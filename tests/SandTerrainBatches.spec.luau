-- Real Terrain, isolated empty region in Studio Edit. No player data.
return function(Adapter,Field,Legacy)
	local origin=Vector3.new(602,2,-66)
	local region=Region3.new(origin+Vector3.new(-34,-2,-34),origin+Vector3.new(30,30,30))
	local terrain=workspace.Terrain
	local originalMaterials,originalOccupancy=terrain:ReadVoxels(region,4)
	for x=1,16 do for y=1,8 do for z=1,16 do assert(originalOccupancy[x][y][z]==0,"QA region is not empty")end end end
	local field=Field.Create()
	for y=0,6 do for x=-(6-y),6-y do for z=-(6-y),6-y do field.Set(x,y,z,true)end end end
	local current
	local function getCell(x,y,z)return field.Has(x,y,z)end
	local function verify()
		local _,o=terrain:ReadVoxels(region,4)
		for x=1,16 do for y=1,8 do for z=1,16 do assert((o[x][y][z]>0)==field.Has(x-9,y-1,z-9),"Terrain differs at batch border")end end end
	end
	local ok,result=pcall(function()
		local legacySeconds
		if Legacy then local started=os.clock()current=Legacy.Create(origin,getCell)verify()legacySeconds=os.clock()-started current.Destroy()current=nil end
		local started=os.clock()current=Adapter.Create(origin,getCell)verify()
		local defaultSeconds=os.clock()-started
		assert(current.Stats().writes==1 and current.Stats().filled==455,"small default changed")
		current.Destroy()current=nil
		local overlapRejected=false
		task.defer(function()local allowed=pcall(function()return Adapter.Create(origin,getCell)end)overlapRejected=not allowed end)
		current=Adapter.Create(origin,getCell,{batchSize=4})
		assert(overlapRejected and current.Stats().initialBatches==32,"yielding initialization lost reservation")verify()
		field.Set(3,0,0,false)field.Set(4,0,0,false)field.Set(3,0,0,true)
		current.Mark(3,0,0)current.Mark(4,0,0)
		assert(current.Flush()==2 and field.Count()==454,"cross-chunk mass/write count")verify()
		assert(not pcall(current.Mark,8,0,0),"outside edit accepted")
		current.Destroy()current=nil
		local initialized=pcall(function()Adapter.Create(origin,function(x)if x>=-4 then error("injected generation failure")end return true end,{batchSize=4})end)
		assert(not initialized,"generation failure ignored")
		local _,empty=terrain:ReadVoxels(region,4)
		for x=1,16 do for y=1,8 do for z=1,16 do assert(empty[x][y][z]==0,"failed initialization left Terrain")end end end
		current=Adapter.Create(origin,function()return false end)current.Destroy()current=nil
		local cellRegion=Region3.new(origin-Vector3.new(2,2,2),origin+Vector3.new(2,2,2))
		terrain:WriteVoxels(cellRegion,4,{{{Enum.Material.Rock}}},{{{1}}})
		assert(not pcall(Adapter.Create,origin,getCell),"pre-existing Terrain overwritten")
		local m,o=terrain:ReadVoxels(cellRegion,4)assert(m[1][1][1]==Enum.Material.Rock and o[1][1][1]==1)
		return {legacySeconds=legacySeconds,defaultSeconds=defaultSeconds,batches=32,crossBorder=true,overlapRejected=true,failureRestored=true,foreignTerrainPreserved=true}
	end)
	if current then current.Destroy()end
	terrain:WriteVoxels(region,4,originalMaterials,originalOccupancy)
	assert(ok,result)return result
end
