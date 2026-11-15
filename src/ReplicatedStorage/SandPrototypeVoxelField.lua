-- 64 occupied/empty cells per chunk. No Instances or per-cell stored tables.
local Field={}
local digits="0123456789abcdef"
local function address(x,y,z)
	-- Templates can contain IEEE negative zero; it must address the same chunk as zero.
	return string.format("%d,%d,%d",math.floor(x/4),math.floor(y/4),math.floor(z/4)),x%4*16+y%4*4+z%4
end
function Field.Decode(encoded)
	if type(encoded)~="string"or #encoded~=16 or encoded:find("[^0-9a-f]")then return nil end
	return {tonumber(encoded:sub(1,8),16),tonumber(encoded:sub(9,16),16)}
end
function Field.Encode(words)
	local result={}
	for _,word in words do
		for shift=28,0,-4 do
			local n=bit32.extract(word,shift,4)
			result[#result+1]=digits:sub(n+1,n+1)
		end
	end
	return table.concat(result)
end
function Field.Contains(encoded,x,y,z)
	local words=Field.Decode(encoded)
	if not words then return false end
	local _,index=address(x,y,z)
	return bit32.extract(words[math.floor(index/32)+1],index%32)==1
end
Field.Address=address
function Field.Popcount(word)
	word=word-bit32.band(bit32.rshift(word,1),0x55555555)
	word=bit32.band(word,0x33333333)+bit32.band(bit32.rshift(word,2),0x33333333)
	word=bit32.band(word+bit32.rshift(word,4),0x0f0f0f0f)
	word+=bit32.rshift(word,8)word+=bit32.rshift(word,16)
	return bit32.band(word,0x3f)
end
function Field.CountWords(words)return Field.Popcount(words[1])+Field.Popcount(words[2])end
function Field.Create(initial)
	local chunks,dirty={},{}
	local count=0
	for key,encoded in initial or {}do
		local words=assert(Field.Decode(encoded),"invalid initial voxel chunk")
		chunks[key]=words dirty[key]=true count+=Field.CountWords(words)
	end
	local api={}
	local publishedTemplate
	function api.Has(x,y,z)
		local key,index=address(x,y,z)
		local words=chunks[key]
		return words~=nil and bit32.extract(words[math.floor(index/32)+1],index%32)==1
	end
	function api.Set(x,y,z,occupied)
		local key,index=address(x,y,z)
		local words=chunks[key]
		if not words then
			if not occupied then return false end
			words={0,0}chunks[key]=words
		end
		local slot,shift=math.floor(index/32)+1,index%32
		if (bit32.extract(words[slot],shift)==1)==occupied then return false end
		words[slot]=bit32.replace(words[slot],occupied and 1 or 0,shift)
		count+=occupied and 1 or -1
		dirty[key]=true
		return true
	end
	function api.Count()return count end
	function api.Export()
		local result={}
		for key,words in chunks do
			if words[1]~=0 or words[2]~=0 then result[key]=Field.Encode(words)end
		end
		return result
	end
	function api.Each(callback)
		for key,words in chunks do
			local cx,cy,cz=key:match("^(-?%d+),(-?%d+),(-?%d+)$")
			cx,cy,cz=tonumber(cx)*4,tonumber(cy)*4,tonumber(cz)*4
			for index=0,63 do
				if bit32.extract(words[math.floor(index/32)+1],index%32)==1 then
					callback(cx+math.floor(index/16),cy+math.floor(index/4)%4,cz+index%4)
				end
			end
		end
	end
	function api.Publish(folder,yieldEvery,template)
		if template and publishedTemplate~=template then
			-- Missing chunks are explicit zero deltas, otherwise deleted sand would
			-- reappear through the client's fallback to the original template.
			for key in template do dirty[key]=true end
			publishedTemplate=template
		end
		local sent=0
		for key in dirty do
			local value=folder:FindFirstChild(key)
			local encoded=chunks[key]and Field.Encode(chunks[key])or "0000000000000000"
			if template and encoded==(template[key]or "0000000000000000")then
				if value then value:Destroy()end
			else
				if not value then value=Instance.new("StringValue")value.Name=key value.Parent=folder end
				value.Value=encoded
			end
			dirty[key]=nil sent+=1
			if yieldEvery and sent%yieldEvery==0 then task.wait()end
		end
		return sent
	end
	return api
end
return Field
