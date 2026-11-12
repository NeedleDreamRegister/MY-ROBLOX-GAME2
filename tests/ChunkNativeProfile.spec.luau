return function(modules,height,store,key)
	height=height or 74
	local Geometry,Field=modules.SandPrototypeGeometry,modules.SandPrototypeVoxelField
	local Finds,Plot,Session,Codec,Collapse=modules.SandPrototypeFindData,modules.SandPrototypePlotData,modules.SandPrototypeSaveSession,modules.SandPrototypeSaveCodec,modules.SandPrototypeCollapse
	for _,word in {0,1,2,0x80000000,0xffffffff,0xaaaa5555,0x12345678}do
		local count=0 for shift=0,31 do count+=bit32.extract(word,shift)end
		assert(Field.Popcount(word)==count,"bit count corrupted mass")
	end
	local started=os.clock()
	local initial=Plot.Fresh(height)
	local size=initial.initialCells
	local validate=Finds.Validator(1,false,false,size)
	initial=assert(validate(initial))
	assert(initial.cells==nil and initial.voxelChunks,"large profile unfolded to cell tables")
	local field=Field.Create(initial.voxelChunks)
	assert(field.Count()==size and field.Set(0,0,0,false))
	local data=table.clone(initial)
	data.dugCells=1 data.account=table.clone(initial.account)data.account.CarriedCells=1 data.account.XP=1
	local moves,retry=Collapse.Advance({x=0,y=0,z=0,budget=height},function(x,y,z)return field.Has(x,y,z)end,
		function(_,sx,sy,sz,x,y,z)field.Set(sx,sy,sz,false)field.Set(x,y,z,true)data.artifact=Finds.Move(data.artifact,sx,sy,sz,x,y,z)end,function()return true end,8,1)
	data.movedCells=moves data.voxelChunks=field.Export()data.pendingCollapses=retry and {retry}or {}
	data=assert(validate(data))
	local packed=Codec.Pack(data)
	local decoded=assert(validate(assert(Codec.Unpack(packed))))
	assert(not decoded.cells and decoded.movedCells==8 and #decoded.pendingCollapses==1)
	assert(Field.Create(decoded.voxelChunks).Count()==size-1 and decoded.account.XP==1 and decoded.account.CarriedCells==1)
	local corrupt=table.clone(decoded)
	local regrown=Field.Create(decoded.voxelChunks)regrown.Set(retry.x,retry.y,retry.z,true)
	corrupt.voxelChunks=regrown.Export()
	assert(not validate(corrupt),"chunk mass mismatch accepted")
	corrupt=table.clone(decoded)corrupt.voxelChunks=table.clone(decoded.voxelChunks)
	corrupt.voxelChunks["0,0,0"]=nil corrupt.voxelChunks["1000,0,0"]="0000000000000001"
	assert(not validate(corrupt),"foreign chunk accepted")
	local realStore=store~=nil
	if not store then
		store={}
		function store:UpdateAsync(_,callback)local value=callback(self.value)if value then self.value=value end return value end
	end
	key=key or "large"
	local options={owner="first",validate=validate,transition=Finds.Advances,compact=true}
	local first=assert(Session.Open(store,key,data,options))assert(first:Save(first.snapshot,true))
	options.owner="second"
	local second=assert(Session.Open(store,key,initial,options))
	assert(not second.snapshot.cells and second.snapshot.dugCells==1 and second.snapshot.movedCells==8 and #second.snapshot.pendingCollapses==1)
	assert(second:Save(second.snapshot,true))
	local stored=realStore and store:GetAsync(key)or store.value
	assert(stored.formatVersion==3)
	local validationStarted=os.clock()
	for _=1,5 do assert(validate(data))end
	local validationMS=(os.clock()-validationStarted)*1000/5
	return {size=size,height=height,chunkNative=true,remaining=field.Count(),moved=8,partialRestored=true,envelope=3,encoding=packed.geometryEncoding,
		packedBytes=#game:GetService("HttpService"):JSONEncode(packed),seconds=os.clock()-started,validationMS=validationMS,realDataStore=realStore,key=key}
end
