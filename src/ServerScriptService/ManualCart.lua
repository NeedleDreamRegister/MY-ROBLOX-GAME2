-- Drives the existing progression cart. No wallet, cargo or duplicate model.
local Manual={}
function Manual.Create(owner,model,canMutate)
 local root=model.PrimaryPart
 local active,driver,speed=false,nil,nil
 local controls={}local equipmentConnection
 local motion=require(game.ReplicatedStorage.GroundCartMotion).Create(model)
 local prompt=Instance.new('ProximityPrompt')prompt.Name='ManualPushPrompt'
 prompt.KeyboardKeyCode=Enum.KeyCode.Q prompt.HoldDuration=.3 prompt.MaxActivationDistance=7
 prompt.RequiresLineOfSight=false prompt.ObjectText='ТАЧКА'prompt.ActionText='Взяться за ручки'prompt.Parent=root
 local function publish(value)
  model:SetAttribute('Pushing',value)
  local f=owner:FindFirstChild('SandPrototypeState')if f then f:SetAttribute('PushingCart',value)end
 end
 local function release()
  if equipmentConnection then equipmentConnection:Disconnect()equipmentConnection=nil end
  for _,c in controls do c:Destroy()end table.clear(controls)
  if driver and driver.Parent and speed then driver.WalkSpeed=speed end
  if active then model:SetAttribute('ManualParked',true)end
  active=false driver=nil speed=nil publish(false)prompt.ActionText='Взяться за ручки'
 end
 local function toggle(actor)
  if actor~=owner or not canMutate()then return end
  if active then release()return end
  local ch=owner.Character local h=ch and ch:FindFirstChildOfClass('Humanoid')local r=ch and ch:FindFirstChild('HumanoidRootPart')
  if not h or h.Health<=0 or h.SeatPart or ch:GetAttribute('MountainSliding')or not r or(r.Position-root.Position).Magnitude>8 then return end
  active=true driver=h speed=h.WalkSpeed h.WalkSpeed=math.min(speed,12)h:UnequipTools()
  model:SetAttribute('ManualParked',false)publish(true)prompt.ActionText='Оставить тачку'
  for _,side in {'Left','Right'}do
   local upper=ch:FindFirstChild(side..'UpperArm')local hand=ch:FindFirstChild(side..'Hand')
   if upper and hand then
    local ik=Instance.new('IKControl')ik.Name='ManualCartGrip'..side
    ik.Type=Enum.IKControlType.Position ik.ChainRoot=upper ik.EndEffector=hand:FindFirstChild(side..'GripAttachment')or hand
    ik.Target=model['Handle'..side].GripTarget ik.Weight=1 ik.SmoothTime=.08 ik.Priority=5 ik.Parent=h
    table.insert(controls,ik)
   end
  end
  equipmentConnection=ch.ChildAdded:Connect(function(o)if o:IsA('Tool')then task.defer(function()if active and driver==h then h:UnequipTools()end end)end end)
 end
 local connection=prompt.Triggered:Connect(toggle)
 local api={Toggle=toggle}
 function api.Update(dt,enabled)
  prompt.Enabled=enabled and canMutate()
  if not active then return end
  local ch=owner.Character local h=ch and ch:FindFirstChildOfClass('Humanoid')local r=ch and ch:FindFirstChild('HumanoidRootPart')
  if not enabled or not canMutate()or h~=driver or h.Health<=0 or h.SeatPart or ch:GetAttribute('MountainSliding')or not r or(r.Position-root.Position).Magnitude>9 then release()return end
  local destination,blocked=motion.Step(ch,dt)
  model:SetAttribute('Blocked',blocked==true)
  if destination then model:PivotTo(destination)end
 end
 function api.Destroy()release()connection:Disconnect()prompt:Destroy()end
 return api
end
return Manual
