local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Motion=require(game.ReplicatedStorage:WaitForChild('DigMotion'))
local me=Players.LocalPlayer
local entries,lastDig={},{}
game.ReplicatedStorage:WaitForChild('SandPrototypeDig').OnClientEvent:Connect(function(_,_,uid,_,_,collapse,kind)if not collapse and kind~='conveyor'then lastDig[uid]=os.clock()end end)
local function frame(direction,hint)
 local up=direction.Unit;local right=hint:Cross(up)
 if right.Magnitude<.01 then right=Vector3.xAxis:Cross(up)end
 right=right.Unit;return CFrame.fromMatrix(Vector3.zero,right,up,right:Cross(up))
end
local function arm(ch,side,handCF,pole)
 local upper=ch:FindFirstChild(side..'UpperArm');local lower=ch:FindFirstChild(side..'LowerArm');local hand=ch:FindFirstChild(side..'Hand')
 if not upper or not lower or not hand then return end
 local shoulder=upper:FindFirstChild(side..'Shoulder');local elbow=lower:FindFirstChild(side..'Elbow');local wrist=hand:FindFirstChild(side..'Wrist')
 if not shoulder or not elbow or not wrist then return end
 local torso=shoulder.Part0;local start=(torso.CFrame*shoulder.C0).Position;local finish=(handCF*wrist.C1).Position
 local v1=elbow.C0.Position-shoulder.C1.Position;local v2=wrist.C0.Position-elbow.C1.Position
 local l1,l2=v1.Magnitude,v2.Magnitude;local delta=finish-start;local distance=math.clamp(delta.Magnitude,.05,l1+l2-.01);local dir=delta.Unit
 local along=(l1*l1-l2*l2+distance*distance)/(2*distance);local height=math.sqrt(math.max(0,l1*l1-along*along))
 local bend=pole-start;local perpendicular=bend-dir*bend:Dot(dir);if perpendicular.Magnitude<.01 then perpendicular=torso.CFrame.RightVector end
 local joint=start+dir*along+perpendicular.Unit*height
 local rot1=frame(start-joint,torso.CFrame.LookVector)*frame(-v1,Vector3.new(0,0,-1)):Inverse()
 local rot2=frame(joint-finish,torso.CFrame.LookVector)*frame(-v2,Vector3.new(0,0,-1)):Inverse()
 local upperCF=CFrame.new(start)*rot1*CFrame.new(-shoulder.C1.Position)
 local lowerCF=CFrame.new(joint)*rot2*CFrame.new(-elbow.C1.Position)
 shoulder.Transform=(torso.CFrame*shoulder.C0):ToObjectSpace(upperCF*shoulder.C1)
 elbow.Transform=(upperCF*elbow.C0):ToObjectSpace(lowerCF*elbow.C1)
 wrist.Transform=(lowerCF*wrist.C0):ToObjectSpace(handCF*wrist.C1)
end
local function reachOffset(ch,side,handCF)
 local upper=ch:FindFirstChild(side..'UpperArm');local lower=ch:FindFirstChild(side..'LowerArm');local hand=ch:FindFirstChild(side..'Hand')
 if not upper or not lower or not hand then return Vector3.zero end
 local shoulder=upper:FindFirstChild(side..'Shoulder');local elbow=lower:FindFirstChild(side..'Elbow');local wrist=hand:FindFirstChild(side..'Wrist')
 if not shoulder or not elbow or not wrist then return Vector3.zero end
 local start=(shoulder.Part0.CFrame*shoulder.C0).Position
 local finish=(handCF*wrist.C1).Position;local delta=finish-start
 local reach=(elbow.C0.Position-shoulder.C1.Position).Magnitude+(wrist.C0.Position-elbow.C1.Position).Magnitude-.04
 if delta.Magnitude>reach then return -delta.Unit*(delta.Magnitude-reach)end
 return Vector3.zero
end
local function clear(ch)
 local e=entries[ch]
 if e and e.driver and e.driver.Parent then e.driver.AutoRotate=e.autoRotate end
 for ik,enabled in e and e.disabledIK or {}do if ik.Parent then ik.Enabled=enabled end end
 for _,v in ch:GetDescendants()do if (v:IsA('Motor6D')or v:IsA('AnimationConstraint'))and(v.Name:find('Shoulder')or v.Name:find('Elbow')or v.Name:find('Wrist'))then v.Transform=CFrame.identity end end
 entries[ch]=nil
end
-- Read default controls once per rendered frame, before replacing their movement.
-- PreSimulation can run several times per frame and would feed our own Move back in.
Run:BindToRenderStep('DTMCartSteer',Enum.RenderPriority.Character.Value-1,function(dt)
 local ch=me.Character;local e=ch and entries[ch]
 local h=ch and ch:FindFirstChildOfClass('Humanoid')
 local root=ch and ch:FindFirstChild('HumanoidRootPart')
 if not e or not e.cart or not h or not root or h.Health<=0 then return end
 local input=h.MoveDirection
 if input.Magnitude>.05 then
  local look=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z).Unit
  local desired=Vector3.new(input.X,0,input.Z).Unit
  local angle=math.atan2(look:Cross(desired).Y,look:Dot(desired))
  local turn=math.clamp(angle,-math.rad(120)*math.min(dt,.1),math.rad(120)*math.min(dt,.1))
  look=CFrame.Angles(0,turn,0):VectorToWorldSpace(look)
  root.CFrame=CFrame.lookAt(root.Position,root.Position+look)
  h:Move(look*math.min(1,input.Magnitude),false)
 end
end)
Run.PreSimulation:Connect(function(dt)
 for _,player in Players:GetPlayers()do
  local ch=player.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local tool=ch and ch:FindFirstChildOfClass('Tool')
  local torso=ch and ch:FindFirstChild('UpperTorso')
  local state=player:FindFirstChild('SandPrototypeState')
  local renders=workspace:FindFirstChild('DTMCartRenders')
  local cart
  if state and state:GetAttribute('PushingCart')and renders then
   for _,v in renders:GetChildren()do if v:GetAttribute('OwnerUserId')==player.UserId then cart=v break end end
  end
  if ch and torso and h and h.Health>0 and cart then
   local e=entries[ch]
   if not e or not e.cart then if e then clear(ch)end;e={cart=true,disabledIK={}};entries[ch]=e end
   if player==me then
    if not e.driver then e.driver=h;e.autoRotate=h.AutoRotate end
    h.AutoRotate=false
   end
   for _,side in {'Left','Right'}do
    local ik=h:FindFirstChild('ManualCartGrip'..side)
    if ik then if e.disabledIK[ik]==nil then e.disabledIK[ik]=ik.Enabled end;ik.Enabled=false end
    local hand=ch:FindFirstChild(side..'Hand')
    local grip=hand and hand:FindFirstChild(side..'GripAttachment')
    local rail=cart:FindFirstChild('Handle'..side)
    local target=rail and rail:FindFirstChild('GripTarget')
    if grip and target then
     local desired=target.WorldCFrame*grip.CFrame:Inverse()
     desired+=reachOffset(ch,side,desired)
     arm(ch,side,desired,torso.CFrame:PointToWorldSpace(Vector3.new(side=='Left'and -1.2 or 1.2,-.7,.2)))
    end
   end
  elseif ch and torso and h and h.Health>0 and tool and tool:GetAttribute('SandPrototypeTool')and tool:FindFirstChild('Handle')then
   if entries[ch]and entries[ch].cart then clear(ch)end
   local hand=ch:FindFirstChild('RightHand');local grip=hand and hand:FindFirstChild('RightGrip')
   if grip then
    local e=entries[ch]or{blend=0,clock=0};entries[ch]=e
    local active=player==me and(tool:GetAttribute('DigActiveUntil')or 0)>os.clock()or player~=me and os.clock()-(lastDig[player.UserId]or-math.huge)<.35
    if active then e.clock+=dt else e.clock=0 end
    e.blend+=((active and 1 or 0)-e.blend)*(1-math.exp(-16*dt))
    local phase=(e.clock%.56)/.56;local scoop=math.sin(phase*math.pi*2);local weight=e.blend;local two=tool:GetAttribute('TwoHanded')
    local variant=math.floor(e.clock/.56)%3
    local sinceImpact=os.clock()-(lastDig[player.UserId]or -100)
    local recoil=sinceImpact<.15 and math.exp(-sinceImpact*27)or 0
    tool:SetAttribute('DigStrokeVariant',variant+1)
    local native=Motion.Frames[math.clamp(math.floor(phase*(#Motion.Frames-1))+1,1,#Motion.Frames)].RightUpperArm
    local desired=torso.CFrame*CFrame.new((two and .15 or .65)+weight*.035*(variant-1)*scoop,(two and -.45 or .1)+weight*(-.12-.2*(scoop+1)/2)+recoil*.05,-.85-weight*.2*(1-scoop)+recoil*.075)*CFrame.Angles(weight*(math.rad(17+variant*3)+math.rad(22)*scoop+(native and native[1]or 0)*.05)+math.rad(2)*recoil,weight*math.sin(phase*math.pi)^2*math.rad((variant-1)*4),weight*scoop*math.rad((variant-1)*2))
    local leftHand=ch:FindFirstChild('LeftHand');local leftTarget=tool.Handle:FindFirstChild('LeftGrip')
    -- Move the rigid tool into reach of both arms instead of stretching either wrist.
    for _=1,6 do
     desired+=reachOffset(ch,'Right',desired*grip.C1*grip.C0:Inverse())
     if two and leftHand and leftTarget then desired+=reachOffset(ch,'Left',desired*leftTarget.CFrame*leftHand.LeftGripAttachment.CFrame:Inverse())end
    end
    arm(ch,'Right',desired*grip.C1*grip.C0:Inverse(),torso.CFrame:PointToWorldSpace(Vector3.new(1.2,-.7,.3)))
    if two and leftHand and leftTarget then
     arm(ch,'Left',desired*leftTarget.CFrame*leftHand.LeftGripAttachment.CFrame:Inverse(),torso.CFrame:PointToWorldSpace(Vector3.new(-1.2,-.7,.1)))
    end
   end
  elseif ch and entries[ch]then clear(ch)end
 end
 for ch in entries do if not ch.Parent then entries[ch]=nil end end
end)
