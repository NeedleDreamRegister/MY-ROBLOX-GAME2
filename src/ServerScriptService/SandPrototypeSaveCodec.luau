-- Old envelopes use full chunks; large profiles choose template deltas or sparse chunks.
local Field=require(game:GetService("ReplicatedStorage").SandPrototypeVoxelField)
local Geometry=require(game:GetService("ReplicatedStorage").SandPrototypeGeometry)
local Codec={}
local EMPTY="0000000000000000"
-- Five printable bytes hold x/y/z/budget in 30 bits. Queue order and the exact
-- remaining work budget survive reloads; no JSON table per waiting vacancy.
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local chars,values={},{}
for i=1,#alphabet do chars[i-1]=alphabet:sub(i,i)values[alphabet:byte(i)]=i-1 end
local function packPending(entries)
	local result=table.create(#entries)
	for i,e in entries do
		local n=(e.x+74)*4194304+e.y*32768+(e.z+74)*128+e.budget
		result[i]=chars[math.floor(n/16777216)%64]..chars[math.floor(n/262144)%64]
			..chars[math.floor(n/4096)%64]..chars[math.floor(n/64)%64]..chars[n%64]
	end
	return table.concat(result)
end
local function unpackPending(packed,size)
	if not Geometry.Height(size)or type(packed)~="string"or #packed%5~=0 or #packed>size*5 then return nil,"invalid packed collapse length"end
	local result=table.create(#packed/5)
	for i=1,#packed,5 do
		local n=0
		for j=i,i+4 do local digit=values[packed:byte(j)]if digit==nil then return nil,"invalid packed collapse character"end n=n*64+digit end
		result[#result+1]={x=math.floor(n/4194304)-74,y=math.floor(n/32768)%128,z=math.floor(n/128)%256-74,budget=n%128}
	end
	return result
end
function Codec.Format(snapshot,compact)
	if compact and snapshot.initialCells>455 and #(snapshot.pendingCollapses or {})>4096 then return 4 end
	return compact and(snapshot.initialCells>455 and 3 or 2)or 1
end
function Codec.Pack(snapshot)
	local packed=table.clone(snapshot)
	if snapshot.voxelChunks then
		local baseline=Geometry.Prepare(snapshot.initialCells)
		local delta,changed,remaining={},0,0
		for _ in snapshot.voxelChunks do remaining+=1 end
		for key,bits in baseline do
			local current=snapshot.voxelChunks[key]or EMPTY
			if current~=bits then delta[key]=current changed+=1 end
		end
		if changed<remaining then
			packed.voxelChunks=nil packed.chunkDeltas=delta packed.geometryEncoding="pyramid-v1-delta"
		else
			packed.voxelChunks=table.clone(snapshot.voxelChunks)packed.geometryEncoding="chunks-v1"
		end
	else
		local field=Field.Create()
		for _,cell in snapshot.cells do field.Set(cell.x,cell.y,cell.z,true)end
		packed.voxelChunks=field.Export()
	end
	packed.cells=nil
	if snapshot.initialCells>455 and #(snapshot.pendingCollapses or {})>4096 then
		packed.pendingEncoding="xyzb-v1"packed.pendingPacked=packPending(snapshot.pendingCollapses)packed.pendingCollapses=nil
	end
	return packed
end
function Codec.Unpack(packed)
	if type(packed)~="table"or packed.cells~=nil then return nil,"invalid compact geometry"end
	local raw=packed
	if packed.geometryEncoding=="pyramid-v1-delta"then
		if packed.voxelChunks~=nil then return nil,"ambiguous compact geometry"end
		local delta,_,reason=Geometry.ValidateChunks(packed.chunkDeltas,packed.initialCells)
		if not delta then return nil,reason end
		local chunks=table.clone(Geometry.Prepare(packed.initialCells))
		for key,bits in delta do chunks[key]=bits~=EMPTY and bits or nil end
		raw={voxelChunks=chunks}
	elseif packed.geometryEncoding~=nil and packed.geometryEncoding~="chunks-v1"then return nil,"unknown geometry encoding"
	elseif packed.chunkDeltas~=nil or type(packed.voxelChunks)~="table"then return nil,"invalid compact geometry"end
	local geometry,_,reason=Geometry.Normalize(raw,packed.initialCells)
	if not geometry then return nil,reason end
	local snapshot=table.clone(packed)
	if packed.pendingEncoding~=nil or packed.pendingPacked~=nil then
		if packed.pendingEncoding~="xyzb-v1"or packed.pendingCollapses~=nil then return nil,"unknown or ambiguous collapse encoding"end
		local pending,why=unpackPending(packed.pendingPacked,packed.initialCells)
		if not pending then return nil,why end
		snapshot.pendingCollapses=pending snapshot.pendingEncoding=nil snapshot.pendingPacked=nil
	end
	snapshot.cells=geometry.cells snapshot.voxelChunks=geometry.voxelChunks
	snapshot.chunkDeltas=nil snapshot.geometryEncoding=nil
	return snapshot
end
return Codec
