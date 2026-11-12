return function(modules,height)
	local Plot,Finds,Codec,Geometry,Field=modules.SandPrototypePlotData,modules.SandPrototypeFindData,modules.SandPrototypeSaveCodec,modules.SandPrototypeGeometry,modules.SandPrototypeVoxelField
	height=height or 12
	local raw=Plot.Fresh(height)local size=raw.initialCells
	local validate=Finds.Validator(1,false,false,size)
	local fresh=assert(validate(raw))
	local packed=Codec.Pack(fresh)
	assert(packed.geometryEncoding=="pyramid-v1-delta"and next(packed.chunkDeltas)==nil and not packed.voxelChunks)
	local roundtrip=assert(validate(assert(Codec.Unpack(packed))))
	assert(Field.Create(roundtrip.voxelChunks).Count()==size)
	local field=Field.Create(roundtrip.voxelChunks)
	-- Fully empty one valid bottom chunk, including the hidden find.
	local removed=0
	for x=0,3 do for y=0,3 do for z=0,3 do if field.Set(x,y,z,false)then removed+=1 end end end end
	local dug=table.clone(raw)dug.voxelChunks=field.Export()dug.dugCells=removed
	dug.accounts={["1"]={CapacityLevel=0,CapacityCells=20,CarriedCells=0,CartCells=0,BarrowOwned=0,ShovelLevel=0,XP=removed,Coins=removed}}
	dug=assert(validate(dug))
	local partial=Codec.Pack(dug)
	assert(partial.chunkDeltas["0,0,0"]=="0000000000000000","deleted chunk fell back to baseline")
	local restored=assert(validate(assert(Codec.Unpack(partial))))
	assert(not Geometry.Has(restored,0,0,0)and Field.Create(restored.voxelChunks).Count()==size-removed,"sold sand regrew")
	local empty=table.clone(raw)empty.voxelChunks={}empty.dugCells=size
	empty.accounts={["1"]={CapacityLevel=0,CapacityCells=20,CarriedCells=0,CartCells=0,BarrowOwned=0,ShovelLevel=0,XP=size,Coins=size}}
	empty=assert(validate(empty))
	local sparse=Codec.Pack(empty)
	assert(sparse.geometryEncoding=="chunks-v1"and next(sparse.voxelChunks)==nil and sparse.chunkDeltas==nil)
	assert(Field.Create(assert(validate(assert(Codec.Unpack(sparse)))).voxelChunks).Count()==0)
	local invalid=table.clone(partial)invalid.chunkDeltas=table.clone(partial.chunkDeltas)invalid.chunkDeltas["10000,0,0"]="0000000000000001"
	assert(not Codec.Unpack(invalid),"foreign delta accepted")
	invalid=table.clone(partial)invalid.geometryEncoding="pyramid-v2-delta"
	assert(not Codec.Unpack(invalid),"unknown template version silently reinterpreted")
	return {size=size,freshBytes=#game:GetService("HttpService"):JSONEncode(packed),partialBytes=#game:GetService("HttpService"):JSONEncode(partial),emptyBytes=#game:GetService("HttpService"):JSONEncode(sparse),noRegrowth=true,sparseFallback=true,unknownVersionRejected=true}
end
