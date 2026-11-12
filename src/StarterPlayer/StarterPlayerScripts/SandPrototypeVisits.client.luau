-- Server selects the destination and keeps all plot permissions.
if workspace:GetAttribute("PersonalPlotsEnabled")~=true then return end
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild("SandPrototypeVisit")
local accessRemote=game.ReplicatedStorage:WaitForChild("SandPrototypeAccess")
local gui=Instance.new("ScreenGui")
gui.Name="SandPrototypeVisits"
gui.ResetOnSpawn=false
gui.DisplayOrder=7
gui.Parent=player:WaitForChild("PlayerGui")
local frame=Instance.new("Frame")
frame.Name="Menu"
frame.AnchorPoint=Vector2.new(1,0)
frame.Position=UDim2.new(1,-12,0,12)
frame.Size=UDim2.fromOffset(200,36)
frame.BackgroundColor3=Color3.fromRGB(24,31,39)
frame.BackgroundTransparency=0.08
frame.Parent=gui
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,10)
corner.Parent=frame
local toggle=Instance.new("TextButton")
toggle.Name="Toggle"
toggle.Size=UDim2.new(1,0,0,36)
toggle.BackgroundTransparency=1
toggle.Text="Участки"
toggle.Font=Enum.Font.GothamBold
toggle.TextSize=16
toggle.TextColor3=Color3.fromRGB(242,239,229)
toggle.Parent=frame
local list=Instance.new("ScrollingFrame")
list.Name="Destinations"
list.Position=UDim2.fromOffset(8,42)
list.Size=UDim2.new(1,-16,0,160)
list.BackgroundTransparency=1
list.BorderSizePixel=0
list.ScrollBarThickness=4
list.AutomaticCanvasSize=Enum.AutomaticSize.Y
list.CanvasSize=UDim2.fromOffset(0,0)
list.Visible=false
list.Parent=frame
local layout=Instance.new("UIListLayout")
layout.Padding=UDim.new(0,4)
layout.SortOrder=Enum.SortOrder.LayoutOrder
layout.Parent=list
local status=Instance.new("TextLabel")
status.Name="Status"
status.Position=UDim2.fromOffset(8,206)
status.Size=UDim2.new(1,-16,0,38)
status.BackgroundTransparency=1
status.Font=Enum.Font.GothamMedium
status.TextSize=12
status.TextColor3=Color3.fromRGB(186,204,186)
status.TextWrapped=true
status.Text="Помогай с разрешения хозяина"
status.Visible=false
status.Parent=frame
local accessButton=Instance.new("TextButton")
accessButton.Name="Access"
accessButton.Size=UDim2.new(1,-16,0,34)
accessButton.BackgroundColor3=Color3.fromRGB(51,67,66)
accessButton.TextColor3=Color3.fromRGB(242,239,229)
accessButton.Font=Enum.Font.GothamMedium
accessButton.TextSize=12
accessButton.Text="Копать у меня: закрыто"
accessButton.Visible=false
accessButton.Parent=frame
local currentMode="Closed"
local modes={Closed="Friends",Friends="Open",Open="Closed"}
accessButton.Activated:Connect(function()accessRemote:FireServer(modes[currentMode])end)
task.spawn(function()
	local mountain=require(game.ReplicatedStorage.SandPrototypeClientContext).GetMountain(player)
	local function update()
		currentMode=mountain:GetAttribute("AccessMode")or "Closed"
		local labels={Closed="закрыто",Friends="друзья",Open="всем"}
		accessButton.Text="Копать у меня: "..(labels[currentMode]or "закрыто")
	end
	mountain:GetAttributeChangedSignal("AccessMode"):Connect(update)
	update()
end)
local expanded=false
local rows=1
local function placeMenu()
	local camera=workspace.CurrentCamera
	local narrow=camera and camera.ViewportSize.X<520
	local contentHeight=rows*34+(rows-1)*4
	local inset=game:GetService("GuiService"):GetGuiInset()
	local coreHeight=camera and camera.ViewportSize.Y-inset.Y or 577
	local baseY=narrow and 172 or 12
	local listHeight=math.min(contentHeight,math.max(34,coreHeight-baseY-142))
	list.Size=UDim2.new(1,-16,0,listHeight)
	accessButton.Position=UDim2.fromOffset(8,42+listHeight+4)
	status.Position=UDim2.fromOffset(8,42+listHeight+42)
	frame.Position=UDim2.new(1,-12,0,narrow and 172 or 12)
	frame.Size=UDim2.fromOffset(expanded and 200 or 110,expanded and (130+listHeight)or 36)
end
local function show(value)
	expanded=value
	list.Visible=value
	status.Visible=value
	accessButton.Visible=value
	placeMenu()
	toggle.Text=value and "Закрыть" or "Участки"
end
toggle.Activated:Connect(function()show(not expanded)end)
local function refresh()
	for _,child in list:GetChildren()do if child:IsA("TextButton")then child:Destroy()end end
	local people=Players:GetPlayers()
	table.sort(people,function(a,b)
		if a==b then return false end
		if a==player then return true end
		if b==player then return false end
		return a.UserId<b.UserId
	end)
	for i,owner in people do
		if i>4 then break end
		local button=Instance.new("TextButton")
		button.Name="Plot_"..owner.UserId
		button:SetAttribute("DestinationUserId",owner.UserId)
		button.LayoutOrder=i
		button.Size=UDim2.new(1,0,0,34)
		button.BackgroundColor3=Color3.fromRGB(51,67,66)
		button.TextColor3=Color3.fromRGB(242,239,229)
		button.Font=Enum.Font.GothamMedium
		button.TextSize=14
		button.TextTruncate=Enum.TextTruncate.AtEnd
		button.Text=owner==player and "Домой" or owner.DisplayName
		button.Parent=list
		button.Activated:Connect(function()
			status.Text="Переходим…"
			remote:FireServer(owner.UserId)
		end)
	end
	rows=math.clamp(#people,1,4)
	placeMenu()
end
Players.PlayerAdded:Connect(refresh)
Players.PlayerRemoving:Connect(function()task.delay(0.1,refresh)end)
remote.OnClientEvent:Connect(function(ok,message)
	status.Text=message
	status.TextColor3=ok and Color3.fromRGB(186,224,186)or Color3.fromRGB(255,173,139)
end)
accessRemote.OnClientEvent:Connect(function(ok,message)
	status.Text=message
	status.TextColor3=ok and Color3.fromRGB(186,224,186)or Color3.fromRGB(255,173,139)
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeMenu)end
	placeMenu()
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeMenu)end
placeMenu()
refresh()
