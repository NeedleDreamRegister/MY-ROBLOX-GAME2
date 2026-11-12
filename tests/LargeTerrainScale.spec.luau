-- Isolated real Terrain benchmark. Default is small; height=74,hits=64 tests 596x300x596.
-- Restores its initially empty reservation even if an assertion fails. No player data.
return function(modules,options)
	options=options or {}
	local Adapter,Field,Grid,Collapse=modules.Adapter,modules.Field,modules.Grid,modules.Collapse
	local height,hits=options.height or 12,options.hits or 16
	assert(height%1==0 and height>=8 and height<=74 and hits%1==0 and hits>=1 and hits<=256)
	local origin=options.origin or Vector3.new(1802,2,1802)
	local edge=math.ceil((height+1)/4)*4
	local bounds={min=Vector3.new(-edge,0,-edge),max=Vector3.new(edge,edge,edge),batchSize=16}
	local cells=Field.Create()
	local started=os.clock()
	local generated=0
	for y=0,height do for x=-(height-y),height-y do for z=-(height-y),height-y do
		cells.Set(x,y,z,true)generated+=1
		if generated%1024==0 then task.wait()end
	end end end
	assert(generated==(height+1)*(2*height+1)*(2*height+3)/3)
	local generationSeconds=os.clock()-started
	local geometry=cells.Export()
	local chunks=0 for _ in geometry do chunks+=1 end
	local geometryBytes=#game:GetService("HttpService"):JSONEncode(geometry)
	local renderer
	local ok,result=pcall(function()
		renderer=Adapter.Create(origin,function(x,y,z)return cells.Has(x,y,z)end,bounds)
		local initial=renderer.Stats()
		assert(initial.filled==generated)
		local function record(x,y,z)if cells.Has(x,y,z)then return {x=x,y=y,z=z}end end
		local function move(_,sx,sy,sz,x,y,z)
			cells.Set(sx,sy,sz,false)cells.Set(x,y,z,true)renderer.Mark(sx,sy,sz)renderer.Mark(x,y,z)
		end
		local accepted,stale,moved,maxWrites=0,0,0,0
		local queue=Collapse.Queue(4096)
		local function advance(entry)
			local transfers,retry=Collapse.Process(queue,entry,function(x,y,z)return cells.Has(x,y,z)end,move,function()return true end,8,height,function(x,y,z)
				return y>=0 and y<=height and math.abs(x)<=height-y and math.abs(z)<=height-y
			end,accepted+1)
			moved+=transfers
			maxWrites=math.max(maxWrites,renderer.Flush())
			return retry
		end
		local mutateStarted=os.clock()
		for index=1,hits do
			task.wait(0.12) -- same minimum action interval as the server
			queue.Step(advance,4)
			local hit=workspace:Raycast(origin+Vector3.new(0,(height+5)*4,0),Vector3.new(0,-(height+10)*4,0))
			local target=hit and Grid.Resolve(origin,hit.Position,hit.Normal,record,bounds)
			if target then
				assert(cells.Set(target.x,target.y,target.z,false))accepted+=1 renderer.Mark(target.x,target.y,target.z)
				queue.Push(advance({x=target.x,y=target.y,z=target.z,budget=height-target.y}))
			else stale+=1 end
		end
		local mutationSeconds=os.clock()-mutateStarted
		assert(cells.Set(0,0,0,false))renderer.Mark(0,0,0)
		local beforeBase=moved
		queue.Push(advance({x=0,y=0,z=0,budget=height}))
		local continuationFrames=0
		while queue.Count()>0 do
			assert(continuationFrames<math.ceil(height/8)+128,"collapse did not terminate")
			task.wait(0.25)queue.Step(advance,4)continuationFrames+=1
		end
		local actual,checked=0,0
		for x=-edge,edge-1,16 do for y=0,edge-1,16 do for z=-edge,edge-1,16 do
			local sx,sy,sz=math.min(16,edge-x),math.min(16,edge-y),math.min(16,edge-z)
			local first=Grid.Position(origin,x,y,z)-Vector3.new(2,2,2)
			local _,occupancy=workspace.Terrain:ReadVoxels(Region3.new(first,first+Vector3.new(sx,sy,sz)*4),4)
			for a=1,sx do for b=1,sy do for c=1,sz do
				local present=occupancy[a][b][c]>0
				assert(present==cells.Has(x+a-1,y+b-1,z+c-1),"Terrain differs from compact field")
				if present then actual+=1 end checked+=1
			end end end task.wait()
		end end end
		assert(actual==cells.Count()and actual+accepted+1==generated)
		return {height=height,initialCells=generated,cells=actual,dug=accepted+1,acceptedHits=accepted,staleSamples=stale,
			logicalChunks=chunks,geometryBytes=geometryBytes,generationSeconds=generationSeconds,initialSeconds=initial.initialSeconds,
			initialWriteBatches=initial.initialBatches,checkedVoxels=checked,maximumWritesPerHit=maxWrites,
			mutationSeconds=mutationSeconds,moved=moved,baseMoves=moved-beforeBase,continuationFrames=continuationFrames,pending=queue.Count()}
	end)
	if renderer then renderer.Destroy()end
	assert(ok,result)return result
end
