-- Owns one bounded, initially empty Terrain region. Large initialization is batched.
local Grid=require(game:GetService("ReplicatedStorage").SandPrototypeTerrainGrid)
local Terrain=workspace.Terrain
local Adapter={}
local reservations={}
local function arrays(size)
	local material,occupancy={},{}
	for x=1,size.X do material[x]={}occupancy[x]={}
		for y=1,size.Y do material[x][y]={}occupancy[x][y]={}
			for z=1,size.Z do material[x][y][z]=Enum.Material.Air occupancy[x][y][z]=0 end
		end
	end
	return material,occupancy
end
function Adapter.Create(origin,getCell,options)
	options=options or {}
	assert(origin.X%4==2 and origin.Y%4==2 and origin.Z%4==2,"Terrain origin must be voxel-centred")
	local lo=options.min or Vector3.new(-8,0,-8)
	local hi=options.max or Vector3.new(8,8,8) -- exclusive, in logical cells
	local batch=options.batchSize or 16
	assert(type(batch)=="number"and batch>=4 and batch<=16 and batch%4==0,"invalid Terrain batch size")
	for _,axis in {"X","Y","Z"}do
		assert(lo[axis]%4==0 and hi[axis]%4==0 and hi[axis]>lo[axis]and hi[axis]-lo[axis]<=512,"Terrain bounds must align to logical chunks")
	end
	local size=hi-lo
	local volume=size.X*size.Y*size.Z
	assert(volume<=4194304,"Terrain region exceeds owned volume limit")
	local minimum=Grid.Position(origin,lo.X,lo.Y,lo.Z)-Vector3.new(2,2,2)
	local maximum=Grid.Position(origin,hi.X,hi.Y,hi.Z)-Vector3.new(2,2,2)
	for _,r in reservations do
		assert(maximum.X<=r.min.X or minimum.X>=r.max.X or maximum.Z<=r.min.Z or minimum.Z>=r.max.Z,"Terrain plot overlap")
	end
	local region=Region3.new(minimum,maximum)
	local token={min=minimum,max=maximum}
	reservations[token]=token -- reserve before the first yielding operation
	local batches,touched={},{}
	for x=lo.X,hi.X-1,batch do for y=lo.Y,hi.Y-1,batch do for z=lo.Z,hi.Z-1,batch do
		local extent=Vector3.new(math.min(batch,hi.X-x),math.min(batch,hi.Y-y),math.min(batch,hi.Z-z))
		local first=Grid.Position(origin,x,y,z)-Vector3.new(2,2,2)
		batches[#batches+1]={x=x,y=y,z=z,size=extent,region=Region3.new(first,first+extent*4)}
	end end end
	local sliceStarted,sliceBatches=os.clock(),0
	local function yieldBatch()
		if #batches<=1 then return end
		sliceBatches+=1
		if sliceBatches>=4 or os.clock()-sliceStarted>=0.003 then
			task.wait()sliceStarted=os.clock()sliceBatches=0
		end
	end
	local function restore()
		sliceStarted=os.clock()sliceBatches=0
		local failure
		local empty={}
		for _,entry in touched do
			-- Every owned voxel was verified empty before the first write. Keep
			-- region metadata, not millions of redundant Air/zero table entries.
			local key=string.format("%d,%d,%d",entry.size.X,entry.size.Y,entry.size.Z)
			local buffers=empty[key]
			if not buffers then local m,o=arrays(entry.size)buffers={m,o}empty[key]=buffers end
			local ok,reason=pcall(function()Terrain:WriteVoxels(entry.region,4,buffers[1],buffers[2])end)
			if not ok then failure=tostring(reason)end
			yieldBatch()
		end
		return failure==nil,failure
	end
	local writes,filled=0,0
	local started=os.clock()
	local ok,reason=pcall(function()
		-- Verify the entire reservation before writing any part of it.
		for _,entry in batches do
			local _,occupancy=Terrain:ReadVoxels(entry.region,4)
			for x=1,entry.size.X do for y=1,entry.size.Y do for z=1,entry.size.Z do
				assert(occupancy[x][y][z]==0,"Terrain region already contains material; refusing to overwrite")
			end end end
			yieldBatch()
		end
		for _,entry in batches do
			local m,o=arrays(entry.size)
			for x=1,entry.size.X do for y=1,entry.size.Y do for z=1,entry.size.Z do
				if getCell(entry.x+x-1,entry.y+y-1,entry.z+z-1)then
					m[x][y][z]=Enum.Material.Sand o[x][y][z]=1 filled+=1
				end
			end end end
			touched[#touched+1]=entry -- also restore a write that raises after partial work
			Terrain:WriteVoxels(entry.region,4,m,o)writes+=1
			yieldBatch()
		end
	end)
	if not ok then
		local restored,restoreReason=restore()
		if restored then reservations[token]=nil end
		error(tostring(reason)..(restored and ""or "; restoration failed, region remains reserved: "..tostring(restoreReason)))
	end
	local initialSeconds=os.clock()-started
	local dirty={}
	local closed=false
	local api={}
	function api.Mark(x,y,z)
		assert(not closed,"Terrain adapter closed")
		assert(x%1==0 and y%1==0 and z%1==0 and x>=lo.X and x<hi.X and y>=lo.Y and y<hi.Y and z>=lo.Z and z<hi.Z,"Terrain edit outside owned region")
		local cx,cy,cz=math.floor(x/4),math.floor(y/4),math.floor(z/4)
		dirty[string.format("%d,%d,%d",cx,cy,cz)]={cx,cy,cz}
	end
	function api.Flush()
		assert(not closed,"Terrain adapter closed")
		local count=0
		for key,chunk in dirty do
			local cx,cy,cz=chunk[1]*4,chunk[2]*4,chunk[3]*4
			local m,o=arrays(Vector3.new(4,4,4))
			for x=0,3 do for y=0,3 do for z=0,3 do
				if getCell(cx+x,cy+y,cz+z)then m[x+1][y+1][z+1]=Enum.Material.Sand o[x+1][y+1][z+1]=1 end
			end end end
			local first=Grid.Position(origin,cx,cy,cz)-Vector3.new(2,2,2)
			Terrain:WriteVoxels(Region3.new(first,first+Vector3.new(16,16,16)),4,m,o)
			dirty[key]=nil count+=1 writes+=1
		end
		return count
	end
	function api.Resolve(position,normal)return Grid.Resolve(origin,position,normal,getCell,{min=lo,max=hi})end
	function api.Stats()return {writes=writes,region=region,initialBatches=#batches,volume=volume,filled=filled,initialSeconds=initialSeconds}end
	function api.Destroy()
		if closed then return end
		local restored,restoreReason=restore()
		assert(restored,"Terrain restoration failed: "..tostring(restoreReason))
		closed=true reservations[token]=nil
	end
	return api
end
return Adapter
