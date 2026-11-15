-- Cosmetic-only theme. Does not change inventory, prices, saving, or gameplay remotes.
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local styled=setmetatable({},{__mode="k"})
local cream=Color3.fromRGB(246,232,203)
local gold=Color3.fromRGB(211,175,100)
local teal=Color3.fromRGB(22,48,49)
local function corner(widget,radius)
 local c=widget:FindFirstChildWhichIsA("UICorner")
 if not c then c=Instance.new("UICorner") c.Parent=widget end
 c.CornerRadius=UDim.new(0,radius)
end
local function stroke(widget,color,transparency)
 local s=widget:FindFirstChild("DTMThemeStroke")
 if not s then s=Instance.new("UIStroke")s.Name="DTMThemeStroke"s.Parent=widget end
 s.Color=color s.Thickness=1 s.Transparency=transparency s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
end
local function gradient(widget,top,bottom)
 local g=widget:FindFirstChild("DTMThemeGradient")
 if not g then g=Instance.new("UIGradient")g.Name="DTMThemeGradient"g.Parent=widget end
 g.Rotation=90 g.Color=ColorSequence.new(top,bottom)
end
local function decorate(widget)
 if styled[widget] or not widget:IsA("GuiObject") then return end
 local gui=widget:FindFirstAncestorWhichIsA("ScreenGui")
 if not gui then return end
 local name=widget.Name
 if gui.Name=="SandPrototypeHUD" then
  if name=="InventoryCard" then
   styled[widget]=true widget.BackgroundColor3=Color3.new(1,1,1)widget.BackgroundTransparency=.06 widget.BorderSizePixel=0
   corner(widget,12)stroke(widget,gold,.48)
   gradient(widget,Color3.fromRGB(28,54,55),Color3.fromRGB(17,32,34))
   if not widget:FindFirstChild("DTMAccent") then
    local accent=Instance.new("Frame")accent.Name="DTMAccent"accent.BorderSizePixel=0
    accent.BackgroundColor3=gold accent.Position=UDim2.new(0,0,.12,0)accent.Size=UDim2.new(0,3,.76,0)
    accent.Parent=widget corner(accent,2)
   end
  elseif name=="Inventory" then styled[widget]=true widget.Font=Enum.Font.GothamBold widget.TextColor3=cream
  elseif name=="MoneyAndXP" then styled[widget]=true widget.TextColor3=Color3.fromRGB(235,204,143)
  elseif name=="Hint" then
   styled[widget]=true widget.TextColor3=Color3.fromRGB(212,220,205)
   local function refreshHint()
    local text=widget.Text:gsub("Зелёная станция покупает песок","Автомат принимает песок")
    if text~=widget.Text then widget.Text=text end
   end
   widget:GetPropertyChangedSignal("Text"):Connect(refreshHint)
   refreshHint()
  elseif name=="CapacityBar" or name=="MountainBar" then
   styled[widget]=true widget.BackgroundColor3=Color3.fromRGB(56,77,74)corner(widget,4)
  elseif name=="Fill" then
   styled[widget]=true corner(widget,4)
   -- Gameplay HUD retains ownership of the fill size and warning colors.
  end
 elseif gui.Name=="SandPrototypeVisits" then
  if name=="Menu" then
   styled[widget]=true widget.BackgroundColor3=Color3.new(1,1,1)widget.BackgroundTransparency=.04 widget.BorderSizePixel=0
   corner(widget,12)stroke(widget,gold,.5)
   gradient(widget,Color3.fromRGB(28,54,55),Color3.fromRGB(17,32,34))
  elseif widget:IsA("TextButton") and name~="Toggle" then
   styled[widget]=true corner(widget,7)stroke(widget,Color3.fromRGB(115,151,131),.7)
  elseif name=="Toggle" then
   styled[widget]=true widget.TextColor3=cream
  end
 elseif gui.Name=="SandPrototypeFeedback" and name=="DigToast" then
  styled[widget]=true widget.BackgroundColor3=teal widget.BackgroundTransparency=.08
  corner(widget,10)stroke(widget,gold,.45)
 elseif gui.Name=="DTM_MobileDig" and name=="DigButton" then
  styled[widget]=true widget.BackgroundColor3=Color3.new(1,1,1)widget.BorderSizePixel=0
  widget.TextColor3=Color3.fromRGB(31,45,41)
  corner(widget,14)stroke(widget,Color3.fromRGB(251,221,158),.25)
  gradient(widget,Color3.fromRGB(229,185,101),Color3.fromRGB(205,153,66))
 end
end
local function watchGui(gui)
 if not gui:IsA("ScreenGui") then return end
 gui.DescendantAdded:Connect(function(widget)task.defer(decorate,widget)end)
 for _,widget in ipairs(gui:GetDescendants())do task.defer(decorate,widget)end
end
playerGui.ChildAdded:Connect(watchGui)
for _,gui in ipairs(playerGui:GetChildren())do watchGui(gui)end

-- Move only the owner plaque to the decorative gate.
-- Spawn points, plot models, access buttons and permissions are untouched.
local plaqueDone=setmetatable({},{__mode="k"})
local function placePlaque(sign)
 if not sign:IsA("BasePart") or sign.Name~="OwnerSign" or plaqueDone[sign] then return end
 plaqueDone[sign]=true
 task.spawn(function()
  local plot=sign.Parent
  for attempt=1,30 do
   if not sign.Parent or not plot then return end
   local station=plot:FindFirstChild("SandPrototypeStation")
   local fence=station and station:FindFirstChild("PlotFence")
   local gate=fence and fence:FindFirstChild("ArchSign")
   if gate then
    sign.Size=Vector3.new(10.6,.9,.18)
    sign.CFrame=gate.CFrame*CFrame.new(0,-1.35,0)
    sign.Material=Enum.Material.Wood sign.Color=Color3.fromRGB(35,75,73)
    for _,gui in ipairs(sign:GetChildren())do if gui:IsA("SurfaceGui")then
     gui.CanvasSize=Vector2.new(848,90)gui.LightInfluence=.5
     for _,text in ipairs(gui:GetDescendants())do if text:IsA("TextLabel")then
      text.TextColor3=cream text.Font=Enum.Font.GothamMedium
     end end
    end end
    local front=sign:FindFirstChildWhichIsA("SurfaceGui")
    if front and not sign:FindFirstChild("DTMOwnerLabelBack") then
     local back=front:Clone()back.Name="DTMOwnerLabelBack"back.Face=Enum.NormalId.Back back.Parent=sign
    end
    return
   end
   task.wait(.1)
  end
 end)
end

local exhibitDone=setmetatable({},{__mode="k"})
local padDone=setmetatable({},{__mode="k"})
local function visualPart(parent,name,size,cf,color,material)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false
 p.Color=color p.Material=material or Enum.Material.SmoothPlastic
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent return p
end
local function paintWorldSign(sign)
 sign.Color=Color3.fromRGB(35,75,73)sign.Material=Enum.Material.Wood
 sign.TopSurface=Enum.SurfaceType.Smooth
 for _,v in ipairs(sign:GetDescendants())do
  if v:IsA("SurfaceGui")then v.LightInfluence=.35
  elseif v:IsA("TextLabel")then v.TextColor3=cream v.Font=Enum.Font.GothamMedium end
 end
end
local function dressShovelPad(pad)
 if padDone[pad]or not pad:IsA("BasePart")then return end
 padDone[pad]=true
 pad.Material=Enum.Material.Sandstone pad.Color=Color3.fromRGB(164,113,57)pad.TopSurface=Enum.SurfaceType.Smooth
 local decor=Instance.new("Model")decor.Name="DTMVisualPadTrim"
 local top=pad.Position.Y+pad.Size.Y/2+.025
 for _,dx in ipairs({-pad.Size.X/2+.2,pad.Size.X/2-.2})do
  visualPart(decor,"BrassEdge",Vector3.new(.07,.05,pad.Size.Z-.35),CFrame.new(pad.Position.X+dx,top,pad.Position.Z),gold,Enum.Material.Metal)
 end
 for _,dz in ipairs({-pad.Size.Z/2+.2,pad.Size.Z/2-.2})do
  visualPart(decor,"BrassEdge",Vector3.new(pad.Size.X-.35,.05,.07),CFrame.new(pad.Position.X,top,pad.Position.Z+dz),gold,Enum.Material.Metal)
 end
 decor:SetAttribute("PurelyVisual",true)decor.Parent=pad
end
local function dressMuseum(museum)
 if exhibitDone[museum]or not museum:IsA("Model")then return end
 exhibitDone[museum]=true
 task.spawn(function()
  local ped=museum:WaitForChild("Pedestal",5)
  local ped2=museum:WaitForChild("Pedestal2",5)
  if not ped or not ped2 or not museum.Parent then return end
  if museum:FindFirstChild("DTMVisualExhibit")then return end
  local art=Instance.new("Model")art.Name="DTMVisualExhibit"art:SetAttribute("PurelyVisual",true)
  local bronze=Color3.fromRGB(176,139,78)
  for _,base in ipairs({ped,ped2})do
   base.Material=Enum.Material.Sandstone base.Color=Color3.fromRGB(161,140,108)
   base.TopSurface=Enum.SurfaceType.Smooth base.BottomSurface=Enum.SurfaceType.Smooth
   local x,z=base.Position.X,base.Position.Z
   local top=base.Position.Y+base.Size.Y/2
   local width,depth=base.Size.X-.3,base.Size.Z-.35
   local h=2.2
   for _,dx in ipairs({-width/2,width/2})do for _,dz in ipairs({-depth/2,depth/2})do
    local post=visualPart(art,"ExhibitCorner",Vector3.new(.075,h,.075),CFrame.new(x+dx,top+h/2,z+dz),bronze,Enum.Material.Metal)
    post.CastShadow=false
   end end
   for _,y in ipairs({top+.035,top+h})do
    for _,dz in ipairs({-depth/2,depth/2})do
     visualPart(art,"ExhibitRail",Vector3.new(width+.075,.065,.075),CFrame.new(x,y,z+dz),bronze,Enum.Material.Metal).CastShadow=false
    end
    for _,dx in ipairs({-width/2,width/2})do
     visualPart(art,"ExhibitRail",Vector3.new(.075,.065,depth+.075),CFrame.new(x+dx,y,z),bronze,Enum.Material.Metal).CastShadow=false
    end
   end
   local function glass(size,cf)
    local g=visualPart(art,"ExhibitGlass",size,cf,Color3.fromRGB(186,214,202),Enum.Material.Glass)
    g.Transparency=.88 g.Reflectance=.06 g.CastShadow=false
   end
   for _,dx in ipairs({-width/2,width/2})do glass(Vector3.new(.035,h,depth),CFrame.new(x+dx,top+h/2,z))end
   for _,dz in ipairs({-depth/2,depth/2})do glass(Vector3.new(width,h,.035),CFrame.new(x,top+h/2,z+dz))end
   glass(Vector3.new(width,.035,depth),CFrame.new(x,top+h,z))
  end
  for _,name in ipairs({"Sign","FutureSign"})do
   local sign=museum:FindFirstChild(name)
   if sign and sign:IsA("BasePart")then
    paintWorldSign(sign)
    local width=name=="Sign"and 8.3 or 4.2
    sign.Size=Vector3.new(width,1.1,.18)
    sign.Position=Vector3.new(sign.Position.X,ped.Position.Y+3.5,sign.Position.Z)
    for _,gui in ipairs(sign:GetChildren())do if gui:IsA("SurfaceGui")then gui.CanvasSize=Vector2.new(width*100,110)end end
   end
  end
  local minX=math.min(ped.Position.X-ped.Size.X/2,ped2.Position.X-ped2.Size.X/2)-.7
  local maxX=math.max(ped.Position.X+ped.Size.X/2,ped2.Position.X+ped2.Size.X/2)+.7
  local midX=(minX+maxX)/2
  local backZ=ped.Position.Z-2.85
  local floor=visualPart(art,"DisplayApron",Vector3.new(maxX-minX,.05,6.3),CFrame.new(midX,.075,ped.Position.Z+.1),Color3.fromRGB(193,167,126),Enum.Material.Sandstone)
  floor.CastShadow=false
  for _,x in ipairs({minX+.2,maxX-.2})do
   visualPart(art,"DisplayPost",Vector3.new(.16,5.65,.16),CFrame.new(x,2.825,backZ),Color3.fromRGB(100,71,48),Enum.Material.Wood)
  end
  local header=visualPart(art,"DisplayHeading",Vector3.new(maxX-minX,1.12,.18),CFrame.new(midX,5.4,backZ),teal,Enum.Material.Wood)
  for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back})do
   local gui=Instance.new("SurfaceGui")gui.Name="ExhibitHeading"gui.Face=face gui.CanvasSize=Vector2.new(980,90)gui.LightInfluence=.35 gui.Parent=header
   local label=Instance.new("TextLabel")label.Size=UDim2.fromScale(.96,.9)label.Position=UDim2.fromScale(.02,.05)
   label.BackgroundTransparency=1 label.Text="НАХОДКИ"label.Font=Enum.Font.GothamBold label.TextColor3=cream label.TextScaled=true label.Parent=gui
  end
  for _,base in ipairs({ped,ped2})do
   local lamp=visualPart(art,"DisplayLamp",Vector3.new(2.4,.045,.12),CFrame.new(base.Position.X,4.8,backZ+.18),Color3.fromRGB(244,219,166),Enum.Material.Neon)
   lamp.CastShadow=false
   local light=Instance.new("SpotLight")light.Face=Enum.NormalId.Bottom light.Angle=90 light.Range=10 light.Brightness=.9
   light.Color=Color3.fromRGB(255,228,184)light.Shadows=false light.Parent=lamp
  end
  art.Parent=museum
 end)
end

local pathDone=setmetatable({},{__mode="k"})
local function finishGuidePath(path)
 if pathDone[path]or not path:IsA("Model")then return end
 pathDone[path]=true
 task.spawn(function()
  local plot=path.Parent
  local mountain=plot and plot:WaitForChild("SandPrototype",5)
  local start=path:WaitForChild("Step_0",5)
  if not mountain or not start then return end
  local origin,initial
  for attempt=1,150 do
   if not path.Parent or not mountain.Parent then return end
   if mountain:GetAttribute("TerrainEnabled")==false then return end
   origin=mountain:GetAttribute("TerrainOrigin")initial=mountain:GetAttribute("InitialCells")
   if typeof(origin)=="Vector3"and type(initial)=="number"then break end
   task.wait(.1)
  end
  if typeof(origin)~="Vector3"or type(initial)~="number"then return end
  local height
  for h=1,128 do if math.abs((h+1)*(2*h+1)*(2*h+3)/3-initial)<.5 then height=h break end end
  if not height or path:FindFirstChild("DTMVisualPathExtension")then return end
  local goal=Vector3.new(origin.X,start.Position.Y,origin.Z+height*4+8)
  local delta=goal-start.Position
  if delta.Magnitude<3.6 then return end
  local n=math.ceil(delta.Magnitude/3.6)
  local art=Instance.new("Model")art.Name="DTMVisualPathExtension"art:SetAttribute("PurelyVisual",true)
  for i=1,n do
   local pos=start.Position:Lerp(goal,i/n)
   local color=start.Color:Lerp(Color3.fromRGB(218,195,154),i%2*.12)
   visualPart(art,"GuideStone_"..i,start.Size,CFrame.lookAt(pos,pos+delta.Unit),color,start.Material)
  end
  art.Parent=path
 end)
end

-- Display the original SellPrompt using a legible PC/touch presentation.
-- Input is forwarded to the existing prompt; its server handler owns the sale.
local promptService=game:GetService("ProximityPromptService")
local promptInput=game:GetService("UserInputService")
local promptTweens=game:GetService("TweenService")
local sellPresentation=Instance.new("ScreenGui")
sellPresentation.Name="DTM_SandExchangePrompt"
sellPresentation.ResetOnSpawn=false sellPresentation.DisplayOrder=20
sellPresentation.Parent=playerGui
local sellButton=Instance.new("TextButton")
sellButton.Name="SellButton"sellButton.AnchorPoint=Vector2.new(.5,1)
sellButton.Position=UDim2.new(.5,0,1,-82)sellButton.Size=UDim2.fromOffset(270,58)
sellButton.BackgroundColor3=teal sellButton.BorderSizePixel=0 sellButton.Text=""
sellButton.Visible=false sellButton.AutoButtonColor=true sellButton.Parent=sellPresentation
corner(sellButton,11)stroke(sellButton,gold,.12)
local sellTitle=Instance.new("TextLabel")
sellTitle.Name="Action"sellTitle.BackgroundTransparency=1 sellTitle.Position=UDim2.fromOffset(8,5)
sellTitle.Size=UDim2.new(1,-16,0,27)sellTitle.Font=Enum.Font.GothamBold sellTitle.TextSize=20
sellTitle.TextColor3=cream sellTitle.Text="ПРОДАТЬ ПЕСОК"sellTitle.Parent=sellButton
local sellHint=Instance.new("TextLabel")
sellHint.Name="Hint"sellHint.BackgroundTransparency=1 sellHint.Position=UDim2.fromOffset(8,32)
sellHint.Size=UDim2.new(1,-16,0,17)sellHint.Font=Enum.Font.GothamMedium sellHint.TextSize=12
sellHint.TextColor3=gold sellHint.Parent=sellButton
local progress=Instance.new("Frame")progress.Name="HoldProgress"progress.BorderSizePixel=0
progress.AnchorPoint=Vector2.new(0,1)progress.Position=UDim2.new(0,10,1,-4)
progress.Size=UDim2.fromOffset(0,3)progress.BackgroundColor3=gold progress.Parent=sellButton
corner(progress,2)
local activeSellPrompt,holdInput,progressTween
local function endSellHold()
 if activeSellPrompt and holdInput then activeSellPrompt:InputHoldEnd()end
 holdInput=nil
end
local function showSellPrompt(prompt,inputType)
 if prompt.Name~="SellPrompt"or not prompt.Parent then return end
 local station=prompt.Parent.Parent
 if not station:FindFirstChild("SandExchangeV7")then return end
 local own=player:FindFirstChild("SandPrototypeMountain")
 if not own or not own.Value or station.Parent~=own.Value.Parent then return end
 endSellHold()
 activeSellPrompt=prompt
 sellHint.Text=inputType==Enum.ProximityPromptInputType.Touch
  and "Удерживайте кнопку для продажи"
  or inputType==Enum.ProximityPromptInputType.Gamepad
  and ("Удерживайте "..prompt.GamepadKeyCode.Name)
  or ("Удерживайте "..prompt.KeyboardKeyCode.Name.." или эту кнопку")
 sellButton.Visible=true
end
promptService.PromptShown:Connect(showSellPrompt)
promptService.PromptHidden:Connect(function(prompt)
 if prompt~=activeSellPrompt then return end
 endSellHold()activeSellPrompt=nil sellButton.Visible=false
 if progressTween then progressTween:Cancel()end
 progress.Size=UDim2.fromOffset(0,3)
end)
sellButton.InputBegan:Connect(function(input)
 if not activeSellPrompt or holdInput then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  holdInput=input activeSellPrompt:InputHoldBegin()
 end
end)
promptInput.InputEnded:Connect(function(input)if input==holdInput then endSellHold()end end)
promptInput.WindowFocusReleased:Connect(endSellHold)
promptService.PromptButtonHoldBegan:Connect(function(prompt)
 if prompt~=activeSellPrompt then return end
 if progressTween then progressTween:Cancel()end
 progress.Size=UDim2.fromOffset(0,3)
 progressTween=promptTweens:Create(progress,TweenInfo.new(prompt.HoldDuration,Enum.EasingStyle.Linear),{Size=UDim2.new(1,-20,0,3)})
 progressTween:Play()
end)
promptService.PromptButtonHoldEnded:Connect(function(prompt)
 if prompt~=activeSellPrompt then return end
 if progressTween then progressTween:Cancel()end
 progress.Size=UDim2.fromOffset(0,3)
end)

local machineDone=setmetatable({},{__mode="k"})
local function dressSandExchange(machine)
 if machineDone[machine]or not machine:IsA("Model")then return end
 machineDone[machine]=true
 task.spawn(function()
  local station=machine.Parent
  local pad=station:WaitForChild("SellPad",10)
  local sellPrompt=pad and pad:WaitForChild("SellPrompt",10)
  if sellPrompt then sellPrompt.Style=Enum.ProximityPromptStyle.Custom end
  local panel=machine:WaitForChild("MachineScreen",10)
  local gui=panel and panel:WaitForChild("Readout",10)
  local state=player:WaitForChild("SandPrototypeState",10)
  local ownMountain=player:WaitForChild("SandPrototypeMountain",10)
  if not gui or not state or not ownMountain then return end
  local readiness=gui:WaitForChild("Readiness",5)
  local help=gui:WaitForChild("Help",5)
  if not readiness or not help then return end
  local input=game:GetService("UserInputService")
  local function update()
   if not machine.Parent then return end
   local own=ownMountain.Value and machine:IsDescendantOf(ownMountain.Value.Parent)
   if not own then
    readiness.Text="ПРОДАЖА НА СВОЁМ УЧАСТКЕ"
    help.Text="Автомат обслуживает владельца участка"
    return
   end
   local carried=state:GetAttribute("CarriedCells")or 0
   local cargo=state:GetAttribute("CartCells")or 0
   local cart=station.Parent:FindFirstChild("FollowWheelbarrow")
   -- Match the server's station radius, using the authoritative cart rather than
   -- its locally smoothed visual copy. This is guidance, never a sale decision.
   local cartNearby=cart and cart.PrimaryPart and (cart.PrimaryPart.Position-pad.Position).Magnitude<=16
   local available=carried+(cartNearby and cargo or 0)
   local needsCart=cargo>0 and not cartNearby
   readiness.Text=available>0 and ("К ПРОДАЖЕ: "..available)
    or needsCart and ("ПОДВЕЗИТЕ ТАЧКУ: "..cargo)
    or "НЕТ ПЕСКА ДЛЯ ПРОДАЖИ"
   help.Text=needsCart and available==0 and "Подкатите тачку ближе к автомату"
    or input.PreferredInput==Enum.PreferredInput.Touch
    and "Удерживайте кнопку «Продать песок»"
    or "Удерживайте E для продажи песка"
   if activeSellPrompt==sellPrompt then
    sellTitle.Text=available>0 and ("ПРОДАТЬ ПЕСОК: "..available)
     or needsCart and "ПОДВЕЗИТЕ ТАЧКУ" or "НЕТ ПЕСКА"
    sellHint.Text=available==0 and (needsCart and "Груз должен быть рядом с автоматом"or "Сначала добудьте песок")
     or input.PreferredInput==Enum.PreferredInput.Touch and "Удерживайте кнопку для продажи"
     or input.PreferredInput==Enum.PreferredInput.Gamepad and ("Удерживайте "..sellPrompt.GamepadKeyCode.Name)
     or ("Удерживайте "..sellPrompt.KeyboardKeyCode.Name.." или эту кнопку")
   end
  end
  -- The cart can enter/leave the sale radius without an inventory change.
  local elapsed=0
  local connections={
   state:GetAttributeChangedSignal("InventoryCells"):Connect(update),
   ownMountain:GetPropertyChangedSignal("Value"):Connect(update),
   input:GetPropertyChangedSignal("PreferredInput"):Connect(update),
   game:GetService("RunService").Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.25 then return end;elapsed=0
    local ch=player.Character;local root=ch and ch:FindFirstChild("HumanoidRootPart")
    if root and (root.Position-pad.Position).Magnitude<80 then update()end
   end)
  }
  machine.Destroying:Connect(function()for _,connection in connections do connection:Disconnect()end end)
  update()
 end)
end

local function decorateWorld(v)
 if v.Name=="SandExchangeV7"then dressSandExchange(v)
 elseif v.Name=="OwnerSign"then placePlaque(v)
 elseif v.Name=="Museum"then dressMuseum(v)
 elseif v.Name=="ShovelUpgradePad"then task.defer(dressShovelPad,v)
 elseif v.Name=="EquipmentSign"and v:IsA("BasePart")then task.defer(paintWorldSign,v)
 elseif v.Name=="EquipmentBay"and v:IsA("BasePart")then v.TopSurface=Enum.SurfaceType.Smooth end
end

local function watchPlots(folder)
 if folder.Name~="SandPlots" then return end
 folder.DescendantAdded:Connect(decorateWorld)
 for _,v in ipairs(folder:GetDescendants())do decorateWorld(v)end
end
workspace.ChildAdded:Connect(watchPlots)
local plots=workspace:FindFirstChild("SandPlots")if plots then watchPlots(plots)end

