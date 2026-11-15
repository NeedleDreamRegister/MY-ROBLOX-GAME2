local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local R=game.ReplicatedStorage
local me=Players.LocalPlayer
local kick=0
local function emitter(tool)
 local h=tool:FindFirstChild('Handle');if not h then return end
 local a=h:FindFirstChild('BladeSand')
 if not a then
  a=Instance.new('Attachment');a.Name='BladeSand';a.Position=tool:GetAttribute('TwoHanded')and Vector3.new(0,-2.28,.65)or Vector3.new(0,-.3,-1);a.Parent=h
  local grain=Instance.new('ParticleEmitter');grain.Name='FallingGrains';grain.Texture='rbxasset://textures/particles/smoke_main.dds';grain.Enabled=false;grain.Rate=0;grain.Lifetime=NumberRange.new(.28,.48);grain.Speed=NumberRange.new(.6,2);grain.SpreadAngle=Vector2.new(35,35);grain.EmissionDirection=Enum.NormalId.Top;grain.Acceleration=Vector3.new(0,-23,0);grain.Drag=1;grain.LightInfluence=1;grain.Rotation=NumberRange.new(0,180);grain.RotSpeed=NumberRange.new(-100,100)
  grain.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(1,.035)});grain.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.75,.2),NumberSequenceKeypoint.new(1,1)});grain.Parent=a
 end
 return a.FallingGrains
end
R:WaitForChild('SandPrototypeDig').OnClientEvent:Connect(function(position,color,uid,_,_,collapse,kind)
 if collapse or kind=='conveyor'or typeof(position)~='Vector3'then return end
 local camera=workspace.CurrentCamera;if not camera or(camera.CFrame.Position-position).Magnitude>65 then return end
 local p=Players:GetPlayerByUserId(uid);local ch=p and p.Character;local tool=ch and ch:FindFirstChildOfClass('Tool')
 if tool and tool:GetAttribute('SandPrototypeTool')then
  local grain=emitter(tool);if grain then grain.Color=ColorSequence.new(color);grain:Emit(9);task.delay(.09,function()if grain.Parent then grain:Emit(4)end end)end
 end
 if p==me then kick=math.min(.4,kick+.24)end
end)
Run:BindToRenderStep('DTMDigRecoil',Enum.RenderPriority.Camera.Value+1,function(dt)
 kick*=math.exp(-22*dt)
 local camera=workspace.CurrentCamera
 if camera and kick>.001 and not(me.Character and me.Character:GetAttribute('MountainSliding'))then camera.CFrame*=CFrame.Angles(math.rad(kick),0,0)end
end)
