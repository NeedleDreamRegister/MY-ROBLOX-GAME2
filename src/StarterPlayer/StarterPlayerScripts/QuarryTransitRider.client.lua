-- This controller only owns jump while this character is in the park shuttle.
local Players=game:GetService('Players')
local CAS=game:GetService('ContextActionService')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild('QuarryTransitRequests'):WaitForChild('ExitRide')
local action='QuarryTransitSafeExit'
local activeHumanoid=nil
local activeCart=nil
local previousJumping=true
local watched={}
local exitQueued=false
local hud=Instance.new('ScreenGui') hud.Name='QuarryTransitHUD' hud.ResetOnSpawn=false hud.DisplayOrder=5 hud.Enabled=false hud.Parent=player:WaitForChild('PlayerGui')
local panel=Instance.new('Frame') panel.Name='RidePanel' panel.AnchorPoint=Vector2.new(.5,1) panel.Position=UDim2.new(.5,0,1,-20) panel.Size=UDim2.new(.9,0,0,82) panel.BackgroundColor3=Color3.fromRGB(26,40,34) panel.BackgroundTransparency=.07 panel.BorderSizePixel=0 panel.Parent=hud
local sizeLimit=Instance.new('UISizeConstraint') sizeLimit.MaxSize=Vector2.new(360,82) sizeLimit.MinSize=Vector2.new(260,82) sizeLimit.Parent=panel
local corner=Instance.new('UICorner') corner.CornerRadius=UDim.new(0,13) corner.Parent=panel
local outline=Instance.new('UIStroke') outline.Color=Color3.fromRGB(171,145,89) outline.Transparency=.52 outline.Thickness=1 outline.Parent=panel
local title=Instance.new('TextLabel') title.Position=UDim2.fromOffset(14,11) title.Size=UDim2.new(1,-174,0,20) title.TextXAlignment=Enum.TextXAlignment.Left title.Font=Enum.Font.GothamBold title.TextSize=13 title.Text='QG TOURING' title.TextColor3=Color3.fromRGB(234,222,190) title.BackgroundTransparency=1 title.Parent=panel
local status=Instance.new('TextLabel') status.Name='RideStatus' status.Position=UDim2.fromOffset(14,33) status.Size=UDim2.new(1,-174,0,30) status.TextXAlignment=Enum.TextXAlignment.Left status.TextYAlignment=Enum.TextYAlignment.Top status.Font=Enum.Font.Gotham status.TextSize=12 status.TextWrapped=true status.TextColor3=Color3.fromRGB(203,216,202) status.BackgroundTransparency=1 status.Parent=panel
local button=Instance.new('TextButton') button.Name='ExitButton' button.AnchorPoint=Vector2.new(1,0) button.Position=UDim2.new(1,-12,0,15) button.Size=UDim2.fromOffset(144,42) button.BackgroundColor3=Color3.fromRGB(56,86,68) button.BorderSizePixel=0 button.TextColor3=Color3.fromRGB(245,234,207) button.Font=Enum.Font.GothamBold button.TextSize=12 button.Parent=panel
local buttonCorner=Instance.new('UICorner') buttonCorner.CornerRadius=UDim.new(0,9) buttonCorner.Parent=button
local track=Instance.new('Frame') track.Position=UDim2.fromOffset(14,72) track.Size=UDim2.new(1,-28,0,3) track.BackgroundColor3=Color3.fromRGB(66,82,68) track.BorderSizePixel=0 track.Parent=panel
local progress=Instance.new('Frame') progress.Name='LapProgress' progress.Size=UDim2.fromScale(0,1) progress.BackgroundColor3=Color3.fromRGB(186,161,102) progress.BorderSizePixel=0 progress.Parent=track
local function updateHUD()
 if not activeCart or not activeHumanoid then hud.Enabled=false return end
 hud.Enabled=true
 if activeCart:GetAttribute('Docked') then
  status.Text='Посадка · '..math.ceil(activeCart:GetAttribute('DwellRemaining') or 0)..' с'
  button.Text='Выйти · Пробел'
 elseif exitQueued then status.Text='Выход заказан · F отменить' button.Text='Выйти · Пробел'
 else status.Text='Пробел — выйти сразу' button.Text='Выйти · Пробел' end
 local length=activeCart:GetAttribute('RouteLength') or 1
 progress.Size=UDim2.fromScale(math.clamp((activeCart:GetAttribute('Travel') or 0)/length,0,1),1)
end
local function requestExit()
 if activeCart and activeHumanoid then remote:FireServer(activeCart:GetAttribute('Docked') and 'Exit' or 'ToggleExit') end
end
button.Activated:Connect(function()if activeCart and activeHumanoid then remote:FireServer('JumpExit') end end)
local hudTimer=0
RunService.Heartbeat:Connect(function(dt) hudTimer+=dt if hudTimer>=.1 then hudTimer=0 updateHUD() end end)
local function updatePrompts(cart)
 if not cart.Parent then return end
 local root=cart.PrimaryPart or cart:FindFirstChild('Chassis')
 if root and root:FindFirstChild('ExitPrompt') then
  local enabled=activeCart==cart and cart:GetAttribute('Docked')==true
  if root.ExitPrompt.Enabled~=enabled then root.ExitPrompt.Enabled=enabled end
 end
 local folder=cart:FindFirstChild('PassengerSeats')
 if folder then for _,seat in folder:GetChildren() do
  local prompt=seat:FindFirstChild('BoardPrompt')
  if prompt then
   local enabled=seat:GetAttribute('AvailableForBoarding')==true and activeHumanoid==nil
   if prompt.Enabled~=enabled then prompt.Enabled=enabled end
  end
 end end
end
local function updateAllPrompts() for cart in watched do updatePrompts(cart) end end
local function watchCart(cart)
 if watched[cart] or not cart:GetAttribute('TransitOnly') then return end
 watched[cart]=true
 task.spawn(function()
  local seats=cart:WaitForChild('PassengerSeats',10)
  local root=cart:WaitForChild('Chassis',10)
  if not seats or not root then return end
  local exit=root:WaitForChild('ExitPrompt',10)
  if not exit then return end
  cart:GetAttributeChangedSignal('Docked'):Connect(function()updatePrompts(cart)end)
  exit:GetPropertyChangedSignal('Enabled'):Connect(function()updatePrompts(cart)end)
  for _,seat in seats:GetChildren() do
   local prompt=seat:WaitForChild('BoardPrompt',10)
   if prompt then
    seat:GetAttributeChangedSignal('AvailableForBoarding'):Connect(function()updatePrompts(cart)end)
    prompt:GetPropertyChangedSignal('Enabled'):Connect(function()updatePrompts(cart)end)
   end
  end
  updatePrompts(cart)
 end)
 cart.AncestryChanged:Connect(function()if not cart:IsDescendantOf(workspace)then watched[cart]=nil end end)
end
task.spawn(function()
 local carts=workspace:WaitForChild('QuarryTransitVehicles')
 for _,cart in carts:GetChildren() do watchCart(cart) end
 carts.ChildAdded:Connect(watchCart)
end)
local function release()
 CAS:UnbindAction(action)
 if activeHumanoid and activeHumanoid.Parent then activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,previousJumping) end
 activeHumanoid=nil
 activeCart=nil
 exitQueued=false
 hud.Enabled=false
 updateAllPrompts()
end
local function characterAdded(character)
 release()
 local humanoid=character:WaitForChild('Humanoid')
 local function seated(sitting,seat)
  release()
  local cart=seat and seat:FindFirstAncestorOfClass('Model')
  if not sitting or not seat or not cart or not cart:GetAttribute('TransitOnly') or not cart:FindFirstChild('PassengerSeats') or not seat:IsDescendantOf(cart.PassengerSeats) then return end
  activeHumanoid=humanoid
  activeCart=cart
  previousJumping=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
  humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
  updateAllPrompts()
  updateHUD()
  CAS:BindActionAtPriority(action,function(_,state,input)
   if state==Enum.UserInputState.Begin then
    if input.KeyCode==Enum.KeyCode.F then requestExit()
    else remote:FireServer('JumpExit') end
   end
   return Enum.ContextActionResult.Sink
  end,false,3000,Enum.PlayerActions.CharacterJump,Enum.KeyCode.F)
 end
 humanoid.Seated:Connect(seated)
 if humanoid.SeatPart then seated(true,humanoid.SeatPart) end
 humanoid.Died:Connect(release)
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then task.spawn(characterAdded,player.Character) end
-- Both peers agree on the exit pose before normal character ownership resumes.
remote.OnClientEvent:Connect(function(character,target)
 if character=='QueueStatus' then exitQueued=target==true updateHUD() return end
 if character~=player.Character or typeof(target)~='CFrame' then return end
 local humanoid=character:FindFirstChildOfClass('Humanoid')
 local root=character:FindFirstChild('HumanoidRootPart')
 if not humanoid or not root or humanoid.Health<=0 then return end
 humanoid.Sit=false
 release()
 character:PivotTo(target)
 root.AssemblyLinearVelocity=Vector3.zero
 root.AssemblyAngularVelocity=Vector3.zero
 humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end)

