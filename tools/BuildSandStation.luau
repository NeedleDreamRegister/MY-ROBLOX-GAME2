-- Run once in the Edit DataModel. Never replaces an existing station.
assert(not workspace:FindFirstChild("SandPrototypeStation"), "Station already exists")
local station = Instance.new("Model")
station.Name = "SandPrototypeStation"

local function makePad(name, position, color, title, action, key, gamepadKey, promptName)
	local pad = Instance.new("Part")
	pad.Name = name
	pad.Size = Vector3.new(6, 1, 6)
	pad.Position = position
	pad.Color = color
	pad.Material = Enum.Material.SmoothPlastic
	pad.Anchored = true
	pad.Parent = station
	local sign = Instance.new("BillboardGui")
	sign.Name = "StationSign"
	sign.Size = UDim2.fromOffset(230, 70)
	sign.StudsOffset = Vector3.new(0, 5, 0)
	sign.MaxDistance = 70
	sign.AlwaysOnTop = true
	sign.Parent = pad
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(24, 31, 39)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 17
	label.TextWrapped = true
	label.Text = title
	label.Parent = sign
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = promptName
	prompt.ActionText = action
	prompt.ObjectText = title
	prompt.KeyboardKeyCode = key
	prompt.GamepadKeyCode = gamepadKey
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.25
	prompt.RequiresLineOfSight = true
	prompt.Parent = pad
	return pad
end

station.PrimaryPart = makePad("SellPad", Vector3.new(5, 0.5, -14), Color3.fromRGB(63, 170, 117), "ПРОДАЖА ПЕСКА\n1 ячейка = 1 монета", "Продать весь песок", Enum.KeyCode.E, Enum.KeyCode.ButtonX, "SellPrompt")
makePad("UpgradePad", Vector3.new(13, 0.5, -14), Color3.fromRGB(74, 132, 218), "РЮКЗАК II\n40 ячеек · 10 монет", "Улучшить вместимость", Enum.KeyCode.F, Enum.KeyCode.ButtonY, "UpgradePrompt")
station.Parent = workspace
return station:GetFullName()
