local P=game.Players.LocalPlayer
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local remote=game.ReplicatedStorage:WaitForChild('MountainSlideRequest')
local Rules=require(game.ReplicatedStorage:WaitForChild('MountainSlideRules'))
local gui=Instance.new('ScreenGui');gui.Name='MountainSlideUI';gui.ResetOnSpawn=false;gui.DisplayOrder=20;gui.Parent=P:WaitForChild('PlayerGui')
local b=Instance.new('TextButton');b.Name='SlideButton';b.BackgroundColor3=Color3.fromRGB(30,83,91);b.TextColor3=Color3.fromRGB(242,221,176);b.Font=Enum.Font.GothamBold;b.TextSize=14;b.TextWrapped=true;b.Visible=false;b.Parent=gui;local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,14);corner.Parent=b;local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(149,191,190);stroke.Transparency=.3;stroke.Parent=b
local function sliding()return P.Character and P.Character:GetAttribute('MountainSliding')==true end
local function blocked()local u=P.PlayerGui:FindFirstChild('UpgradeUI');return Input:GetFocusedTextBox()~=nil or(u and u:FindFirstChild('Modal')and u.Modal.Visible)end
local function toggle()if blocked()then return end;remote:FireServer(sliding()and 'stop'or 'start')end
b.Activated:Connect(toggle)
Input.InputBegan:Connect(function(i,processed)
 if processed then return end
 if i.KeyCode==Enum.KeyCode.C or i.KeyCode==Enum.KeyCode.ButtonB then toggle()
 elseif i.KeyCode==Enum.KeyCode.Space and sliding()then remote:FireServer('stop')end
end)
Input.JumpRequest:Connect(function()if sliding()then remote:FireServer('stop')end end)
Input.WindowFocusReleased:Connect(function()if sliding()then remote:FireServer('stop')end end)
remote.OnClientEvent:Connect(function(text)local f=P.PlayerGui:FindFirstChild('SandPrototypeFeedback');local hint=f and f:FindFirstChild('ActionHint');if hint then hint:Fire(text)end end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.12 then return end;elapsed=0
 local ch=P.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local root=ch and ch:FindFirstChild('HumanoidRootPart')
 local active=sliding();local touch=Input.PreferredInput==Enum.PreferredInput.Touch
 local vp=workspace.CurrentCamera.ViewportSize;local short=touch and vp.Y<500;local slideWidth=short and(vp.X<544 and 60 or vp.X<600 and 90 or 102)or 102
 b.Visible=not blocked()and h~=nil and h.Health>0 and root~=nil and(active or Rules.Sample(P,root,8)~=nil)
 b.AnchorPoint=Vector2.new(touch and 1 or .5,1);b.Position=touch and UDim2.new(1,-158,1,-150)or UDim2.new(.5,0,1,-86);b.Size=touch and UDim2.fromOffset(slideWidth,66)or UDim2.fromOffset(230,38)
 b.Text=active and(touch and 'СТОП'or 'C · ОСТАНОВИТЬСЯ')or(touch and 'СЪЕХАТЬ'or 'C · СЁРФИНГ С ГОРЫ')
 if active and h then remote:FireServer('steer',h.MoveDirection)end
end)

-- Keep a low, readable slide silhouette while the generated animation supplies motion.
local poseBlend={}
local poseAngles={
 Root={-8,90,0},Waist={5,-12,0},
 LeftHip={24,0,-20},RightHip={38,0,20},
 LeftKnee={-44,0,0},RightKnee={-64,0,0},
 LeftAnkle={20,0,0},RightAnkle={25,0,0},
 LeftShoulder={25,0,-48},RightShoulder={15,0,48},
 LeftElbow={14,0,0},RightElbow={18,0,0},
}
local function limbFrame(direction,hint)
 local up=direction.Unit;local right=hint:Cross(up);if right.Magnitude<.01 then right=Vector3.xAxis:Cross(up)end
 right=right.Unit;return CFrame.fromMatrix(Vector3.zero,right,up,right:Cross(up))
end
local function plantFoot(ch,side,footCF,torsoCF)
 local upper=ch:FindFirstChild(side..'UpperLeg');local lower=ch:FindFirstChild(side..'LowerLeg');local foot=ch:FindFirstChild(side..'Foot')
 if not upper or not lower or not foot then return end
 local hip=upper:FindFirstChild(side..'Hip');local knee=lower:FindFirstChild(side..'Knee');local ankle=foot:FindFirstChild(side..'Ankle')
 if not hip or not knee or not ankle then return end
 local start=(torsoCF*hip.C0).Position;local finish=(footCF*ankle.C1).Position
 local v1=knee.C0.Position-hip.C1.Position;local v2=ankle.C0.Position-knee.C1.Position
 local l1,l2=v1.Magnitude,v2.Magnitude;local delta=finish-start;if delta.Magnitude<.01 then return end
 local distance=math.clamp(delta.Magnitude,.05,l1+l2-.015);local dir=delta.Unit
 if distance<delta.Magnitude then local nextFinish=start+dir*distance;footCF+=nextFinish-finish;finish=nextFinish end
 local along=(l1*l1-l2*l2+distance*distance)/(2*distance);local height=math.sqrt(math.max(0,l1*l1-along*along))
 local pole=torsoCF:PointToWorldSpace(Vector3.new(side=='Left'and -.5 or .5,-.2,-2));local bend=pole-start;local perpendicular=bend-dir*bend:Dot(dir)
 if perpendicular.Magnitude<.01 then perpendicular=torsoCF.LookVector end
 local joint=start+dir*along+perpendicular.Unit*height
 local rot1=limbFrame(start-joint,torsoCF.LookVector)*limbFrame(-v1,Vector3.new(0,0,-1)):Inverse()
 local rot2=limbFrame(joint-finish,torsoCF.LookVector)*limbFrame(-v2,Vector3.new(0,0,-1)):Inverse()
 local upperCF=CFrame.new(start)*rot1*CFrame.new(-hip.C1.Position)
 local lowerCF=CFrame.new(joint)*rot2*CFrame.new(-knee.C1.Position)
 hip.Transform=(torsoCF*hip.C0):ToObjectSpace(upperCF*hip.C1)
 knee.Transform=(upperCF*knee.C0):ToObjectSpace(lowerCF*knee.C1)
 ankle.Transform=(lowerCF*ankle.C0):ToObjectSpace(footCF*ankle.C1)
end
Run.PreSimulation:Connect(function(dt)
 for _,player in game.Players:GetPlayers()do
  local ch=player.Character
  if ch and ch:GetAttribute('MountainSliding')then
   local blend=math.min(1,(poseBlend[ch]or 0)+dt*7);poseBlend[ch]=blend
   for _,joint in ch:GetDescendants()do
    local a=poseAngles[joint.Name]
    if a and (joint:IsA('Motor6D')or joint:IsA('AnimationConstraint'))then
     local pose=CFrame.Angles(math.rad(a[1]),math.rad(a[2]),math.rad(a[3]))
     if joint.Name=='Root'then local lean=ch:GetAttribute('SlideLean')or 0;pose=CFrame.new(0,-.65,0)*CFrame.Angles(math.rad(-8)+lean*.12,math.pi/2,lean*.1)end
     joint.Transform=joint.Transform:Lerp(pose,blend*.96)
    end
   end
   local board=ch:FindFirstChild('Sandboard');local lower=ch:FindFirstChild('LowerTorso');local rootJoint=lower and lower:FindFirstChild('Root')
   if board and board.PrimaryPart and rootJoint then
    local lowerCF=rootJoint.Part0.CFrame*rootJoint.C0*rootJoint.Transform*rootJoint.C1:Inverse()
    for _,side in {'Left','Right'}do
     local foot=ch:FindFirstChild(side..'Foot')
     if foot then local z=side=='Left'and .85 or -.85;local cf=board.PrimaryPart.CFrame*CFrame.new(0,.11+foot.Size.Y/2,z)*CFrame.Angles(0,math.pi/2,0);plantFoot(ch,side,cf,lowerCF)end
    end
   end
  elseif ch and poseBlend[ch]then
   poseBlend[ch]=nil
   for _,joint in ch:GetDescendants()do if poseAngles[joint.Name]and (joint:IsA('Motor6D')or joint:IsA('AnimationConstraint'))then joint.Transform=CFrame.identity end end
  end
 end
 for ch in poseBlend do if not ch.Parent then poseBlend[ch]=nil end end
end)

local Boards=require(game.ReplicatedStorage:WaitForChild('SandboardAppearance'))
local styleButton=Instance.new('TextButton');styleButton.Name='BoardStyle';styleButton.BackgroundColor3=Color3.fromRGB(28,48,55);styleButton.TextColor3=Color3.fromRGB(230,210,164);styleButton.Font=Enum.Font.GothamBold;styleButton.TextSize=12;styleButton.Visible=false;styleButton.Parent=gui;local sc=Instance.new('UICorner');sc.CornerRadius=UDim.new(0,10);sc.Parent=styleButton
local lastStyle=-100
styleButton.Activated:Connect(function()
 if sliding()or blocked()or os.clock()-lastStyle<.4 then return end;lastStyle=os.clock()
 local state=P:FindFirstChild('SandPrototypeState');local current=state and state:GetAttribute('BoardStyle')or 'dune';local index=table.find(Boards.Order,current)or 1
 game.ReplicatedStorage.DTMUpgradeRemote:FireServer({OwnerUserId=P.UserId,Action='boardStyle',Item=Boards.Order[index%#Boards.Order+1]})
end)
Run.Heartbeat:Connect(function()
 local touch=Input.PreferredInput==Enum.PreferredInput.Touch
 styleButton.Visible=b.Visible and not sliding()
 local vp=workspace.CurrentCamera.ViewportSize;local short=touch and vp.Y<500
 local inset=vp.X<544 and 224 or vp.X<600 and 254 or 272
 local styleWidth=math.clamp(vp.X-inset-(12+math.clamp(vp.X*.44,222,260))-6,44,144)
 styleButton.AnchorPoint=Vector2.new(touch and 1 or .5,1);styleButton.Position=short and UDim2.new(1,-inset,1,-161)or touch and UDim2.new(1,-24,1,-230)or UDim2.new(.5,0,1,-132);styleButton.Size=short and UDim2.fromOffset(styleWidth,44)or touch and UDim2.fromOffset(236,44)or UDim2.fromOffset(230,32)
 local state=P:FindFirstChild('SandPrototypeState');local id=state and state:GetAttribute('BoardStyle')or 'dune';local style=Boards.Styles[id]or Boards.Styles.dune
 styleButton.Text=(short and styleWidth<110 and ''or 'ДОСКА: ')..style.Name..'  ↻';styleButton.TextSize=short and styleWidth<80 and 9 or 12;styleButton.TextColor3=style.Accent
end)
local lensCamera,lensBase,lensValue
Run:BindToRenderStep('DTMSurfLens',Enum.RenderPriority.Camera.Value+2,function(dt)
 local camera=workspace.CurrentCamera;if not camera then return end
 if sliding()then
  if lensCamera~=camera or not lensBase then lensCamera=camera;lensBase=camera.FieldOfView;lensValue=lensBase end
  local r=P.Character and P.Character:FindFirstChild('HumanoidRootPart');local speed=r and Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude or 0
  local target=lensBase+6*math.clamp((speed-12)/36,0,1);lensValue+=(target-lensValue)*(1-math.exp(-5*dt));camera.FieldOfView=lensValue
 elseif lensBase and lensCamera==camera then
  lensValue+=(lensBase-lensValue)*(1-math.exp(-8*dt));camera.FieldOfView=lensValue
  if math.abs(lensValue-lensBase)<.02 then camera.FieldOfView=lensBase;lensBase=nil;lensCamera=nil end
 elseif lensBase then lensBase=nil;lensCamera=nil end
end)
