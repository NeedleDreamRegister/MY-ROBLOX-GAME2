local M={}
function M.Build(position)
 local m=Instance.new('Model');m.Name='UpgradeMachine';m:SetAttribute('VisualVersion',13)
 local dark=Color3.fromRGB(28,39,49);local edge=Color3.fromRGB(74,92,102);local black=Color3.fromRGB(10,22,31)
 local blue=Color3.fromRGB(64,213,240);local gold=Color3.fromRGB(236,165,69);local purple=Color3.fromRGB(177,122,250)
 local function part(n,size,offset,col,mat,cf)
  local p=Instance.new('Part');p.Name=n;p.Size=size;p.CFrame=CFrame.new(position+offset)*(cf or CFrame.identity);p.Color=col or dark;p.Material=mat or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
 end
 local function light(n,size,pos,col)local p=part(n,size,pos,col,Enum.Material.Neon);p:SetAttribute('DTMPulse',true);return p end
 local function labelGui(p,name,width,height)
  local g=Instance.new('SurfaceGui');g.Name=name;g.Face=Enum.NormalId.Back;g.CanvasSize=Vector2.new(width,height);g.LightInfluence=.05;g.MaxDistance=100;g.Parent=p;return g
 end
 local function text(g,s,pos,size,font,col,align)
  local l=Instance.new('TextLabel');l.BackgroundTransparency=1;l.Text=s;l.Position=pos;l.Size=size;l.Font=Enum.Font.GothamBold;l.TextScaled=true;l.TextWrapped=true;l.TextColor3=col or Color3.fromRGB(222,236,233);l.TextXAlignment=align or Enum.TextXAlignment.Left;l.Parent=g;local cap=Instance.new('UITextSizeConstraint');cap.MaxTextSize=font;cap.MinTextSize=8;cap.Parent=l;return l
 end
 part('Foundation',Vector3.new(10,.32,5.3),Vector3.new(0,.16,0),black)
 part('FloatingPlinth',Vector3.new(9.65,.22,5),Vector3.new(0,.42,0),edge)
 light('PlinthLight',Vector3.new(9.3,.055,.07),Vector3.new(0,.43,2.52),blue)
 local body=part('Body',Vector3.new(5.8,7.65,3.8),Vector3.new(-1.35,4.35,0),dark);body.CanCollide=true;body.CanQuery=true;m.PrimaryPart=body
 part('Crown',Vector3.new(6.15,.42,4.2),Vector3.new(-1.35,8.34,0),edge)
 part('CrownInset',Vector3.new(5.6,.14,3.9),Vector3.new(-1.35,8.63,0),black)
 for _,x in {-4.28,1.58}do
  part('ArmoredPillar',Vector3.new(.3,7.6,.45),Vector3.new(x,4.35,1.92),edge)
  light('EnergyRail',Vector3.new(.07,5.2,.055),Vector3.new(x,5.13,2.17),x<0 and blue or purple)
  for _,y in {.85,2.1,7.6,8.05}do part('Bolt',Vector3.new(.12,.12,.07),Vector3.new(x,y,2.18),gold)end
 end
 for _,side in {-1,1}do
  local x=-1.35+side*2.94
  for i=1,8 do part('CoolingFin',Vector3.new(.11,.12,2.4),Vector3.new(x,1.1+i*.22,-.05),black)end
  part('SidePanel',Vector3.new(.06,3.45,2.55),Vector3.new(x,5.55,-.05),Color3.fromRGB(38,52,63))
  for j=1,3 do light('SideStatus',Vector3.new(.08,.12,.5),Vector3.new(x,3.4+j*.23,.7),blue)end
 end
 local header=part('HeaderPlate',Vector3.new(5.35,.88,.18),Vector3.new(-1.35,7.53,2.05),black)
 local hg=labelGui(header,'BrandDisplay',1000,160)
 text(hg,'DTM  /  FORGE',UDim2.fromScale(.04,.05),UDim2.fromScale(.92,.32),38,gold)
 text(hg,'АВТОМАТ УЛУЧШЕНИЙ',UDim2.fromScale(.04,.4),UDim2.fromScale(.92,.52),48,Color3.fromRGB(233,242,237))
 part('ScreenFrame',Vector3.new(5.25,3.76,.25),Vector3.new(-1.35,5.05,2),edge)
 local screen=part('Touchscreen',Vector3.new(4.94,3.43,.13),Vector3.new(-1.35,5.05,2.19),black,Enum.Material.SmoothPlastic)
 local g=labelGui(screen,'UpgradeDisplay',840,570)
 local bg=Instance.new('Frame');bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromRGB(9,27,35);bg.BorderSizePixel=0;bg.Parent=g
 local grad=Instance.new('UIGradient');grad.Color=ColorSequence.new(Color3.fromRGB(11,34,44),Color3.fromRGB(22,54,64));grad.Rotation=35;grad.Parent=bg
 text(g,'СОЗДАЙ СВОЙ СЛЕДУЮЩИЙ ИНСТРУМЕНТ',UDim2.fromScale(.06,.065),UDim2.fromScale(.88,.14),31,blue)
 text(g,'КОПАЙ. ПРОДАВАЙ.\nСТАНОВИСЬ СИЛЬНЕЕ.',UDim2.fromScale(.06,.24),UDim2.fromScale(.87,.29),49)
 local names={'08  ИНСТРУМЕНТОВ','05  УРОВНЕЙ','04  СЕКЦИИ'}
 for i,s in names do text(g,s,UDim2.fromScale(.06+(i-1)*.31,.63),UDim2.fromScale(.28,.09),22,i==1 and blue or i==2 and purple or gold)end
 text(g,'E   ОТКРЫТЬ МАСТЕРСКУЮ',UDim2.fromScale(.06,.81),UDim2.fromScale(.88,.12),37,gold)
 local scan=Instance.new('Frame');scan.Name='Scanline';scan.Size=UDim2.new(1,0,0,3);scan.BackgroundColor3=blue;scan.BackgroundTransparency=.78;scan.BorderSizePixel=0;scan.Parent=g
 light('ScreenUnderline',Vector3.new(4.8,.06,.08),Vector3.new(-1.35,3.18,2.24),blue)
 part('ConsoleDeck',Vector3.new(5.15,.22,.9),Vector3.new(-1.35,2.65,2),edge,Enum.Material.Metal,CFrame.Angles(-.15,0,0))
 for i,col in {gold,blue,purple}do
  local x=-1.35+(i-2)*1.55;part('ButtonSocket',Vector3.new(.94,.12,.62),Vector3.new(x,2.84,2.08),black)
  light('ButtonCap',Vector3.new(.73,.09,.44),Vector3.new(x,2.95,2.08),col)
 end
 part('ServiceHatch',Vector3.new(4.9,1.34,.12),Vector3.new(-1.35,1.54,1.97),Color3.fromRGB(21,31,41))
 part('HatchLatch',Vector3.new(.1,.44,.1),Vector3.new(.7,1.58,2.06),gold)
 for i=1,7 do part('HatchVent',Vector3.new(2.6,.055,.06),Vector3.new(-1.65,1.15+i*.12,2.05),edge)end
 local side=part('ShowcaseBody',Vector3.new(2.55,6.75,3.8),Vector3.new(3.05,3.93,0),dark);side.CanCollide=true
 for _,x in {1.84,4.26}do part('ShowcaseRim',Vector3.new(.13,6.1,.22),Vector3.new(x,4.05,2),edge)end
 part('ShowcaseCrown',Vector3.new(2.8,.32,4.15),Vector3.new(3.05,7.48,0),edge)
 light('ShowcaseTop',Vector3.new(2.4,.05,.08),Vector3.new(3.05,7.19,2.04),purple)
 local glass=part('DisplayGlass',Vector3.new(2.25,4.2,.07),Vector3.new(3.05,4.5,2.05),Color3.fromRGB(121,191,209),Enum.Material.Glass);glass.Transparency=.86;glass.Reflectance=.12
 part('DisplayBack',Vector3.new(2.22,4.2,.1),Vector3.new(3.05,4.5,1.43),black)
 part('DisplayPedestal',Vector3.new(1.8,.2,.55),Vector3.new(3.05,2.45,1.72),edge)
 local sample=require(script.Parent.UpgradeToolAppearance).Build('shovel');for _,v in sample:GetDescendants()do if v:IsA('BasePart')then v.Anchored=true;v.CFrame=CFrame.new(position+Vector3.new(3.05,4.4,1.7))*CFrame.Angles(.3,math.pi,0)*v.CFrame;v.Size*=.68 end end
 -- Tool parts are scaled around their common origin, independently of gameplay tools.
 for _,v in sample:GetChildren()do if v:IsA('BasePart')then local base=position+Vector3.new(3.05,4.4,1.7);v.Position=base+(v.Position-base)*.68 end end
 sample.Name='CrystalShowpiece';sample.Parent=m
 local tag=part('ShowcaseTag',Vector3.new(2.2,.7,.13),Vector3.new(3.05,1.85,2.04),black)
 local tg=labelGui(tag,'ShowcaseLabel',440,150);text(tg,'КРИСТАЛЬНАЯ ЛАПА\nКОЛЛЕКЦИЯ ИНСТРУМЕНТОВ',UDim2.fromScale(.04,.1),UDim2.fromScale(.92,.8),25,purple,Enum.TextXAlignment.Center)
 for i=1,4 do part('ShowcaseVent',Vector3.new(1.85,.08,.08),Vector3.new(3.05,.8+i*.12,2.03),edge)end
 light('IconShaft',Vector3.new(.17,1.15,.16),Vector3.new(-1.35,9.22,0),blue)
 light('IconGrip',Vector3.new(.75,.17,.17),Vector3.new(-1.35,9.88,0),gold)
 light('IconBlade',Vector3.new(.95,.58,.17),Vector3.new(-1.35,8.75,0),purple)

 -- Sculpted exterior: bevels, bronze reveals and a single readable focal display.
 body.Color=Color3.fromRGB(38,49,59)
 for _,p in m:GetChildren()do if p:IsA('BasePart')then
  if p.Name:find('Icon')or p.Name=='ButtonCap'or p.Name=='ButtonSocket'then p:Destroy()
  elseif p.Name=='EnergyRail'then p.Size=Vector3.new(.045,4.9,.045)
  elseif p.Name=='HeaderPlate'then p.Color=Color3.fromRGB(27,38,46)end
 end end
 local bronze=Color3.fromRGB(173,129,69);local alloy=Color3.fromRGB(116,135,144)
 local function wedge(n,size,pos,col,rotation)
  local p=Instance.new('WedgePart');p.Name=n;p.Size=size;p.CFrame=CFrame.new(position+pos)*(rotation or CFrame.identity);p.Color=col;p.Material=Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=m;return p
 end
 local function cylinder(n,diameter,depth,pos,col,rotation,mat)
  local p=part(n,Vector3.new(depth,diameter,diameter),pos,col,mat or Enum.Material.Metal,rotation);p.Shape=Enum.PartType.Cylinder;return p
 end
 for _,side in {-1,1}do
  local x=-1.35+side*3
  wedge('ShoulderBevel',Vector3.new(.5,1.1,3.9),Vector3.new(x,7.95,.05),alloy,CFrame.Angles(0,side<0 and math.pi or 0,side<0 and 0 or math.pi))
  part('FloatingArmor',Vector3.new(.18,4.4,3.15),Vector3.new(x+side*.08,5.2,-.15),Color3.fromRGB(47,65,76))
  part('BronzeReveal',Vector3.new(.08,6.8,.1),Vector3.new(x+side*.11,4.45,1.57),bronze)
  wedge('LowerArmorBevel',Vector3.new(.5,1.0,3.9),Vector3.new(x,1.0,.02),edge,CFrame.Angles(0,side<0 and 0 or math.pi,side<0 and math.pi or 0))
  for i=1,3 do part('RecessedSideVent',Vector3.new(.2,.16,2.1),Vector3.new(x+side*.18,4.05+i*.32,-.1),black)end
 end
 wedge('CrownChamfer',Vector3.new(5.75,.45,.6),Vector3.new(-1.35,8.66,1.77),alloy,CFrame.Angles(0,math.pi,0))
 part('CrownBronzeLip',Vector3.new(5.3,.055,.08),Vector3.new(-1.35,8.56,2.15),bronze)
 for _,x in {-3.84,1.14}do part('ScreenBezel',Vector3.new(.17,3.85,.14),Vector3.new(x,5.05,2.27),bronze)end
 for _,y in {3.12,6.98}do part('ScreenBezel',Vector3.new(5.12,.12,.14),Vector3.new(-1.35,y,2.27),bronze)end
 for i=1,3 do
  local x=-1.35+(i-2)*1.5
  cylinder('ControlDial',.78,.12,Vector3.new(x,2.89,2.08),bronze,CFrame.Angles(0,0,math.pi/2))
  cylinder('DialInset',.61,.14,Vector3.new(x,2.98,2.08),black,CFrame.Angles(0,0,math.pi/2))
  cylinder('DialLight',.35,.145,Vector3.new(x,3.0,2.08),({gold,blue,purple})[i],CFrame.Angles(0,0,math.pi/2),Enum.Material.Neon)
 end
 local serial=part('SerialBadge',Vector3.new(1.5,.35,.06),Vector3.new(-2.9,1.65,2.08),bronze)
 text(labelGui(serial,'Serial',450,100),'DTM  /  F-013',UDim2.fromScale(.05,.06),UDim2.fromScale(.9,.88),38,black,Enum.TextXAlignment.Center)
 local plate=part('ForgeEmblemMount',Vector3.new(1.6,1.6,.2),Vector3.new(-1.35,9.35,.2),black)
 plate.Shape=Enum.PartType.Cylinder;plate.Size=Vector3.new(.2,1.6,1.6);plate.CFrame=CFrame.new(position+Vector3.new(-1.35,9.35,.2))*CFrame.Angles(0,math.pi/2,0)
 for i=1,24 do
  local a=i*math.pi*2/24
  part('EmblemRing',Vector3.new(.17,.07,.1),Vector3.new(-1.35+math.cos(a)*.86,9.35+math.sin(a)*.86,.35),bronze,Enum.Material.Metal,CFrame.Angles(0,0,a+math.pi/2))
 end
 light('EmblemStem',Vector3.new(.1,.82,.09),Vector3.new(-1.35,9.4,.38),blue)
 part('EmblemGrip',Vector3.new(.49,.13,.1),Vector3.new(-1.35,9.85,.38),gold)
 wedge('EmblemScoop',Vector3.new(.53,.43,.12),Vector3.new(-1.35,8.97,.38),gold,CFrame.Angles(0,0,math.pi))
 part('ShowcasePedestalRim',Vector3.new(1.95,.1,1.03),Vector3.new(3.05,2.8,1.0),bronze)
 light('ShowcasePedestalLight',Vector3.new(1.7,.055,.85),Vector3.new(3.05,2.88,1.0),purple)
 for _,y in {2.36,6.67}do part('GlassBronzeRail',Vector3.new(2.35,.08,.08),Vector3.new(3.05,y,2.13),bronze)end
 for _,x in {1.89,4.21}do part('GlassBronzeRail',Vector3.new(.065,4.35,.08),Vector3.new(x,4.5,2.13),bronze)end
 local spotlight=Instance.new('PointLight');spotlight.Name='DisplayLight';spotlight.Color=purple;spotlight.Brightness=.35;spotlight.Range=5;spotlight.Shadows=false;spotlight.Parent=m.DisplayPedestal
 -- Replace promotional text with a live, readable terminal display.
 screen.CanQuery=true
 g:ClearAllChildren()
 local function uiFrame(name,pos,size,color,parent)
  local f=Instance.new('Frame');f.Name=name;f.Position=pos;f.Size=size;f.BackgroundColor3=color;f.BorderSizePixel=0;f.Parent=parent or g;local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,12);c.Parent=f;return f
 end
 local background=uiFrame('Background',UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(13,29,40))
 local gr=Instance.new('UIGradient');gr.Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(119,159,184));gr.Rotation=35;gr.Parent=background
 text(g,'FORGE  /  013',UDim2.fromScale(.055,.05),UDim2.fromScale(.65,.065),32,gold)
 local dot=uiFrame('ReadyDot',UDim2.fromScale(.85,.06),UDim2.fromScale(.018,.027),blue)
 text(g,'ГОТОВ',UDim2.fromScale(.88,.045),UDim2.fromScale(.1,.06),18,blue)
 text(g,'ТВОЙ СЛЕДУЮЩИЙ\nБОЛЬШОЙ ШАГ',UDim2.fromScale(.055,.17),UDim2.fromScale(.9,.25),53,Color3.fromRGB(235,242,232))
 local selected=text(g,'Обычная лопата',UDim2.fromScale(.06,.49),UDim2.fromScale(.88,.065),30,blue);selected.Name='SelectedTool'
 local stats=text(g,'УРОВЕНЬ 1 / 5   •   20 ПЕСКА',UDim2.fromScale(.06,.575),UDim2.fromScale(.88,.055),24,Color3.fromRGB(181,207,213));stats.Name='ToolStats'
 local open=Instance.new('TextButton');open.Name='OpenWorkshop';open.Position=UDim2.fromScale(.055,.735);open.Size=UDim2.fromScale(.89,.145);open.BackgroundColor3=blue;open.Text='ОТКРЫТЬ МАСТЕРСКУЮ   →';open.Font=Enum.Font.GothamBold;open.TextScaled=true;open.TextColor3=black;open.Parent=g;local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,14);corner.Parent=open;local cap=Instance.new('UITextSizeConstraint');cap.MaxTextSize=32;cap.Parent=open
 text(g,'НАЖМИТЕ E ИЛИ КНОПКУ НА ЭКРАНЕ',UDim2.fromScale(.06,.915),UDim2.fromScale(.88,.04),19,Color3.fromRGB(156,186,196),Enum.TextXAlignment.Center)
 local scan=uiFrame('Scanline',UDim2.fromScale(0,0),UDim2.new(1,0,0,2),blue);scan.BackgroundTransparency=.85
 m.CrystalShowpiece:SetAttribute('AnimatedShowpiece',true)

 local prompt=Instance.new('ProximityPrompt');prompt.Name='UpgradePrompt';prompt.ActionText='Открыть мастерскую';prompt.ObjectText='АВТОМАТ УЛУЧШЕНИЙ';prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.HoldDuration=.15;prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.Parent=body
 require(script.Parent.UpgradeMachineRefinement).Apply(m)
 return m
end
return M