local P=game.Players.LocalPlayer
local Pose=require(game.ReplicatedStorage:WaitForChild('CartPose'))
local Run=game:GetService('RunService')
local folder=Instance.new('Folder');folder.Name='DTMCartRenders';folder.Parent=workspace
local entries={}
local function watch(m)
 if not m:IsA('Model')or m:GetAttribute('FollowCart')~=true or entries[m]then return end
 local e={hidden={},guis={},angle=0};entries[m]=e
 task.defer(function()
  local root=m:WaitForChild('GripRoot',8);local tire=m:WaitForChild('WheelTire',8);local load=m:WaitForChild('SandLoad',8);if not root or not tire or not load or not m.Parent then entries[m]=nil;return end
  local v=m:Clone();v.Name='CartRender';v:SetAttribute('FollowCart',false)
  for _,x in v:GetDescendants()do if x:IsA('BasePart')then x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false elseif x:IsA('ProximityPrompt')or x:IsA('LuaSourceContainer')then x:Destroy()end end
  e.visual=v;e.pose=root.CFrame;e.last=root.Position;e.wheels={};e.wheelLocal=v.PrimaryPart.CFrame:ToObjectSpace(v.WheelTire.CFrame)
  for _,x in v:GetChildren()do if x:IsA('BasePart')and x:GetAttribute('WheelRotates')then e.wheels[x]=v.WheelTire.CFrame:ToObjectSpace(x.CFrame)end end
  for _,x in m:GetDescendants()do if x:IsA('BasePart')then e.hidden[x]=x.LocalTransparencyModifier;x.LocalTransparencyModifier=1 elseif x:IsA('BillboardGui')or x:IsA('SurfaceGui')then e.guis[x]=x.Enabled;x.Enabled=false end end
  v.Parent=folder
 end)
end
for _,v in workspace:GetDescendants()do watch(v)end;workspace.DescendantAdded:Connect(watch)
Run:BindToRenderStep('DTMFollowCart',Enum.RenderPriority.Character.Value+1,function(dt)
 for source,e in entries do
  if not source.Parent then if e.visual then e.visual:Destroy()end;entries[source]=nil
  elseif e.visual then
   local v=e.visual;local cf=source.PrimaryPart.CFrame;local ch=P.Character;local r=ch and ch:FindFirstChild('HumanoidRootPart');local h=ch and ch:FindFirstChildOfClass('Humanoid')
   if source:GetAttribute('OwnerUserId')==P.UserId and source:GetAttribute('CartEnabled')and r and h and h.Health>0 then cf=Pose.Get(r,h,v,ch)else cf=e.pose:Lerp(cf,1-math.exp(-20*dt))end
   local delta=cf.Position-e.last;e.last=cf.Position;e.pose=cf;e.angle-=Vector3.new(delta.X,0,delta.Z):Dot(cf.LookVector)/(.85*v:GetScale())
   v:PivotTo(cf)
   for wheel,rel in e.wheels do wheel.CFrame=cf*e.wheelLocal*CFrame.Angles(e.angle,0,0)*rel end
   local amount=source:GetAttribute('CartCells')or 0;local capacity=source:GetAttribute('CartCapacity')or 500;local scale=v:GetScale();local height=(.04+1.1*math.clamp(amount/capacity,0,1))*scale
   v.SandLoad.Size=Vector3.new(2.9*scale,height,2.45*scale);v.SandLoad.Transparency=amount==0 and 1 or 0;v.SandLoad.CFrame=cf*CFrame.new(v:GetAttribute('LoadBottom')*scale+Vector3.new(0,height/2,0))*v:GetAttribute('LoadRotation')
   local text=v:FindFirstChild('LoadLabel',true);if text then text.Text=string.format('ПЕСОК %d / %d\n%s',amount,capacity,source:GetAttribute('CartEnabled')and 'ТАЧКА С ВАМИ' or 'ПРИПАРКОВАНА')end
  end
 end
end)

