local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local state
local Context=require(game.ReplicatedStorage:WaitForChild("SandPrototypeClientContext"))
local mountain = Context.GetMountain(player)
local gui = Instance.new("ScreenGui")
gui.Name = "SandPrototypeHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "InventoryCard"
panel.Position = UDim2.fromOffset(12, 12)
panel.Size = UDim2.new(0.36, 0, 0, 150)
panel.BackgroundColor3 = Color3.fromRGB(24, 31, 39)
panel.BackgroundTransparency = 0.08
panel.Parent = gui
local bounds = Instance.new("UISizeConstraint")
bounds.MinSize = Vector2.new(245, 150)
bounds.MaxSize = Vector2.new(330, 150)
bounds.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local function text(name, y, height, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = UDim2.fromOffset(14, y)
	label.Size = UDim2.new(1, -28, 0, height)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromRGB(242, 239, 229)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamMedium
	label.TextSize = size
	label.Text = ""
	label.Parent = panel
	return label
end

local inventory = text("Inventory", 10, 25, 20)
inventory.TextScaled=true
local inventorySize=Instance.new("UITextSizeConstraint")inventorySize.MinTextSize=12 inventorySize.MaxTextSize=20 inventorySize.Parent=inventory
local bar = Instance.new("Frame")
bar.Name = "CapacityBar"
bar.Position = UDim2.fromOffset(14, 41)
bar.Size = UDim2.new(1, -28, 0, 7)
bar.BorderSizePixel = 0
bar.BackgroundColor3 = Color3.fromRGB(64, 73, 80)
bar.Parent = panel
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BorderSizePixel = 0
fill.BackgroundColor3 = Color3.fromRGB(230, 193, 111)
fill.Parent = bar
local money = text("MoneyAndXP", 52, 21, 16)
money.TextScaled=true
local moneySize=Instance.new("UITextSizeConstraint")
moneySize.MinTextSize=12
moneySize.MaxTextSize=16
moneySize.Parent=money
local upgrade = text("Upgrade", 76, 18, 13, Color3.fromRGB(173, 204, 243))
upgrade.TextScaled=true
local upgradeSize=Instance.new("UITextSizeConstraint")upgradeSize.MinTextSize=11 upgradeSize.MaxTextSize=13 upgradeSize.Parent=upgrade
local progress = text("MountainProgress", 96, 16, 12, Color3.fromRGB(223, 211, 171))
progress.TextScaled=true
local progressSize=Instance.new("UITextSizeConstraint")progressSize.MinTextSize=10 progressSize.MaxTextSize=12 progressSize.Parent=progress
local mountainBar = Instance.new("Frame")
mountainBar.Name = "MountainBar"
mountainBar.Position = UDim2.fromOffset(14, 113)
mountainBar.Size = UDim2.new(1, -28, 0, 3)
mountainBar.BorderSizePixel = 0
mountainBar.BackgroundColor3 = Color3.fromRGB(64, 73, 80)
mountainBar.Parent = panel
local mountainFill = Instance.new("Frame")
mountainFill.Name = "Fill"
mountainFill.Size = UDim2.fromScale(0, 1)
mountainFill.BorderSizePixel = 0
mountainFill.BackgroundColor3 = Color3.fromRGB(230, 193, 111)
mountainFill.Parent = mountainBar
local hint = text("Hint", 118, 16, 12)
local disclaimer = text("TestMode", 136, 13, 10, Color3.fromRGB(186, 188, 192))

-- Animate confirmed ratios only when their destination changes. Rapid state
-- updates cancel the preceding tween rather than accumulating competing motion.
local barStates={}
local function setRatio(target,ratio,immediate)
	ratio=math.clamp(ratio,0,1)
	local previous=barStates[target]
	if previous and previous.ratio==ratio then return end
	if previous and previous.tween then previous.tween:Cancel()end
	local entry={ratio=ratio}barStates[target]=entry
	local size=UDim2.fromScale(ratio,1)
	if immediate or not previous then target.Size=size return end
	entry.tween=TweenService:Create(target,TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=size})
	entry.tween:Play()
end

local function refresh()
	local saveStatus = mountain:GetAttribute("PersistenceStatus") or "Loading"
	local saveLabels = {
		Loading = "ЗАГРУЖАЕМ ПРОГРЕСС", Saved = "ПРОТОТИП · СОХРАНЕНО",
		Dirty = "ПРОТОТИП · ОЖИДАЕТ СОХРАНЕНИЯ", Saving = "ПРОТОТИП · СОХРАНЯЕМ…",
		SessionOnly = "ПРОТОТИП · БЕЗ СОХРАНЕНИЙ", SaveFailed = "СБОЙ СОХРАНЕНИЯ · ИГРА ОСТАНОВЛЕНА",
		Locked = "МИР ЗАНЯТ ДРУГИМ СЕРВЕРОМ", LoadFailed = "НЕ УДАЛОСЬ ЗАГРУЗИТЬ ДАННЫЕ",
		LockLost = "СЕССИЯ ПОТЕРЯНА · ПЕРЕЗАЙДИ",
	}
	local unavailableHints = {
		Loading = "Подключаем сохранение…",
		SaveFailed = "Сбой записи · действия остановлены",
		Locked = "Мир занят · перезайди позже",
		LoadFailed = "Нет данных · перезайди позже",
		LockLost = "Сессия потеряна · перезайди",
	}
	local unavailableHint = unavailableHints[saveStatus]
	disclaimer.Text = saveLabels[saveStatus] or saveStatus
	disclaimer.TextColor3 = (saveStatus == "SaveFailed" or saveStatus == "LoadFailed" or saveStatus == "LockLost" or saveStatus == "Locked")
		and Color3.fromRGB(255, 159, 139) or Color3.fromRGB(186, 188, 192)
	if not state then
		inventory.Text = saveStatus == "Loading" and "Загрузка прогресса…" or "Прогресс недоступен"
		money.Text, upgrade.Text = "", ""
		progress.Text = "Гора: загружаем прогресс…"
		setRatio(mountainFill,0,true)
		setRatio(fill,0,true)
		hint.Text = unavailableHint or "Нет прогресса · перезайди позже"
		return
	end
	local carried = state:GetAttribute("CarriedCells") or 0
	local capacity = state:GetAttribute("CapacityCells") or 20
	local coins = state:GetAttribute("Coins") or 0
	local xp = state:GetAttribute("XP") or 0
	local level = state:GetAttribute("CapacityLevel") or 0
	local pending=state:GetAttribute("PendingCells")or 0
	local cartCells=state:GetAttribute("CartCells")or 0
	local manual=carried-cartCells
	local manualCapacity=level==1 and 40 or 20
	local cartNearby=state:GetAttribute("CartNearby")==true
	local barrow = state:GetAttribute("BarrowOwned") or 0
	inventory.Text=(state:GetAttribute("BarrowOwned")or 0)==1
		and string.format("Руки %d/%d · Тачка %d/80",manual,manualCapacity,cartCells)
		or string.format("Песок %d / %d",carried,capacity)
	money.Text = string.format("Монеты  %d     Опыт  %d", coins, xp)
	setRatio(fill,cartNearby and (carried+pending)/capacity or (manual+pending)/manualCapacity)
	fill.BackgroundColor3 = Context.FreeCapacity(state)<=pending and Color3.fromRGB(245, 136, 95) or Color3.fromRGB(230, 193, 111)
	local shovelLevel=state:GetAttribute("ShovelLevel")or 0
	local finds=state:GetAttribute("FindCount")or 0
	local touch=UserInputService.PreferredInput==Enum.PreferredInput.Touch
	if shovelLevel==0 then
		upgrade.Text=touch and "Лопата II: 20 · до 2 ячеек за удар"or "Лопата II: H · 20 · до 2 ячеек"
	elseif level==0 and barrow==0 then
		upgrade.Text=touch and "Рюкзак II: 10  |  Тачка: 25" or "Рюкзак II: F · 10  |  Тачка: G · 25"
	elseif level==0 then
		upgrade.Text=touch and "Рюкзак II: 10  |  Тачка куплена" or "Рюкзак II: F · 10  |  Тачка куплена"
	elseif barrow==0 then
		upgrade.Text=touch and "Тачка: 25  |  Рюкзак II готов" or "Тачка: G · 25  |  Рюкзак II готов"
	else
		upgrade.Text="Снаряжение готово · Находок: "..finds
	end
	local initial = mountain:GetAttribute("InitialCells")
	local dug = mountain:GetAttribute("DugCells")
	local remaining = mountain:GetAttribute("RemainingCells")
	if type(initial) == "number" and initial > 0 and type(dug) == "number" then
		local ratio=math.clamp(dug/initial,0,1)
		-- Never round an unfinished mountain up to 100%.
		local percent=math.min(99.9,math.floor(ratio*1000)/10)
		progress.Text = remaining == 0 and string.format("Гора раскопана: %d / %d", dug, initial)
			or string.format("Гора %.1f%% · %d / %d", percent, dug, initial)
		setRatio(mountainFill,ratio)
	else
		progress.Text = "Гора: загружаем прогресс…"
		setRatio(mountainFill,0,true)
	end
	if unavailableHint then
		hint.Text = unavailableHint
	elseif state:GetAttribute("PushingCart")==true then
		hint.Text=UserInputService.PreferredInput==Enum.PreferredInput.Touch and "Вези к автомату · нажми на тачку"or "Вези к автомату · Q — оставить"
	elseif pending>0 then
		hint.Text=string.format("Ожидает подтверждения: %d песка",pending)
	elseif (state:GetAttribute("RewardSyncPending")or 0)>0 then
		hint.Text="Проверяем награды помощника…"
	elseif (state:GetAttribute("HelpStatus")or "")~=""then
		hint.Text=state:GetAttribute("HelpStatus")
	elseif barrow==1 and manual>=manualCapacity and not cartNearby then
		hint.Text="Руки заняты · подведи тачку"
	elseif carried >= capacity then
		hint.Text = "Переноска полна · продай песок"
	elseif cartCells>0 and manual==0 then
		hint.Text="Подкати тачку к зелёной станции"
	elseif carried > 0 then
		hint.Text = "Зелёная станция покупает песок"
	elseif remaining == 0 then
		hint.Text = "Своя гора раскопана"
	elseif shovelLevel==0 and coins>=20 then
		hint.Text="Лопата II доступна · бронзовая станция"
	elseif level==0 and barrow==0 and coins>=25 then
		hint.Text = touch and "Выбери улучшение на площадке" or "Выбери улучшение: F или G"
	elseif level==0 and coins>=10 then
		hint.Text = "Рюкзак II доступен · синяя станция"
	elseif barrow==0 and coins>=25 then
		hint.Text = touch and "Тачка доступна · площадка" or "Тачка доступна · площадка (G)"
	else
		hint.Text = UserInputService.PreferredInput == Enum.PreferredInput.Touch
			and "Коснись песка, чтобы копать" or "Возьми лопату · ЛКМ по песку"
	end
end

mountain:GetAttributeChangedSignal("PersistenceStatus"):Connect(refresh)
for _, attribute in { "InitialCells", "DugCells", "RemainingCells" } do
	mountain:GetAttributeChangedSignal(attribute):Connect(refresh)
end
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
refresh()
task.spawn(function()
	state = player:WaitForChild("SandPrototypeState")
	state.AttributeChanged:Connect(refresh)
	refresh()
end)
