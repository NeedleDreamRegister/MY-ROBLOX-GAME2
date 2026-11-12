-- Pure schema/consistency checks for the small shared prototype only.
-- Does not access DataStoreService or mutate the input.
local Snapshot = {}
local INITIAL_CELLS = 455
local Geometry=require(game:GetService("ReplicatedStorage").SandPrototypeGeometry)

local function integer(value, low, high)
	return type(value) == "number" and value == value and value >= low and value <= high and value % 1 == 0
end

function Snapshot.Validate(raw, expectedCells)
	local size = expectedCells or INITIAL_CELLS
	local height=Geometry.Height(size)
	if not height then return nil,"unsupported mountain size"end
	if type(raw) ~= "table" then return nil, "snapshot must be a table" end
	if raw.schemaVersion ~= 1 then return nil, "unsupported schema version" end
	if raw.initialCells ~= size then return nil, "incompatible initial mountain" end
	if not integer(raw.revision, 0, 1000000000) then return nil, "invalid revision" end
	if not integer(raw.dugCells, 0, size) then return nil, "invalid dug mass" end
	if not integer(raw.movedCells, 0, raw.dugCells * math.max(8,height)) then return nil, "invalid moved count" end
	if type(raw.accounts)~="table"then return nil,"missing accounts"end
	local geometry,count,reason=Geometry.Normalize(raw,size)
	if not geometry then return nil,reason end
	if count+raw.dugCells~=size then return nil,"mountain mass does not match digging"end
	local normalized={schemaVersion=1,initialCells=size,revision=raw.revision,dugCells=raw.dugCells,movedCells=raw.movedCells,
		cells=geometry.cells,voxelChunks=geometry.voxelChunks,accounts={}}
	local totalXP, accountedMass, accountCount = 0, 0, 0
	for userId, state in raw.accounts do
		local numericId = type(userId) == "string" and tonumber(userId) or nil
		if type(userId) ~= "string" or #userId > 20 or not string.match(userId, "^%d+$")
			or not integer(numericId, 1, 9007199254740991) or string.format("%.0f", numericId) ~= userId then
			return nil, "invalid account user id"
		end
		if type(state) ~= "table" then return nil, "invalid account" end
				if not integer(state.CapacityLevel, 0, 1) then return nil, "invalid capacity level" end
		local barrowOwned = state.BarrowOwned
		if barrowOwned == nil then barrowOwned = 0 end
		if not integer(barrowOwned, 0, 1) then return nil, "invalid wheelbarrow flag" end
		local shovelLevel=state.ShovelLevel==nil and 0 or state.ShovelLevel
		if not integer(shovelLevel,0,1) then return nil,"invalid shovel level" end
		local capacity = (state.CapacityLevel == 0 and 20 or 40) + barrowOwned * 80
		if state.CapacityCells ~= capacity then return nil, "capacity does not match upgrades" end
		if not integer(state.CarriedCells, 0, capacity) then return nil, "invalid carried mass" end
		local cartCells=state.CartCells
		if cartCells==nil then cartCells=barrowOwned==1 and math.min(state.CarriedCells,80)or 0 end
		if not integer(cartCells,0,barrowOwned*80)or cartCells>state.CarriedCells
			or state.CarriedCells-cartCells>capacity-barrowOwned*80 then return nil,"invalid cart/manual mass"end
		if not integer(state.XP, state.CarriedCells, size) or not integer(state.Coins, 0, size) then
			return nil, "invalid XP or coins"
		end
		normalized.accounts[userId] = {
			CarriedCells = state.CarriedCells, CartCells=cartCells, CapacityCells = capacity,
			CapacityLevel = state.CapacityLevel, BarrowOwned = barrowOwned, ShovelLevel=shovelLevel, XP = state.XP, Coins = state.Coins,
		}
		totalXP += state.XP
		accountedMass += state.CarriedCells + state.Coins + state.CapacityLevel * 10 + barrowOwned * 25 + shovelLevel*20
		accountCount += 1
		if accountCount > 128 then return nil, "prototype account limit exceeded" end
	end
	if totalXP ~= raw.dugCells then return nil, "XP does not match total digging" end
	if accountedMass ~= raw.dugCells then return nil, "inventory and economy do not conserve mass" end
	return normalized
end

return Snapshot
