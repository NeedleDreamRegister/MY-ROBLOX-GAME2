local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Motion=require(game.ReplicatedStorage:WaitForChild('DigMotion'))
local me=Players.LocalPlayer
local entries,lastDig,lastDigPosition,lastStroke={},{},{},{}
game.ReplicatedStorage:WaitForChild('SandPrototypeDig').OnClientEvent:Connect(function(position,_,uid,_,_,collapse,kind)if not collapse and kind~='conveyor'then lastDig[uid]=os.clock();lastDigPosition[uid]=position;lastStroke[uid]=(lastStroke[uid]or 0)+1 end end)
local function directionBasis(up,right)
 up=up.Unit;right=right-up*right:Dot(up)
 if right.Magnitude<.01 then right=up:Cross(Vector3.yAxis)end
 if right.Magnitude<.01 then right=Vector3.xAxis end
 right=right.Unit;return CFrame.fromMatrix(Vector3.zero,right,up,right:Cross(up))
end
local function equippedGrip(hand,handle)
 if not hand then return nil end
 for _,joint in hand:GetChildren()do
  if joint.Name=='RightGrip'and(joint:IsA('JointInstance')or joint:IsA('AnimationConstraint'))
   and joint.Part0==hand and joint.Part1==handle then return joint end
 end
end
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
 if e and e.grip and e.grip.Parent then e.grip.C1=e.baseGrip end
 if e and e.leftTarget and e.leftTarget.Parent then e.leftTarget.CFrame=e.baseLeft end
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
  local cart
  local renders=workspace:FindFirstChild('DTMCartRenders')
  if renders then for _,v in renders:GetChildren()do if v:GetAttribute('OwnerUserId')==me.UserId then cart=v break end end end
  local blocked=cart and cart:GetAttribute('MotionBlocked')==true
  -- A blocked cart also limits the driver's turn, keeping reverse usable.
  local facing=blocked and cart.PrimaryPart.CFrame.LookVector or root.CFrame.LookVector
  local look=Vector3.new(facing.X,0,facing.Z).Unit
  local desired=Vector3.new(input.X,0,input.Z).Unit
  local reverse=look:Dot(desired)<-.5
  if reverse then desired=-desired end
  local angle=math.atan2(look:Cross(desired).Y,look:Dot(desired))
  local turn=math.clamp(angle,-math.rad(120)*math.min(dt,.1),math.rad(120)*math.min(dt,.1))
  look=CFrame.Angles(0,turn,0):VectorToWorldSpace(look)
  root.CFrame=CFrame.lookAt(root.Position,root.Position+look)
  if blocked and not reverse then
   h:Move(Vector3.zero,false)
   local velocity=root.AssemblyLinearVelocity
   root.AssemblyLinearVelocity=Vector3.new(0,velocity.Y,0)
  else
   h:Move(look*math.min(1,input.Magnitude)*(reverse and -1 or 1),false)
  end
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
   local hand=ch:FindFirstChild('RightHand');local grip=equippedGrip(hand,tool.Handle)
   if grip then
    local e=entries[ch]
    if not e or e.tool~=tool then
     if e then clear(ch)end
     e={blend=0,clock=0,tool=tool,grip=grip,baseGrip=grip.C1,leftTarget=tool.Handle:FindFirstChild('LeftGrip')}
     e.baseLeft=e.leftTarget and e.leftTarget.CFrame;entries[ch]=e
    end
    grip.C1=e.baseGrip
    if e.leftTarget then e.leftTarget.CFrame=e.baseLeft end
    local active=player==me and(tool:GetAttribute('DigActiveUntil')or 0)>os.clock()or player~=me and os.clock()-(lastDig[player.UserId]or-math.huge)<.35
    if active then e.clock+=dt else e.clock=0 end
    e.blend+=((active and 1 or 0)-e.blend)*(1-math.exp(-16*dt))
    local id=tool:GetAttribute('UpgradeToolId');local physical=id=='shovel'or id=='turbo'
    local stamp=player==me and(tool:GetAttribute('DigStrokeAt')or -100)or(lastDig[player.UserId]or -100)
    local phase=physical and math.clamp((os.clock()-stamp)/.18,0,1)or(e.clock%.56)/.56;local scoop=math.sin(phase*math.pi*2);local weight=e.blend;local two=tool:GetAttribute('TwoHanded')
    local variant=physical and(((player==me and tool:GetAttribute('DigStrokeIndex')or lastStroke[player.UserId])or 1)-1)%3 or math.floor(e.clock/.56)%3
    local sinceImpact=os.clock()-(lastDig[player.UserId]or -100)
    local recoil=sinceImpact<.15 and math.exp(-sinceImpact*27)or 0
    tool:SetAttribute('DigStrokeVariant',variant+1)
    local native=Motion.Frames[math.clamp(math.floor(phase*(#Motion.Frames-1))+1,1,#Motion.Frames)].RightUpperArm
    local desired=torso.CFrame*CFrame.new((two and .15 or .65)+weight*.035*(variant-1)*scoop,(two and -.45 or .1)+weight*(-.12-.2*(scoop+1)/2)+recoil*.05,-.85-weight*.2*(1-scoop)+recoil*.075)*CFrame.Angles(weight*(math.rad(17+variant*3)+math.rad(22)*scoop+(native and native[1]or 0)*.05)+math.rad(2)*recoil,weight*math.sin(phase*math.pi)^2*math.rad((variant-1)*4),weight*scoop*math.rad((variant-1)*2))
    local aim=player==me and tool:GetAttribute('DigAimPosition')or lastDigPosition[player.UserId]
    local edge=tool:FindFirstChild('CuttingEdge')
    if physical and edge then
     local pivot=torso.CFrame:PointToWorldSpace(Vector3.new(.15,-.1,-.5))
     local tip=tool.Handle.CFrame:PointToObjectSpace(edge.Position)
     local function pose(point)
      local rotation=CFrame.fromAxisAngle(torso.CFrame.RightVector,math.rad(-15))*directionBasis(point-pivot,torso.CFrame.RightVector)*directionBasis(tip,Vector3.xAxis):Inverse()
      return CFrame.new(point-rotation:VectorToWorldSpace(tip))*rotation
     end
     desired=pose(torso.CFrame:PointToWorldSpace(Vector3.new(.15,-2.1,-1.8)))
     if typeof(aim)=='Vector3'and(aim-pivot).Magnitude>.1 and(aim-pivot).Magnitude<8 then
      if e.contactStamp~=stamp or(pivot-e.contactPivot).Magnitude>.2
       or torso.CFrame.RightVector:Dot(e.contactRight)<.995 then
       -- Reuse the shaft angle while stationary; refresh after moving/turning
       -- so walking into a pit does not leave the contact pose out of reach.
       local base=directionBasis(aim-pivot,torso.CFrame.RightVector)*directionBasis(tip,Vector3.xAxis):Inverse()
       local bestScore=math.huge
       for slide=0,2.5,.5 do
       for angle=-90,90,15 do
        local rotation=CFrame.fromAxisAngle(torso.CFrame.RightVector,math.rad(angle))*base
        local candidate=CFrame.new(aim-rotation:VectorToWorldSpace(tip))*rotation
        local right=reachOffset(ch,'Right',candidate*e.baseGrip*CFrame.new(0,-slide,0)*grip.C0:Inverse()).Magnitude
        local left=reachOffset(ch,'Left',candidate*e.baseLeft*CFrame.new(0,-slide,0)*ch.LeftHand.LeftGripAttachment.CFrame:Inverse()).Magnitude
        local score=right+left+math.abs(angle+15)*.0001+slide*.003
        if score<bestScore then bestScore=score;e.contactRotation=rotation;e.contactSlide=slide end
       end
       end
       e.contactStamp=stamp;e.contactPivot=pivot;e.contactRight=torso.CFrame.RightVector
      end
      local contact=CFrame.new(aim-e.contactRotation:VectorToWorldSpace(tip))*e.contactRotation
      local contactWeight=math.min(1,math.sin(phase*math.pi)^2*1.5)
      desired=desired:Lerp(contact,contactWeight)
      -- Choke up on the real shaft for close walls/ceilings instead of
      -- stretching wrists or moving the blade away from the selected sand.
      local shift=CFrame.new(0,-e.contactSlide*contactWeight,0)
      grip.C1=e.baseGrip*shift;e.leftTarget.CFrame=e.baseLeft*shift
     end
    end
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
