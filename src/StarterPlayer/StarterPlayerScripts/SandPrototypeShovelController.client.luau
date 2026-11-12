-- One action path for mouse, touch and gamepad. Only the server grants sand.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local mouse=player:GetMouse()
local Context=require(ReplicatedStorage:WaitForChild("SandPrototypeClientContext"))
local mountain=Context.GetMountain(player)
local cells=mountain:WaitForChild("Cells")
local digEvent=ReplicatedStorage:WaitForChild("SandPrototypeDig")
local bindings={}
local function bind(tool)
 if not tool:IsA("Tool")or tool:GetAttribute("SandPrototypeTool")~=true or bindings[tool]then return end
local INTERVAL=0.16 -- Above the server's 0.12s limit; not a source of authority.
bindings[tool]=true
local connections={}
local restGrip=tool.Grip
local tween,heldInput
local sequence,lastAction,lastHint=0,-math.huge,-math.huge
local held,closed=false,false
local originalManual=tool.ManualActivationOnly
local function connect(signal,callback)
 local c=signal:Connect(callback)table.insert(connections,c)return c
end
local function touchMode()return Input.PreferredInput==Enum.PreferredInput.Touch end
local function equipped()return not closed and tool.Parent==player.Character end
local function hint(message)
 if os.clock()-lastHint<1 then return end lastHint=os.clock()
 local gui=player.PlayerGui:FindFirstChild("SandPrototypeFeedback")
 local event=gui and gui:FindFirstChild("ActionHint")
 if event then event:Fire(message)end
end
local function aim(position)
 local ray=Context.AimRay(mouse,position)
 if not ray then return nil end
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={player.Character}
 return Context.ResolveHit(player,workspace:Raycast(ray.Origin,ray.Direction*200,params),cells)
end
local function permitted(target)
 if not equipped()or not tool.Enabled then return false end
 local state=player:FindFirstChild("SandPrototypeState")
 if not state then return false end
 if state:GetAttribute("PushingCart")==true then return false end
 local status=mountain:GetAttribute("PersistenceStatus")
 if status~="Saved"and status~="Saving"and status~="Dirty"and status~="SessionOnly"then
  hint("Прогресс пока недоступен")return false
 end
 if Context.FreeCapacity(state)<=(state:GetAttribute("PendingCells")or 0)then
  hint("Сдайте песок или подкатите тачку")return false
 end
 if not Context.CanTarget(player,target,cells)then return false end
 local root=player.Character:FindFirstChild("HumanoidRootPart")
 if not root or(root.Position-target.Position).Magnitude>24 then return false end
 return true
end
local function pose(grip,duration,direction)
 if tween then tween:Cancel()end
 tween=TweenService:Create(tool,TweenInfo.new(duration,Enum.EasingStyle.Quad,direction),{Grip=grip})
 tween:Play()
end
local function cancel()
 held=false heldInput=nil sequence+=1
 if tween then tween:Cancel()tween=nil end
 tool.Grip=restGrip tool:SetAttribute("DigSwingActive",false)
end
local function dig(position)
 local now=os.clock()
 if now-lastAction<INTERVAL or not permitted(aim(position))then return end
 lastAction=now sequence+=1 local action=sequence
 tool:SetAttribute("DigSwingActive",true)
 pose(restGrip*CFrame.Angles(math.rad(24),0,math.rad(-8)),0.035,Enum.EasingDirection.Out)
 task.delay(0.035,function()
  if action~=sequence or not equipped()then return end
  local target=aim(position)
  if permitted(target)then
   local sound=tool:FindFirstChild("Handle")and tool.Handle:FindFirstChild("SwingSound")
   if sound then sound:Play()end
   digEvent:FireServer(Context.Request(target))
  end
  pose(restGrip*CFrame.Angles(math.rad(-38),0,math.rad(5)),0.04,Enum.EasingDirection.In)
  task.delay(0.04,function()
   if action~=sequence or not equipped()then return end
   pose(restGrip,0.065,Enum.EasingDirection.Out)
   task.delay(0.065,function()
    if action==sequence and not closed then tool.Grip=restGrip tool:SetAttribute("DigSwingActive",false)end
   end)
  end)
 end)
end
local function beginHold(input)
 if not equipped()then return end held=true heldInput=input dig()
end
local gui=Instance.new("ScreenGui")gui.Name="DTM_MobileDig"gui.ResetOnSpawn=false
local button=Instance.new("TextButton")button.Name="DigButton"
button.Size=UDim2.fromOffset(116,62)button.AnchorPoint=Vector2.new(1,1)
button.Position=UDim2.new(1,-28,1,-160)button.Text="КОПАТЬ"
button.TextSize=20 button.Font=Enum.Font.GothamBold
button.TextColor3=Color3.fromRGB(255,248,220)button.BackgroundColor3=Color3.fromRGB(198,145,48)
button.Parent=gui
local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,14)corner.Parent=button
gui.Parent=player:WaitForChild("PlayerGui")
local function updateInput()
 cancel()
 tool.ManualActivationOnly=touchMode()or originalManual
 gui.Enabled=touchMode()and equipped()
end
connect(tool.Equipped,function()restGrip=tool.Grip updateInput()end)
connect(tool.Unequipped,function()cancel()gui.Enabled=false end)
connect(tool.Activated,function()if not touchMode()then beginHold(nil)end end)
connect(tool.Deactivated,function()held=false heldInput=nil end)
connect(button.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then beginHold(input)end
end)
connect(Input.InputEnded,function(input)
 if input==heldInput or input.UserInputType==Enum.UserInputType.MouseButton1 then held=false heldInput=nil end
end)
connect(Input.TouchTapInWorld,function(position,processed)
 if touchMode()and not processed and equipped()and not Context.TouchBlocked(player.PlayerGui,position)then dig(position)end
end)
connect(Input:GetPropertyChangedSignal("PreferredInput"),updateInput)
connect(Input.WindowFocusReleased,cancel)
connect(RunService.Heartbeat,function()if held then dig()end end)
connect(player.CharacterRemoving,cancel)
connect(tool.Destroying,function()
 cancel()closed=true gui:Destroy()bindings[tool]=nil
 for _,connection in connections do connection:Disconnect()end
end)
updateInput()
if touchMode()and player.Character and tool.Parent==player.Backpack then
 local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
 if humanoid then humanoid:EquipTool(tool)end
end
end
local backpackConnection
local function watchBackpack(backpack)
 if backpackConnection then backpackConnection:Disconnect()end
 backpackConnection=backpack.ChildAdded:Connect(bind)
 for _,tool in backpack:GetChildren()do bind(tool)end
end
player.ChildAdded:Connect(function(child)if child:IsA("Backpack")then watchBackpack(child)end end)
watchBackpack(player:WaitForChild("Backpack"))
local characterConnection
local function watchCharacter(character)
 if characterConnection then characterConnection:Disconnect()end
 characterConnection=character.ChildAdded:Connect(bind)
 for _,tool in character:GetChildren()do bind(tool)end
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then watchCharacter(player.Character)end
