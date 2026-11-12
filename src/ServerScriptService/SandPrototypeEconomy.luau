-- Server-only accounting. Historical accounts remain in the atomic world save.
local Players = game:GetService("Players")
local function create(owner)
local connections = {}
local Economy = {}
local states = {}
local lastStationAction = {}
local initialized = false
local accounts = {}
local changed = function() end
local allowed = function() return true end
local persistentIds = false
local transport

local START_CAPACITY = 20
local UPGRADED_CAPACITY = 40
local UPGRADE_COST = 10
local BARROW_CAPACITY_BONUS = 80
local BARROW_COST = 25
local SHOVEL_COST = 20
local SELL_PRICE = 1
local MAX_STATION_DISTANCE = 10
local ACTION_INTERVAL = 0.25

local function setWheelbarrowLoad(tool, state)
	local load = tool and tool:FindFirstChild("SandLoad")
	if not load or not load:IsA("BasePart") then return end
	local fraction = math.clamp(state.CarriedCells / math.max(state.CapacityCells, 1), 0, 1)
	load.Transparency = fraction == 0 and 1 or 0
	load.Size = Vector3.new(2.1, 0.05 + 0.4 * fraction, 1.4)
end

local function refreshWheelbarrowLoad(player, state)
	if transport then transport.Update(state)return end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tool = backpack and backpack:FindFirstChild("WheelbarrowTool")
	if not tool and player.Character then tool = player.Character:FindFirstChild("WheelbarrowTool") end
	setWheelbarrowLoad(tool, state)
end

local function refreshShovel(player,state)
	if (state.ShovelLevel or 0)==0 then return end
	local function update(container)
		if not container then return end
		for _,tool in container:GetChildren()do
			if tool:IsA("Tool") and tool:GetAttribute("SandPrototypeTool")==true and tool:FindFirstChild("Blade")then
				tool.ToolTip="Лопата II · до 2 ячеек за удар"
				local blade=tool:FindFirstChild("Blade")
				if blade and blade:IsA("BasePart")then
					local original=blade:GetAttribute("OriginalBladeSize")or blade.Size
					blade:SetAttribute("OriginalBladeSize",original)
					blade.Size=Vector3.new(original.X*1.3,original.Y,original.Z)
					blade.Color=Color3.fromRGB(194,151,83)
				end
			end
		end
	end
	update(player:FindFirstChildOfClass("Backpack"))
	update(player.Character)
end

local function publish(player, state)
	local folder = player:FindFirstChild("SandPrototypeState")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SandPrototypeState"
		folder.Parent = player
	end
	for name, value in state do
		folder:SetAttribute(name, value)
	end
	refreshWheelbarrowLoad(player, state)
	refreshShovel(player,state)
end

local function grantWheelbarrow(player)
	local state = states[player]
	if not state or state.BarrowOwned ~= 1 then return end
	if transport then transport.Update(state)return end
	local toolsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("DTM_Tools")
	local toolTemplate = toolsFolder and toolsFolder:FindFirstChild("WheelbarrowTool")
	local backpack=player:FindFirstChildOfClass("Backpack")
	if not toolTemplate or not backpack or backpack:FindFirstChild("WheelbarrowTool")
		or (player.Character and player.Character:FindFirstChild("WheelbarrowTool")) then return end
	local owned = toolTemplate:Clone()
	owned.Name = "WheelbarrowTool"
	setWheelbarrowLoad(owned, state)
	owned.Parent = backpack
end
local function addPlayer(player)
	if (owner and player ~= owner) or states[player] then return end
	if persistentIds and player.UserId <= 0 then
		player:Kick("Для локального теста игроков отключите PersistenceEnabled в серверном скрипте.")
		return
	end
	local id = tostring(player.UserId)
	local state = accounts[id]
	if not state then
		local count = 0 for _ in accounts do count += 1 end
		if count >= 128 then player:Kick("Тестовый мир достиг лимита профилей.") return end
		state = { CarriedCells = 0, CartCells=0, CapacityCells = START_CAPACITY, Coins = 0, XP = 0, CapacityLevel = 0, BarrowOwned = 0, ShovelLevel=0 }
		accounts[id] = state
		changed()
	end
	states[player] = state
	publish(player, state)
	grantWheelbarrow(player)
	table.insert(connections, player.CharacterAdded:Connect(function()
		task.defer(function()
			if states[player] then grantWheelbarrow(player) refreshShovel(player,states[player]) end
		end)
	end))
end

function Economy.Init(savedAccounts, onChanged, canMutate, requirePersistentIds, cart)
	if initialized then return end
	initialized = true
	changed = onChanged or changed
	allowed = canMutate or allowed
	persistentIds = requirePersistentIds == true
	transport=cart
	for id, state in savedAccounts or {} do
		accounts[id] = table.clone(state)
		accounts[id].CartCells=state.CartCells or ((state.BarrowOwned or 0)==1 and math.min(state.CarriedCells,80)or 0)
	end
	table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		lastStationAction[player] = nil
	end))
	for _, player in Players:GetPlayers() do addPlayer(player) end
end

function Economy.CanCarry(player)
	local state = states[player]
	return allowed() and state ~= nil and Economy.FreeCapacity(player)>0
end

function Economy.FreeCapacity(player)
	local state=states[player]
	if not state then return 0 end
	if not transport then return state.CapacityCells-state.CarriedCells end
	local cart=state.CartCells or 0
	local manualCapacity=state.CapacityLevel==1 and UPGRADED_CAPACITY or START_CAPACITY
	local free=math.max(0,manualCapacity-(state.CarriedCells-cart))
	if state.BarrowOwned==1 and transport.CanLoad()then free+=80-cart end
	return free
end

local function addSand(player,state,amount)
	if state.BarrowOwned==1 and (not transport or transport.CanLoad())then
		state.CartCells=(state.CartCells or 0)+math.min(amount,80-(state.CartCells or 0))
	end
	state.CarriedCells+=amount
	state.XP+=amount
end

function Economy.RecordDig(player)
	local state = states[player]
	assert(allowed() and state and Economy.FreeCapacity(player)>0, "Dig exceeds inventory capacity")
	addSand(player,state,1)
	changed()
	publish(player, state)
end

function Economy.Credit(player,amount)
	local state=states[player]
	if not allowed() or not state or amount<1 or amount%1~=0 or amount>Economy.FreeCapacity(player) then return false end
	addSand(player,state,amount)
	changed()
	publish(player,state)
	return true
end

local function canUseStation(player, pad)
	if not allowed() then return false end
	local state = states[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not state or not root or not humanoid or humanoid.Health <= 0 then return false end
	if (root.Position - pad.Position).Magnitude > MAX_STATION_DISTANCE then return false end
	local now = os.clock()
	if now - (lastStationAction[player] or -math.huge) < ACTION_INTERVAL then return false end
	lastStationAction[player] = now
	return true
end

function Economy.Sell(player, pad)
	if not canUseStation(player, pad) then return false end
	local state = states[player]
	if state.CarriedCells == 0 then return false end
	local cart=state.CartCells or 0
	local delivered=state.CarriedCells-cart
	if not transport or transport.CanSell(pad)then delivered+=cart state.CartCells=0 end
	if delivered==0 then return false end
	local proceeds = delivered * SELL_PRICE
	state.CarriedCells -= delivered
	state.Coins += proceeds
	changed()
	publish(player, state)
	return true
end

function Economy.BuyCapacity(player, pad)
	if not canUseStation(player, pad) then return false end
	local state = states[player]
	if state.CapacityLevel >= 1 or state.Coins < UPGRADE_COST then return false end
	state.Coins -= UPGRADE_COST
	state.CapacityCells = UPGRADED_CAPACITY + (state.BarrowOwned or 0) * BARROW_CAPACITY_BONUS
	state.CapacityLevel = 1
	changed()
	publish(player, state)
	return true
end

function Economy.BuyWheelbarrow(player, pad)
	if not canUseStation(player, pad) then return false end
	local state = states[player]
	if state.BarrowOwned ~= 0 or state.Coins < BARROW_COST then return false end
	state.Coins -= BARROW_COST
	state.BarrowOwned = 1
	-- Wheelbarrow adds carry capacity on top of backpack level.
	state.CapacityCells = (state.CapacityLevel == 1 and UPGRADED_CAPACITY or START_CAPACITY) + BARROW_CAPACITY_BONUS
	changed()
	publish(player, state)
	grantWheelbarrow(player)
	return true
end

function Economy.GetSnapshot(player)
	local state = states[player]
	return state and table.clone(state) or nil
end

function Economy.BuyShovel(player,pad)
	if not canUseStation(player,pad) then return false end
	local state=states[player]
	if (state.ShovelLevel or 0)>=1 or state.Coins<SHOVEL_COST then return false end
	state.Coins-=SHOVEL_COST
	state.ShovelLevel=1
	changed()
	publish(player,state)
	return true
end

function Economy.ExportAccounts()
	local result = {}
	for id, state in accounts do result[id] = table.clone(state) end
	return result
end

function Economy.Destroy()
 for _, connection in connections do connection:Disconnect() end
 table.clear(states)
 if transport then transport.Destroy()end
end
return Economy
end
local default = create(nil)
default.Create = create
return default
