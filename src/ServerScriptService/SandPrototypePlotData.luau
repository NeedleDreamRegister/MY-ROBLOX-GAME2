-- Pure selection/validation. Never changes the legacy record.
local Snapshot = require(script.Parent.SandPrototypeSnapshot)
local Finds = require(script.Parent.SandPrototypeFindData)
local Geometry=require(game:GetService("ReplicatedStorage").SandPrototypeGeometry)
local Field=require(game:GetService("ReplicatedStorage").SandPrototypeVoxelField)
local PlotData = {}
local SNAPSHOT_VERSION = 1

-- Snapshot.Validate checks the current mountain geometry (455 cells).
-- Expand validates 165-cell saves before adding only new coordinates.

function PlotData.Fresh(height)
	height=height or 6
	local size=assert(Geometry.Size(height),"unsupported fresh mountain height")
	local data={schemaVersion=SNAPSHOT_VERSION,revision=0,initialCells=size,dugCells=0,movedCells=0,accounts={}}
	if size>455 then
		Geometry.PrepareFamily(size)
		data.voxelChunks=table.clone(Geometry.Prepare(size))return data
	end
	data.cells={}
	for y=0,height do
		for x=-(height-y),height-y do
			for z=-(height-y),height-y do table.insert(data.cells,{x=x,y=y,z=z}) end
		end
	end
	return data
end

function PlotData.Validator(userId)
	local id=tostring(userId)
	return function(raw)
		local data,reason=Snapshot.Validate(raw)
		if not data then return nil,reason end
		for accountId in data.accounts do
			if accountId~=id then return nil,"foreign account in personal plot" end
		end
		return data
	end
end

-- Add only the 290 coordinates outside the original 165-cell mountain.
-- Existing holes, moved sand, inventory, helper counters and finds stay intact.
function PlotData.Expand(userId, raw)
	if type(raw)~="table" or raw.initialCells~=165 then return nil,"not a legacy mountain" end
	local old,reason=Finds.Validator(userId,false,true)(raw)
	if not old then return nil,"invalid legacy snapshot: "..tostring(reason) end
	local cells=table.clone(old.cells)
	for _,cell in PlotData.Fresh().cells do
		local radius=4-cell.y
		if cell.y>4 or math.abs(cell.x)>radius or math.abs(cell.z)>radius then
			table.insert(cells,cell)
		end
	end
	old.cells=cells
	old.initialCells=455
	if raw.schemaVersion~=3 then
		-- Earlier schemas had no collectible; choose its hiding place from
		-- the expanded mountain, including the new shell if the old core is gone.
		old.schemaVersion=2
		old.artifact=nil
		old.collection=nil
	end
	return Finds.Validator(userId,false)(old)
end

-- Templates must be prepared before an UpdateAsync callback. Grow moves the old
-- core forward in logical coordinates; the matching runtime origin moves back,
-- keeping every existing hole/find at the same physical world position.
function PlotData.Grow(userId,raw,targetSize)
	targetSize=targetSize or 2925
	if type(raw)~="table"then return nil,"missing expansion source"end
	local source=raw
	if raw.initialCells==165 then
		local reason
		source,reason=PlotData.Expand(userId,raw)
		if not source then return nil,reason end
	end
	local oldSize=source.initialCells
	local oldHeight,height=Geometry.Height(oldSize),Geometry.Height(targetSize)
	if not oldHeight or not height or oldSize>=targetSize then return nil,"invalid expansion sizes"end
	local baseline,expanded=Geometry.Prepared(oldSize),Geometry.Prepared(targetSize)
	if not baseline or not expanded then return nil,"prepare expansion templates before migration"end
	local old,reason=Finds.Validator(userId,false,false,oldSize)(source)
	if not old then return nil,"invalid expansion source: "..tostring(reason)end
	local remaining=old.voxelChunks
	if not remaining then
		local field=Field.Create()for _,c in old.cells do field.Set(c.x,c.y,c.z,true)end remaining=field.Export()
	end
	local missing={}
	for key,bits in baseline do
		local expected=Field.Decode(bits)local present=Field.Decode(remaining[key]or "0000000000000000")
		local lost={bit32.band(expected[1],bit32.bnot(present[1])),bit32.band(expected[2],bit32.bnot(present[2]))}
		if lost[1]~=0 or lost[2]~=0 then missing[key]=Field.Encode(lost)end
	end
	local field=Field.Create(expanded)
	local shift=height-oldHeight
	local pending={}
	Field.Create(missing).Each(function(x,y,z)
		assert(field.Set(x,y,z+shift,false),"old core is outside expanded template")
		pending[#pending+1]={x=x,y=y,z=z+shift,budget=height-y}
	end)
	old.initialCells=targetSize old.cells=nil old.voxelChunks=field.Export()old.pendingCollapses=pending
	if old.artifact and not old.artifact.finderId then old.artifact.z+=shift end
	if raw.schemaVersion~=3 then old.schemaVersion=2 old.artifact=nil old.collection=nil end
	return Finds.Validator(userId,false,false,targetSize)(old)
end

function PlotData.Initial(userId, legacy, now)
	if legacy==nil then return PlotData.Fresh(),"fresh" end
	if type(legacy)~="table" or legacy.formatVersion~=1 then return nil,"invalid legacy envelope" end
	local oldSize=type(legacy.snapshot)=="table" and legacy.snapshot.initialCells
	local data,reason=Snapshot.Validate(legacy.snapshot,oldSize==165 and 165 or nil)
	if not data then return nil,"invalid legacy snapshot: "..reason end
	local id=tostring(userId)
	if not data.accounts[id] then return PlotData.Fresh(),"fresh" end
	local count=0
	for _ in data.accounts do count+=1 end
	if count~=1 then return nil,"legacy has multiple contributors" end
	local lease=legacy.lease
	if lease then
		if type(lease)~="table" or type(lease.expiresAt)~="number" or lease.expiresAt~=lease.expiresAt then
			return nil,"invalid legacy lease"
		end
		if lease.expiresAt>now then return nil,"legacy world is still active" end
	end
	data.revision=0
	if oldSize==165 then
		local expanded,expandReason=PlotData.Expand(userId,data)
		if not expanded then return nil,expandReason end
		return expanded,"copied legacy 165"
	end
	return data,"copied legacy"
end

return PlotData

