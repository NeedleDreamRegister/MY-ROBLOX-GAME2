-- Drives the existing progression cart. No wallet, cargo or duplicate model.
local Players=game:GetService('Players')
local Manual={}
function Manual.Create(owner,model,canMutate)
 local root=model.PrimaryPart
 local active,driver,speed=false,nil,nil
 local controls={}local equipmentConnection
 local wheel=root.CFrame:ToObjectSpace(model.WheelTire.CFrame)
 local bowl=root.CFrame:ToObjectSpace(model.TrayBottom.CFrame)
 local scale=model:GetScale()
 local radius=.85*scale
 local box=model:GetAttribute('BodyBoxSize')*scale
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
  local look=Vector3.new(r.CFrame.LookVector.X,0,r.CFrame.LookVector.Z)
  if look.Magnitude<.1 then return end look=look.Unit
  local target=r.Position+look*1.5
  local current=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z).Unit
  local angle=math.atan2(current:Cross(look).Y,current:Dot(look))
  dt=math.min(dt,.1)
  look=CFrame.Angles(0,math.clamp(angle,-math.rad(120)*dt,math.rad(120)*dt),0):VectorToWorldSpace(current)
  local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude params.RespectCanCollide=true
  local excluded={model,ch}for _,p in Players:GetPlayers()do if p.Character then table.insert(excluded,p.Character)end end
  params.FilterDescendantsInstances=excluded
  local rotation=CFrame.lookAt(Vector3.zero,look)*CFrame.Angles(math.rad(-4),0,0)
  local wheelOffset=rotation:VectorToWorldSpace(wheel.Position)
  local horizontal=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
  if horizontal.Magnitude>18*dt then horizontal=horizontal.Unit*18*dt end
  local position=root.Position+horizontal
  local hit=workspace:Raycast(position+wheelOffset+Vector3.new(0,8,0),Vector3.new(0,-30,0),params)
  if not hit or hit.Normal.Y<.82 then model:SetAttribute('Blocked',true)return end
  position=Vector3.new(position.X,hit.Position.Y+radius-wheelOffset.Y,position.Z)
  local delta=position-root.Position
  if math.abs(delta.Y)>2 then model:SetAttribute('Blocked',true)return end
  local destination=CFrame.new(position)*rotation
  local overlap=OverlapParams.new()overlap.FilterType=Enum.RaycastFilterType.Exclude overlap.FilterDescendantsInstances=excluded overlap.RespectCanCollide=true overlap.MaxParts=1
  local from=(root.CFrame*wheel).Position local to=(destination*wheel).Position local travel=to-from
  if (delta.Magnitude>.001 and workspace:Blockcast(root.CFrame*bowl+Vector3.new(0,.65*scale,0),box,delta,params))
   or (travel.Magnitude>.001 and workspace:Spherecast(from,radius*.9,travel,params))
   or #workspace:GetPartBoundsInRadius(to,radius*.9,overlap)>0
   or #workspace:GetPartBoundsInBox(destination*bowl+Vector3.new(0,.65*scale,0),box,overlap)>0 then model:SetAttribute('Blocked',true)return end
  model:SetAttribute('Blocked',false)model:PivotTo(destination)
 end
 function api.Destroy()release()connection:Disconnect()prompt:Destroy()end
 return api
end
return Manual
