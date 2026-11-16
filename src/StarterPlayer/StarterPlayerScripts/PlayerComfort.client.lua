local Players=game:GetService('Players');local Input=game:GetService('UserInputService')
local CAS=game:GetService('ContextActionService');local Run=game:GetService('RunService')
local P=Players.LocalPlayer;local remote=game.ReplicatedStorage:WaitForChild('DTMSprint')
pcall(function()game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)end)
local gui=Instance.new('ScreenGui');gui.Name='DTMPlayerList';gui.ResetOnSpawn=false;gui.DisplayOrder=80;gui.Parent=P.PlayerGui
local panel=Instance.new('Frame');panel.Name='Players';panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-12,0,12);panel.Size=UDim2.fromOffset(340,110);panel.BackgroundColor3=Color3.fromRGB(22,42,46);panel.BackgroundTransparency=.08;panel.BorderSizePixel=0;panel.Visible=false;panel.Parent=gui
panel.BackgroundTransparency=.02
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=panel
local listScale=Instance.new('UIScale');listScale.Parent=panel
local function label(parent,text,x,y,w,size)
 local l=Instance.new('TextLabel');l.BackgroundTransparency=1;l.Text=text;l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(w,24);l.Font=Enum.Font.GothamMedium;l.TextSize=size or 12;l.TextColor3=Color3.fromRGB(233,239,224);l.TextXAlignment=Enum.TextXAlignment.Left;l.TextTruncate=Enum.TextTruncate.AtEnd;l.Parent=parent;return l
end
label(panel,'ИГРОКИ · удерживайте Tab',12,4,310,11)
label(panel,'Игрок',12,28,128,10);label(panel,'Монеты',146,28,72,10);label(panel,'Ур. инстр.',224,28,64,10);label(panel,'Песок',291,28,44,10)
local list=Instance.new('ScrollingFrame');list.Name='Rows';list.BackgroundTransparency=1;list.BorderSizePixel=0;list.Position=UDim2.fromOffset(0,54);list.Size=UDim2.new(1,0,1,-60);list.ScrollBarThickness=3;list.Parent=panel
local function short(n)if n>=1000000 then return string.format('%.1fM',n/1000000)elseif n>=10000 then return string.format('%.1fK',n/1000)end;return tostring(math.floor(n))end
local function refresh()
 listScale.Scale=math.min(1,(workspace.CurrentCamera.ViewportSize.X-20)/340)
 for _,v in list:GetChildren()do if v:IsA('GuiObject')then v:Destroy()end end
 local all=Players:GetPlayers();table.sort(all,function(a,b)local sa=a:FindFirstChild('SandPrototypeState');local sb=b:FindFirstChild('SandPrototypeState');local ca=sa and sa:GetAttribute('Coins')or 0;local cb=sb and sb:GetAttribute('Coins')or 0;if ca==cb then return a.UserId<b.UserId end;return ca>cb end)
 for i,p in all do
  local s=p:FindFirstChild('SandPrototypeState');local a=s and s:GetAttributes()or {};local y=(i-1)*26
  local name=label(list,p.DisplayName,12,y,128);name.TextColor3=p==P and Color3.fromRGB(110,225,201)or name.TextColor3
  label(list,s and short(a.Coins or 0)or '…',146,y,72)
  label(list,s and tostring(a.ToolLevel or 1)or '…',239,y,40)
  label(list,s and short((a.CarriedCells or 0)+(a.CartCells or 0))or '…',291,y,44)
 end
 panel.Size=UDim2.fromOffset(340,60+math.min(7,#all)*26);list.CanvasSize=UDim2.fromOffset(0,#all*26)
end
CAS:BindActionAtPriority('DTMHoldPlayerList',function(_,state)
 if state==Enum.UserInputState.Begin then if Input:GetFocusedTextBox()then return Enum.ContextActionResult.Pass end;refresh();panel.Visible=true
 elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then panel.Visible=false end
 return Enum.ContextActionResult.Sink
end,false,3000,Enum.KeyCode.Tab)
local keys={};local sprint=false
local function release()table.clear(keys);if sprint then sprint=false;remote:FireServer(false)end;panel.Visible=false end
CAS:BindActionAtPriority('DTMHoldSprint',function(_,state,input)
 if state==Enum.UserInputState.Begin and Input:GetFocusedTextBox()then return Enum.ContextActionResult.Pass end
 local key=input.KeyCode
 if state==Enum.UserInputState.Begin then keys[key]=true else keys[key]=nil end
 local value=next(keys)~=nil;if value~=sprint then sprint=value;remote:FireServer(value)end
 return Enum.ContextActionResult.Sink
end,true,3000,Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift,Enum.KeyCode.LeftControl,Enum.KeyCode.RightControl)
CAS:SetTitle('DTMHoldSprint','БЕГ');CAS:SetPosition('DTMHoldSprint',UDim2.new(1,-166,1,-170))
Input.WindowFocusReleased:Connect(release);P.CharacterRemoving:Connect(release)
Input.TextBoxFocused:Connect(release)
local elapsed=0;Run.Heartbeat:Connect(function(dt)elapsed+=dt;if elapsed>.5 then elapsed=0;if panel.Visible then refresh()end end end)
-- A small presentation-only tool in the lower-right corner. No Tool scripts,
-- joints, physics or remotes are cloned into this first-person model.
local view,source;local hidden={}
local function clearView()
 if view then view:Destroy();view=nil end
 for part,value in hidden do if part.Parent then part.LocalTransparencyModifier=value end end
 table.clear(hidden);source=nil
end
local function build(tool)
 clearView();source=tool;view=Instance.new('Model');view.Name='DTMFirstPersonTool'
 local handle=tool:FindFirstChild('Handle');if not handle then clearView();return end
 for _,part in tool:GetDescendants()do if part:IsA('BasePart')then
  local copy=part:Clone();for _,d in copy:GetDescendants()do if d:IsA('LuaSourceContainer')or d:IsA('JointInstance')or d:IsA('WeldConstraint')or d:IsA('NoCollisionConstraint')or d:IsA('Constraint')or d:IsA('Sound')or d:IsA('ParticleEmitter')or d:IsA('Trail')then d:Destroy()end end
  copy.Anchored=true;copy.CanCollide=false;copy.CanTouch=false;copy.CanQuery=false;copy.LocalTransparencyModifier=0;copy.CFrame=handle.CFrame:ToObjectSpace(part.CFrame);copy.Parent=view
  if part==handle then view.PrimaryPart=copy end
 end end
 view:ScaleTo(.32);view.Parent=workspace.CurrentCamera
end
Run:BindToRenderStep('DTMFirstPersonComfort',Enum.RenderPriority.Camera.Value+2,function()
 local camera=workspace.CurrentCamera;local ch=P.Character;local head=ch and ch:FindFirstChild('Head');local tool=ch and ch:FindFirstChildOfClass('Tool')
 local first=camera and head and(camera.CFrame.Position-head.Position).Magnitude<1.05
 if not first or not tool or not tool:GetAttribute('SandPrototypeTool')then if source then clearView()end;return end
 if source~=tool or not view or view.Parent~=camera then build(tool)end
 if not view then return end
 for _,part in tool:GetDescendants()do if part:IsA('BasePart')then if hidden[part]==nil then hidden[part]=part.LocalTransparencyModifier end;part.LocalTransparencyModifier=1 end end
 local phase=math.clamp((os.clock()-(tool:GetAttribute('DigStrokeAt')or -100))/.18,0,1);local motion=math.sin(phase*math.pi)
 local right=.65*math.min(1,camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y)/1.2)
 view:PivotTo(camera.CFrame*CFrame.new(right,-.55+motion*.06,-1.4-motion*.08)*CFrame.Angles(math.rad(100-motion*9),0,math.rad(-12)))
end)
P.CharacterRemoving:Connect(clearView)
