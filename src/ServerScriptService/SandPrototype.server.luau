-- Personal mode is opt-in; the tested shared implementation remains below.
workspace:SetAttribute("PersonalPlotsEnabled",script:GetAttribute("PersonalPlotsEnabled")==true)
if script:GetAttribute("PersonalPlotsEnabled") == true then
 require(script.Parent:WaitForChild("SandPrototypePlots")).Start(script)
 return
end
-- Small, disposable sand experiment. The Edit-mode parts in Workspace.SandPrototype
-- are the initial state; this script owns all changes during Play.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Economy = require(script.Parent:WaitForChild("SandPrototypeEconomy"))
local SaveSession = require(script.Parent:WaitForChild("SandPrototypeSaveSession"))
local Snapshot = require(script.Parent:WaitForChild("SandPrototypeSnapshot"))

local mountain = workspace:WaitForChild("SandPrototype")
local cellFolder = mountain:WaitForChild("Cells")
local digEvent = ReplicatedStorage:WaitForChild("SandPrototypeDig")

local CELL_SIZE = 2
local MAX_DIG_DISTANCE = 24
local MAX_MOVES_PER_DIG = 2
local MIN_DIG_INTERVAL = 0.12

local cells = {}
local lastDigAt = {}
local initialCells = 0
local dugCells = 0
local movedCells = 0
local persistent = script:GetAttribute("PersistenceEnabled") ~= false
local ready, closing, saving = false, false, false
local session
local changeSequence, savedSequence = 0, 0

local function status(value)
	mountain:SetAttribute("PersistenceStatus", value)
end
status("Loading")

local function changed()
	changeSequence += 1
	status(persistent and "Dirty" or "SessionOnly")
end

local function canMutate()
	if not ready or closing then return false end
	if session and os.time() >= session.expiresAt then
		status("LockLost")
		return false
	end
	return true
end

local function key(x, y, z)
	return string.format("%d,%d,%d", x, y, z)
end

local function getCell(x, y, z)
	return cells[key(x, y, z)]
end

local function coordinates(part)
	local x, y, z = part:GetAttribute("GridX"), part:GetAttribute("GridY"), part:GetAttribute("GridZ")
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return nil
	end
	if x % 1 ~= 0 or y % 1 ~= 0 or z % 1 ~= 0 then
		return nil
	end
	return x, y, z
end

for _, part in cellFolder:GetChildren() do
	if part:IsA("BasePart") then
		local x, y, z = coordinates(part)
		assert(x and not getCell(x, y, z), "Invalid or duplicate sand cell: " .. part.Name)
		cells[key(x, y, z)] = part
		initialCells += 1
	end
end

local function countCells()
	local count = 0
	for _ in cells do
		count += 1
	end
	return count
end

local function publishCounts()
	local remaining = countCells()
	assert(initialCells == remaining + dugCells, "Sand mass invariant failed")
	mountain:SetAttribute("InitialCells", initialCells)
	mountain:SetAttribute("RemainingCells", remaining)
	mountain:SetAttribute("DugCells", dugCells)
	mountain:SetAttribute("MovedCells", movedCells)
end

local function capture()
	local data = { schemaVersion = 1, revision = session and session.revision or 0,
		initialCells = initialCells, dugCells = dugCells, movedCells = movedCells,
		cells = {}, accounts = Economy.ExportAccounts() }
	for _, part in cells do
		local x, y, z = coordinates(part)
		table.insert(data.cells, { x = x, y = y, z = z })
	end
	return data
end

local loaded = capture()
if persistent then
	if game.GameId == 0 then status("LoadFailed") warn("Publish the test project before persistent play") return end
	local normalized, reason = Snapshot.Validate(loaded)
	if not normalized then status("LoadFailed") warn(reason) return end
	local store = game:GetService("DataStoreService"):GetDataStore("DigMountainPrototype_v1")
	local owner = game:GetService("HttpService"):GenerateGUID(false)
	for attempt = 1, 3 do
		session, reason = SaveSession.Open(store, "shared_world_v1", normalized, { owner = owner })
		if session or reason == "locked" then break end
		if not string.find(reason, "datastore error:", 1, true) then break end
		if attempt < 3 then task.wait(attempt) end
	end
	if not session then
		status(reason == "locked" and "Locked" or "LoadFailed")
		warn("Sand world load failed: " .. tostring(reason))
		return
	end
	loaded = session.snapshot
	local keep = {}
	for _, cell in loaded.cells do keep[key(cell.x, cell.y, cell.z)] = true end
	for cellKey, part in cells do
		if not keep[cellKey] then part:Destroy() cells[cellKey] = nil end
	end
	dugCells, movedCells = loaded.dugCells, loaded.movedCells
end

ready = true
Economy.Init(loaded.accounts, changed, canMutate, persistent)
status(persistent and (changeSequence > savedSequence and "Dirty" or "Saved") or "SessionOnly")
mountain:SetAttribute("SavedRevision", session and session.revision or 0)

local function saveWorld(release)
	if not session or session.closed then return true end
	if saving then return false end
	saving = true
	local sequence = changeSequence
	local data = capture()
	status("Saving")
	local ok, reason
	for attempt = 1, 3 do
		ok, reason = session:Save(data, release)
		if ok or not string.find(tostring(reason), "datastore error:", 1, true) then break end
		if attempt < 3 then task.wait(attempt) end
	end
	if ok then
		if not closing then ready = true end
		savedSequence = sequence
		mountain:SetAttribute("SavedRevision", session.revision)
		mountain:SetAttribute("LastSaveTime", os.time())
		status(changeSequence > savedSequence and "Dirty" or "Saved")
	else
		local lost = reason == "lease lost" or reason == "revision conflict"
		ready = false
		status(lost and "LockLost" or "SaveFailed")
		warn("Sand world save failed: " .. tostring(reason))
	end
	saving = false
	return ok
end

if persistent then
	task.spawn(function()
		while not closing do
			task.wait(30)
			if not closing then saveWorld(false) end
		end
	end)
	Players.PlayerRemoving:Connect(function() task.defer(saveWorld, false) end)
	game:BindToClose(function()
		closing, ready = true, false
		local deadline = os.clock() + 25
		while saving and os.clock() < deadline do task.wait(0.1) end
		if not saving then saveWorld(true) else warn("Save still busy at shutdown") end
	end)
end

local function isExposed(x, y, z)
	return not getCell(x + 1, y, z)
		or not getCell(x - 1, y, z)
		or not getCell(x, y + 1, z)
		or not getCell(x, y, z + 1)
		or not getCell(x, y, z - 1)
end

local function canSeeCell(character, root, target)
	local head = character:FindFirstChild("Head")
	local origin = head and head.Position or root.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local function hitsTarget(point)
		local hit = workspace:Raycast(origin, point - origin, params)
		return hit ~= nil and hit.Instance == target
	end
	if hitsTarget(target.Position) then
		return true
	end
	-- An occluded centre must not prevent digging a visible edge. Points are
	-- inset from the corners to avoid grazing neighbouring cells numerically.
	local half = target.Size * 0.45
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				local point = target.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
				if hitsTarget(point) then
					return true
				end
			end
		end
	end
	return false
end

-- A vacancy can be filled by sand one level above, either straight down
-- or diagonally from its immediate neighbours. Each step moves one Part.
local sourceOffsets = {
	{ 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
	{ 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 },
	{ 0, 0 },
}

local function settleAround(x, y, z)
	local vacantX, vacantY, vacantZ = x, y, z
	local moves = 0
	local characters = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			table.insert(characters, character)
		end
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = characters
	overlap.MaxParts = 1
	while moves < MAX_MOVES_PER_DIG do
		local source, sourceX, sourceY, sourceZ
		for _, offset in sourceOffsets do
			local sx, sy, sz = vacantX + offset[1], vacantY + 1, vacantZ + offset[2]
			local candidate = getCell(sx, sy, sz)
			if candidate then
				source, sourceX, sourceY, sourceZ = candidate, sx, sy, sz
				break
			end
		end
		if not source then
			break
		end
		local destination = source.Position + Vector3.new((vacantX - sourceX) * CELL_SIZE, -CELL_SIZE, (vacantZ - sourceZ) * CELL_SIZE)
		local box = CFrame.new(destination) * source.CFrame.Rotation
		if #workspace:GetPartBoundsInBox(box, source.Size * 0.95, overlap) > 0 then
			-- Keep this mass at its source instead of sealing a player into sand.
			break
		end

		cells[key(sourceX, sourceY, sourceZ)] = nil
		cells[key(vacantX, vacantY, vacantZ)] = source
		source:SetAttribute("GridX", vacantX)
		source:SetAttribute("GridY", vacantY)
		source:SetAttribute("GridZ", vacantZ)
		source.Name = string.format("Cell_%d_%d_%d", vacantX, vacantY, vacantZ)
		source.Position = destination
		vacantX, vacantY, vacantZ = sourceX, sourceY, sourceZ
		moves += 1
	end
	movedCells += moves
	return moves
end

local function tryDig(player, target)
	if not player:IsA("Player") or typeof(target) ~= "Instance" or not target:IsA("BasePart") then
		return false
	end
	if target.Parent ~= cellFolder then
		return false
	end
	local x, y, z = coordinates(target)
	if not x or getCell(x, y, z) ~= target or not isExposed(x, y, z) then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local equippedTool
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("SandPrototypeTool") == true then
			equippedTool = child
			break
		end
	end
	if not equippedTool then
		return false
	end
	if (root.Position - target.Position).Magnitude > MAX_DIG_DISTANCE then
		return false
	end
	local now = os.clock()
	if now - (lastDigAt[player] or -math.huge) < MIN_DIG_INTERVAL then
		return false
	end
	lastDigAt[player] = now

	if not canSeeCell(character, root, target) then
		return false
	end
	if not Economy.CanCarry(player) then
		return false
	end

	local effectPosition, effectColor = target.Position, target.Color
	cells[key(x, y, z)] = nil
	target:Destroy()
	dugCells += 1
	Economy.RecordDig(player)
	settleAround(x, y, z)
	publishCounts()
	digEvent:FireAllClients(effectPosition, effectColor, player.UserId)
	return true
end

digEvent.OnServerEvent:Connect(tryDig)
Players.PlayerRemoving:Connect(function(player)
	lastDigAt[player] = nil
end)
publishCounts()

local station = workspace:WaitForChild("SandPrototypeStation")
local sellPad = station:WaitForChild("SellPad")
local upgradePad = station:WaitForChild("UpgradePad")
sellPad:WaitForChild("SellPrompt").Triggered:Connect(function(player)
	Economy.Sell(player, sellPad)
end)
upgradePad:WaitForChild("UpgradePrompt").Triggered:Connect(function(player)
	Economy.BuyCapacity(player, upgradePad)
end)

local barrowPad = station:FindFirstChild("WheelbarrowPad")
if barrowPad then
	barrowPad:WaitForChild("WheelbarrowPrompt").Triggered:Connect(function(player)
		if Economy.BuyWheelbarrow(player, barrowPad) then
			local template = game:GetService("ReplicatedStorage"):FindFirstChild("DTM_Tools")
				and game:GetService("ReplicatedStorage").DTM_Tools:FindFirstChild("WheelbarrowTool")
			if template and not player.Backpack:FindFirstChild("WheelbarrowTool") then
				local owned = template:Clone()
				owned.Name = "WheelbarrowTool"
				owned.Parent = player.Backpack
			end
		end
	end)
end
