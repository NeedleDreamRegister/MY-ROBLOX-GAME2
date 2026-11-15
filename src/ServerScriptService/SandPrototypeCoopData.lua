-- Pure schema migration and cumulative reward accounting.
local Snapshot=require(script.Parent.SandPrototypeSnapshot)
local Geometry=require(game:GetService("ReplicatedStorage").SandPrototypeGeometry)
local Coop={}
local function integer(v,lo,hi)
	return type(v)=="number" and v==v and v>=lo and v<=hi and v%1==0
end
local function validId(id,allowTestIds)
	local n=type(id)=="string" and tonumber(id)
	return n and (integer(n,1,9007199254740991)or(allowTestIds and integer(n,-8,-1))) and string.format("%.0f",n)==id
end
local function counters(raw,owner,allowZero,allowTestIds)
	if type(raw)~="table" then return nil,nil,"missing counters" end
	local result,total,count={},0,0
	for id,value in raw do
		if not validId(id,allowTestIds) or id==owner or not integer(value,allowZero and 0 or 1,Geometry.MaxCells) then
			return nil,nil,"invalid contribution counter"
		end
		result[id]=value total+=value count+=1
		if count>128 then return nil,nil,"contribution history limit" end
	end
	return result,total
end
function Coop.Validator(userId,allowTestIds,allowLegacy,expectedCells)
	local owner=tostring(userId)
	expectedCells=expectedCells or 455
	Geometry.Prepare(expectedCells)
	return function(raw)
		if not validId(owner,allowTestIds) then return nil,"invalid owner id" end
		if type(raw)~="table" then return nil,"snapshot must be table" end
		local size=allowLegacy and Geometry.Height(raw.initialCells)and raw.initialCells<=expectedCells and raw.initialCells or expectedCells
		if raw.schemaVersion==1 then
			local v,reason=Snapshot.Validate(raw,size)
			if not v then return nil,reason end
			for id in v.accounts do if id~=owner then return nil,"foreign account in personal plot" end end
			return {schemaVersion=2,ownerId=owner,revision=v.revision,initialCells=size,
				dugCells=v.dugCells,movedCells=v.movedCells,cells=v.cells,voxelChunks=v.voxelChunks,
				account=v.accounts[owner] or {CarriedCells=0,CartCells=0,CapacityCells=20,CapacityLevel=0,BarrowOwned=0,ShovelLevel=0,Coins=0,XP=0},
				outbound={},imports={},accessMode="Closed"}
		end
		if raw.schemaVersion~=2 or raw.ownerId~=owner then return nil,"invalid personal owner/schema" end
		if raw.accessMode~="Closed" and raw.accessMode~="Friends" and raw.accessMode~="Open" then return nil,"invalid access mode" end
		local outbound,exported,reason=counters(raw.outbound,owner,false,allowTestIds)
		if not outbound then return nil,reason end
		local imports,imported,importError=counters(raw.imports,owner,true,allowTestIds)
		if not imports then return nil,importError end
		-- Reuse the tested geometry validator with a synthetic accounting row.
		local geometry,errorMessage=Snapshot.Validate({schemaVersion=1,revision=raw.revision,initialCells=raw.initialCells,
			dugCells=raw.dugCells,movedCells=raw.movedCells,cells=raw.cells,voxelChunks=raw.voxelChunks,
			accounts={["1"]={CarriedCells=0,CapacityCells=20,CapacityLevel=0,Coins=raw.dugCells,XP=raw.dugCells}}},size)
		if not geometry then return nil,errorMessage end
		if exported>raw.dugCells then return nil,"export exceeds dug mass" end
		local a=raw.account
		if type(a)~="table" or not integer(a.CapacityLevel,0,1) or not integer(a.BarrowOwned==nil and 0 or a.BarrowOwned,0,1) then return nil,"invalid account" end
		local capacity=(a.CapacityLevel==0 and 20 or 40)+(a.BarrowOwned==nil and 0 or a.BarrowOwned)*80
		local shovelLevel=a.ShovelLevel==nil and 0 or a.ShovelLevel
		if not integer(shovelLevel,0,1) then return nil,"invalid shovel level" end
		local xp=raw.dugCells-exported+imported
		if not integer(a.CarriedCells,0,capacity)then return nil,"invalid carried mass"end
		local cartCells=a.CartCells
		if cartCells==nil then cartCells=(a.BarrowOwned or 0)==1 and math.min(a.CarriedCells or 0,80)or 0 end
		if not integer(a.CarriedCells,0,capacity)or not integer(cartCells,0,(a.BarrowOwned or 0)*80)
			or cartCells>a.CarriedCells or a.CarriedCells-cartCells>capacity-(a.BarrowOwned or 0)*80 then return nil,"invalid cart/manual mass"end
		if a.CapacityCells~=capacity or not integer(a.CarriedCells,0,capacity)
			or a.XP~=xp or not integer(a.Coins,0,xp)
			or a.CarriedCells+a.Coins+10*a.CapacityLevel+25*(a.BarrowOwned==nil and 0 or a.BarrowOwned)+20*shovelLevel~=xp then return nil,"wallet mass/XP mismatch" end
		return {schemaVersion=2,ownerId=owner,revision=geometry.revision,initialCells=size,
			dugCells=geometry.dugCells,movedCells=geometry.movedCells,cells=geometry.cells,voxelChunks=geometry.voxelChunks,
			account={CarriedCells=a.CarriedCells,CartCells=cartCells,CapacityCells=capacity,CapacityLevel=a.CapacityLevel,BarrowOwned=a.BarrowOwned==nil and 0 or a.BarrowOwned,ShovelLevel=shovelLevel,Coins=a.Coins,XP=xp},
			outbound=outbound,imports=imports,accessMode=raw.accessMode}
	end
end
function Coop.CreditDelta(account,already,confirmed)
	if not integer(already,0,Geometry.MaxCells) or not integer(confirmed,0,Geometry.MaxCells) then return 0 end
	return math.max(0,math.min(confirmed-already,account.CapacityCells-account.CarriedCells))
end
function Coop.Advances(previous,nextValue)
	if previous.schemaVersion~=2 or nextValue.schemaVersion~=2 or previous.ownerId~=nextValue.ownerId then return false end
	if nextValue.dugCells<previous.dugCells or nextValue.movedCells<previous.movedCells or nextValue.account.XP<previous.account.XP
		or nextValue.account.CapacityLevel<previous.account.CapacityLevel
		or(nextValue.account.BarrowOwned or 0)<(previous.account.BarrowOwned or 0)
		or(nextValue.account.ShovelLevel or 0)<(previous.account.ShovelLevel or 0) then return false end
	for _,field in {"imports","outbound"}do
		for id,value in previous[field]do
			if nextValue[field][id]==nil or nextValue[field][id]<value then return false end
		end
	end
	return true
end
return Coop
