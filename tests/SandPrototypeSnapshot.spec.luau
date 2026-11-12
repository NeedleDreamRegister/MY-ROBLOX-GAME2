-- Pure validation test. Run in Studio Edit after installing the ModuleScript.
local Snapshot = require(game.ServerScriptService.SandPrototypeSnapshot)
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in value do result[key] = copy(child) end
	return result
end
local initial = { schemaVersion = 1, revision = 0, initialCells = 165, dugCells = 0, movedCells = 0, cells = {}, accounts = {} }
for y = 0, 4 do
	local radius = 4 - y
	for x = -radius, radius do
		for z = -radius, radius do table.insert(initial.cells, { x = x, y = y, z = z }) end
	end
end
local checked = {}
local function accept(name, value)
	local normalized, reason = Snapshot.Validate(value)
	assert(normalized, name .. ": " .. tostring(reason))
	table.insert(checked, name)
	return normalized
end
local function reject(name, mutate)
	local value = copy(initial)
	mutate(value)
	local normalized, reason = Snapshot.Validate(value)
	assert(normalized == nil and type(reason) == "string", name .. " was accepted")
	table.insert(checked, name)
end
accept("initial mountain", initial)
local progressed = copy(initial)
for _ = 1, 20 do table.remove(progressed.cells) end
progressed.dugCells = 20
progressed.movedCells = 15
progressed.revision = 1
progressed.accounts["11883917519"] = { CarriedCells = 0, CapacityCells = 40, CapacityLevel = 1, XP = 20, Coins = 10 }
accept("sale and upgrade conserve mass", progressed)
local normalized = accept("copy isolation", initial)
normalized.cells[1].x = 999
assert(initial.cells[1].x ~= 999, "validator mutated input")
reject("duplicate coordinates", function(v) v.cells[2] = copy(v.cells[1]) end)
reject("coordinate outside mountain", function(v) v.cells[1].x = 99 end)
reject("fractional coordinate", function(v) v.cells[1].x = 0.5 end)
reject("array hole", function(v) v.cells[1] = nil end)
reject("unaccounted missing cell", function(v) table.remove(v.cells) end)
reject("future schema", function(v) v.schemaVersion = 2 end)
reject("NaN revision", function(v) v.revision = 0/0 end)
reject("infinite revision", function(v) v.revision = math.huge end)
reject("unexpected account coins", function(v) v.accounts["1"] = {CarriedCells=0,CapacityCells=20,CapacityLevel=0,XP=0,Coins=1} end)
reject("wrong capacity", function(v) v.accounts["1"] = {CarriedCells=0,CapacityCells=999,CapacityLevel=0,XP=0,Coins=0} end)
reject("negative inventory", function(v) v.accounts["1"] = {CarriedCells=-1,CapacityCells=20,CapacityLevel=0,XP=0,Coins=0} end)
reject("duplicate numeric identity", function(v) v.accounts["01"] = {CarriedCells=0,CapacityCells=20,CapacityLevel=0,XP=0,Coins=0} end)
local badMoney = copy(progressed)
badMoney.accounts["11883917519"].Coins += 1
assert(Snapshot.Validate(badMoney) == nil, "extra sale coin was accepted")
table.insert(checked, "extra sale coin")
local badXP = copy(progressed)
badXP.accounts["11883917519"].XP += 1
assert(Snapshot.Validate(badXP) == nil, "extra XP was accepted")
table.insert(checked, "extra XP")
return { passed = #checked, cases = checked }
