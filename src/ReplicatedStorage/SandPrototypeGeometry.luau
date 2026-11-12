-- Canonical shapes and chunk-native validation. No player state or Terrain writes.
local Field=require(script.Parent.SandPrototypeVoxelField)
local Geometry={MaxCells=562475}
local heights={[165]=4,[455]=6,[2925]=12,[562475]=74}
local templates,masks,building={},{},{}
local templateCounts={}
function Geometry.Height(size)return heights[size]end
function Geometry.Prepared(size)return templates[size]end
function Geometry.Size(height)
	if type(height)~="number"or height%1~=0 then return nil end
	local size=(height+1)*(2*height+1)*(2*height+3)/3
	return heights[size]==height and size or nil
end
function Geometry.PrepareFamily(size)
	for _,candidate in {165,455,2925,562475}do if candidate<=size then Geometry.Prepare(candidate)end end
end
function Geometry.Contains(size,x,y,z)
	local h=heights[size]
	return h~=nil and y>=0 and y<=h and x%1==0 and y%1==0 and z%1==0 and math.abs(x)<=h-y and math.abs(z)<=h-y
end
function Geometry.Prepare(size)
	if templates[size]then return templates[size]end
	local h=assert(heights[size],"unsupported mountain shape")
	while building[size]do task.wait()end
	if templates[size]then return templates[size]end
	building[size]=true
	local encoded,shapeMasks,shapeCounts={},{},{}
	local chunks=0
	local sliceStarted,sliceChunks=os.clock(),0
	for cy=0,math.floor(h/4)do
		local radius=h-cy*4
		for cx=math.floor(-radius/4),math.floor(radius/4)do for cz=math.floor(-radius/4),math.floor(radius/4)do
			local words={0,0}
			for x=0,3 do for y=0,3 do for z=0,3 do
				if Geometry.Contains(size,cx*4+x,cy*4+y,cz*4+z)then
					local index=x*16+y*4+z local slot=math.floor(index/32)+1
					words[slot]=bit32.replace(words[slot],1,index%32)
				end
			end end end
			if words[1]~=0 or words[2]~=0 then
				local key=string.format("%d,%d,%d",cx,cy,cz)
				shapeMasks[key]=words encoded[key]=Field.Encode(words)shapeCounts[key]=Field.CountWords(words)chunks+=1
			end
			sliceChunks+=1
			if size>455 and(sliceChunks>=128 or os.clock()-sliceStarted>=0.003)then
				task.wait()sliceStarted=os.clock()sliceChunks=0
			end
		end end
	end
	masks[size]=shapeMasks templateCounts[size]=shapeCounts templates[size]=table.freeze(encoded)building[size]=nil
	return templates[size]
end
function Geometry.ValidateChunks(raw,size)
	if not heights[size]or type(raw)~="table"then return nil,nil,"invalid chunk geometry"end
	if not templates[size]then
		if size>455 then return nil,nil,"large template must be prepared before store callbacks"end
		Geometry.Prepare(size)
	end
	local shapeMasks=masks[size]
	local baseline,counts=templates[size],templateCounts[size]
	local result,count,entries={},0,0
	local maxChunks=(2*math.ceil((heights[size]+1)/4))^2*math.ceil((heights[size]+1)/4)
	for key,encoded in raw do
		entries+=1
		if entries>maxChunks or type(key)~="string"then return nil,nil,"chunk count/key limit"end
		local mask=shapeMasks[key]
		if not mask then return nil,nil,"invalid chunk address or bits"end
		if encoded==baseline[key]then
			-- Exact immutable template bytes already have a verified mask/count.
			count+=counts[key]
		else
			local words=Field.Decode(encoded)
			if not words then return nil,nil,"invalid chunk address or bits"end
			if bit32.band(words[1],bit32.bnot(mask[1]))~=0 or bit32.band(words[2],bit32.bnot(mask[2]))~=0 then return nil,nil,"chunk cell outside initial mountain"end
			count+=Field.CountWords(words)
		end
		if count>size then return nil,nil,"too many chunk cells"end
		result[key]=encoded
	end
	return result,count
end
function Geometry.Has(snapshot,x,y,z)
	if snapshot.voxelChunks then
		local bits=snapshot.voxelChunks[Field.Address(x,y,z)]
		return bits~=nil and Field.Contains(bits,x,y,z)
	end
	for _,c in snapshot.cells do if c.x==x and c.y==y and c.z==z then return true end end
	return false
end
function Geometry.Each(snapshot,callback)
	if snapshot.cells then for _,c in snapshot.cells do callback(c.x,c.y,c.z)end
	else Field.Create(snapshot.voxelChunks).Each(callback)end
end
function Geometry.Nearest(snapshot,tx,ty,tz)
	if Geometry.Has(snapshot,tx,ty,tz)then return {x=tx,y=ty,z=tz}end
	local selected,score,selectedKey
	local function consider(x,y,z)
		local value=(x-tx)^2+(y-ty)^2+(z-tz)^2
		if score and value>score then return end
		local key=string.format("%d,%d,%d",x,y,z)
		if not score or value<score or key<selectedKey then selected={x=x,y=y,z=z}score=value selectedKey=key end
	end
	if snapshot.cells then
		for _,c in snapshot.cells do consider(c.x,c.y,c.z)end
	else
		local function distance(first,target)return math.max(first-target,target-first-3,0)end
		for key,bits in snapshot.voxelChunks do
			local cx,cy,cz=key:match("^(-?%d+),(-?%d+),(-?%d+)$")
			cx,cy,cz=tonumber(cx)*4,tonumber(cy)*4,tonumber(cz)*4
			local lower=distance(cx,tx)^2+distance(cy,ty)^2+distance(cz,tz)^2
			if not score or lower<=score then
				local words=Field.Decode(bits)
				for index=0,63 do if bit32.extract(words[math.floor(index/32)+1],index%32)==1 then
					consider(cx+math.floor(index/16),cy+math.floor(index/4)%4,cz+index%4)
				end end
			end
		end
	end
	return selected
end
function Geometry.Normalize(raw,size)
	if raw.cells~=nil and raw.voxelChunks~=nil then return nil,nil,"ambiguous cell/chunk geometry"end
	if raw.voxelChunks~=nil then
		local chunks,count,reason=Geometry.ValidateChunks(raw.voxelChunks,size)
		if not chunks then return nil,nil,reason end
		if size>455 then return {voxelChunks=chunks},count end
		local cells={}
		Field.Create(chunks).Each(function(x,y,z)cells[#cells+1]={x=x,y=y,z=z}end)
		return {cells=cells},count
	end
	if type(raw.cells)~="table"or size>455 then return nil,nil,"large mountains require chunk geometry"end
	local seen,cells,count={},{},0
	for index,c in raw.cells do
		if type(index)~="number"or index%1~=0 or index<1 or index>#raw.cells or type(c)~="table"
			or type(c.x)~="number"or type(c.y)~="number"or type(c.z)~="number"or not Geometry.Contains(size,c.x,c.y,c.z)then return nil,nil,"invalid cell array"end
		local key=string.format("%d,%d,%d",c.x,c.y,c.z)
		if seen[key]then return nil,nil,"duplicate cell"end
		seen[key]=true count+=1 cells[index]={x=c.x,y=c.y,z=c.z}
	end
	if count~=#raw.cells then return nil,nil,"cells must be dense"end
	return {cells=cells},count
end
return Geometry
