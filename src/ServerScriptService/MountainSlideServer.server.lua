local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local R=game.ReplicatedStorage
local Rules=require(R:WaitForChild('MountainSlideRules'))
local Boards=require(R:WaitForChild('SandboardAppearance'))
local remote=Instance.new('RemoteEvent');remote.Name='MountainSlideRequest';remote.Parent=R
local active,last={},{}
local function boardFrame(e,sample)
 local n=sample and sample.Hit.Normal or Vector3.yAxis
 local forward=e.dir-n*e.dir:Dot(n);if forward.Magnitude<.1 then forward=e.dir end
 local position=sample and sample.Hit.Position+n*.17 or e.root.Position-Vector3.new(0,2.2,0)
 return CFrame.lookAt(position,position+forward.Unit,n)*CFrame.Angles(0,0,-(e.lean or 0)*.045)
end
local function mountBoard(e,sample,style)
 if e.board then e.board:Destroy()end
 local board=Boards.Build(style);board.Name='Sandboard';e.board=board;e.style=style
 local cf=boardFrame(e,sample);local root=board.PrimaryPart
 for _,p in board:GetDescendants()do if p:IsA('BasePart')then p.CFrame=cf*p.CFrame end end
 for _,p in board:GetDescendants()do if p:IsA('BasePart')then
  if p~=root then local w=Instance.new('WeldConstraint');w.Part0=root;w.Part1=p;w.Parent=p end
  p.Anchored=false
 end end
 local weld=Instance.new('Weld');weld.Name='BoardMount';weld.Part0=e.root;weld.Part1=root;weld.C0=e.root.CFrame:ToObjectSpace(cf);weld.Parent=root;e.boardWeld=weld
 local a=Instance.new('Attachment');a.Name='SandWake';a.Position=Vector3.new(0,.02,2);a.Parent=root
 local dust=Instance.new('ParticleEmitter');dust.Name='SandTrail';dust.Texture='rbxasset://textures/particles/smoke_main.dds';dust.Color=ColorSequence.new(Color3.fromRGB(219,195,150));dust.Rate=24;dust.Lifetime=NumberRange.new(.2,.45);dust.Speed=NumberRange.new(2,5);dust.SpreadAngle=Vector2.new(28,12);dust.EmissionDirection=Enum.NormalId.Back;dust.Acceleration=Vector3.new(0,-2,0);dust.Drag=3;dust.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(1,1.8)});dust.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.63),NumberSequenceKeypoint.new(1,1)});dust.LightInfluence=1;dust.Parent=a;e.dust=dust
 for _,x in {-.72,.72}do
  local a0=Instance.new('Attachment');a0.Position=Vector3.new(x-.035,-.15,1.8);a0.Parent=root
  local a1=Instance.new('Attachment');a1.Position=Vector3.new(x+.035,-.15,1.8);a1.Parent=root
  local trail=Instance.new('Trail');trail.Name='SandFurrow';trail.Attachment0=a0;trail.Attachment1=a1;trail.Color=ColorSequence.new(Color3.fromRGB(155,131,96));trail.Lifetime=1.1;trail.MinLength=.2;trail.FaceCamera=false;trail.LightInfluence=1;trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.6),NumberSequenceKeypoint.new(1,1)});trail.WidthScale=NumberSequence.new(1,0);trail.Parent=root
 end
 board.Parent=e.ch
end
local function stop(p,reason)
 local e=active[p];if not e then return end;active[p]=nil
 if e.track then e.track:Stop(.18)end
 for _,v in {e.drive,e.align,e.attachment,e.board}do if v then v:Destroy()end end
 if e.h.Parent then e.h.WalkSpeed=e.walk;e.h.AutoRotate=e.rotate;e.h.HipHeight=e.hip;if e.h.Health>0 then e.h:ChangeState(Enum.HumanoidStateType.GettingUp)end end
 if e.ch.Parent then e.ch:SetAttribute('MountainSliding',false);e.ch:SetAttribute('SlideLean',0)end
 if e.root.Parent then e.root.AssemblyLinearVelocity=Vector3.new(e.root.AssemblyLinearVelocity.X*.3,e.root.AssemblyLinearVelocity.Y,e.root.AssemblyLinearVelocity.Z*.3);pcall(function()e.root:SetNetworkOwnershipAuto()end)end
 if e.tool and e.tool.Parent==p:FindFirstChildOfClass('Backpack')and e.h.Parent and e.h.Health>0 then e.h:EquipTool(e.tool)end
 if reason then remote:FireClient(p,reason)end
end
remote.OnServerEvent:Connect(function(p,action,value)
 if action=='stop'then stop(p);return end
 if action=='steer'then
  local e=active[p];if e and typeof(value)=='Vector3'and value.X==value.X and value.Z==value.Z and math.abs(value.X)<=1 and math.abs(value.Z)<=1 then e.steer=Vector3.new(value.X,0,value.Z)end
  return
 end
 if action~='start'then return end
 if active[p]then stop(p);return end
 if os.clock()-(last[p]or-100)<.5 then return end;last[p]=os.clock()
 local ch=p.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local root=ch and ch:FindFirstChild('HumanoidRootPart')
 if not h or not root or h.Health<=0 or h.Sit then return end
 local sample=Rules.Sample(p,root,8)
 if not sample then remote:FireClient(p,'Для спуска поднимитесь выше на гору');return end
 local e={ch=ch,h=h,root=root,walk=h.WalkSpeed,hip=h.HipHeight,rotate=h.AutoRotate,start=os.clock(),dir=sample.Direction,speed=18,steer=Vector3.zero,m=sample.Mountain,air=0,lean=0,tool=ch:FindFirstChildOfClass('Tool')}
 active[p]=e;h:UnequipTools();ch:SetAttribute('MountainSliding',true);h.WalkSpeed=0;h.AutoRotate=false;h.HipHeight=1.35
 pcall(function()root:SetNetworkOwner(nil)end);h:ChangeState(Enum.HumanoidStateType.Physics)
 local a=Instance.new('Attachment');a.Name='SlideOrientation';a.Parent=root;e.attachment=a
 local align=Instance.new('AlignOrientation');align.Name='SlideFacing';align.Mode=Enum.OrientationAlignmentMode.OneAttachment;align.Attachment0=a;align.MaxTorque=100000;align.Responsiveness=15;align.CFrame=CFrame.lookAt(Vector3.zero,e.dir);align.Parent=root;e.align=align
 local drive=Instance.new('LinearVelocity');drive.Name='SurfDrive';drive.Attachment0=a;drive.RelativeTo=Enum.ActuatorRelativeTo.World;drive.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane;drive.PrimaryTangentAxis=Vector3.xAxis;drive.SecondaryTangentAxis=Vector3.zAxis;drive.ForceLimitsEnabled=true;drive.MaxForce=math.max(25000,root.AssemblyMass*1500);drive.PlaneVelocity=Vector2.new(e.dir.X*e.speed,e.dir.Z*e.speed);drive.Parent=root;e.drive=drive
 local state=p:FindFirstChild('SandPrototypeState');mountBoard(e,sample,state and state:GetAttribute('BoardStyle')or 'dune')
 local animator=h:FindFirstChildOfClass('Animator')
 if animator then
  local animation=Instance.new('Animation');animation.AnimationId='rbxassetid://83410528398456'
  local ok,track=pcall(function()return animator:LoadAnimation(animation)end);animation:Destroy()
  if ok then track.Priority=Enum.AnimationPriority.Action;track.Looped=true;track:Play(.2);e.track=track end
 end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end;local step=math.min(elapsed,.1);elapsed=0
 for p,e in active do
  if p.Character~=e.ch or not e.root.Parent or e.h.Health<=0 or os.clock()-e.start>12 then stop(p);continue end
  if e.h:GetState()~=Enum.HumanoidStateType.Physics then e.h:ChangeState(Enum.HumanoidStateType.Physics)end
  local sample=Rules.Sample(p,e.root,0)
  if not sample then
   local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={e.ch};rp.RespectCanCollide=true
   local floor=workspace:Raycast(e.root.Position,Vector3.new(0,-3.5,0),rp)
   if floor and floor.Normal.Y>.94 then stop(p);continue end
   e.air+=step;if e.air>.65 then stop(p);continue end
  else
   e.air=0
   if sample.Mountain~=e.m or sample.Hit.Position.Y<=sample.Origin.Y+2 then stop(p);continue end
   local down=sample.Direction;local side=e.steer-down*e.steer:Dot(down)
   local desired=(down+side*.5).Unit;e.dir=e.dir:Lerp(desired,math.min(1,step*5)).Unit
   local right=e.dir:Cross(Vector3.yAxis);local lean=math.clamp(e.steer:Dot(right),-1,1)
   e.lean+=(lean-e.lean)*math.min(1,step*8);e.ch:SetAttribute('SlideLean',e.lean)
  end
  if e.ch:FindFirstChildOfClass('Tool')then e.h:UnequipTools()end
  e.speed=math.min(48,e.speed+step*12)
  e.drive.PlaneVelocity=Vector2.new(e.dir.X*e.speed,e.dir.Z*e.speed)
  e.align.CFrame=CFrame.lookAt(Vector3.zero,e.dir)
  local state=p:FindFirstChild('SandPrototypeState');local style=state and state:GetAttribute('BoardStyle')or 'dune'
  if style~=e.style then mountBoard(e,sample,style)end
  e.boardWeld.C0=e.root.CFrame:ToObjectSpace(boardFrame(e,sample));e.dust.Enabled=sample~=nil
 end
end)
Players.PlayerRemoving:Connect(function(p)stop(p);last[p]=nil end)
