-- Consistent wayfinding and object presentation. All additions are visual-only.
local Landscape={}
local V,CF=Vector3.new,CFrame.new
local P={wood=Color3.fromRGB(136,101,65),dark=Color3.fromRGB(77,64,47),stone=Color3.fromRGB(216,204,171),green=Color3.fromRGB(49,82,65),cream=Color3.fromRGB(246,232,193),brass=Color3.fromRGB(187,151,87)}
local function part(g,name,size,cf,color,mat)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=mat or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=mat==Enum.Material.Wood;p.Parent=g;return p
end
local function text(board,message,face,size)
 local gui=Instance.new('SurfaceGui');gui.Name='RemasterLettering';gui.Face=face or Enum.NormalId.Back;gui.CanvasSize=Vector2.new(1000,size or 190);gui.LightInfluence=.7;gui.MaxDistance=130;gui.Parent=board
 local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.fromScale(.9,.8);t.Position=UDim2.fromScale(.05,.1)
 t.Text=message;t.TextColor3=P.cream;t.Font=Enum.Font.GothamMedium;t.TextScaled=true;t.Parent=gui
end
local function arrow(g,cf,message,left,width)
 width=width or 5.6
 local board=part(g,'CarvedDirectionBoard',V(width,.8,.16),cf,P.green,Enum.Material.Wood)
 local tip=Instance.new('WedgePart');tip.Name='DirectionArrowTip';tip.Size=V(.16,.8,.6)
 tip.CFrame=cf*CF((left and -1 or 1)*(width/2+.24),0,0)*CFrame.Angles(0,math.pi/2,left and math.pi or 0)
 tip.Color=P.green;tip.Material=Enum.Material.Wood;tip.Anchored=true;tip.CanCollide=false;tip.CanTouch=false;tip.CanQuery=false;tip.Parent=g
 for _,face in {Enum.NormalId.Front,Enum.NormalId.Back}do text(board,message,face)end
 part(g,'BrassDirectionInset',V(width-.15,.04,.025),cf*CF(0,-.32,.095),P.brass,Enum.Material.Metal)
 for _,x in {-width/2+.22,width/2-.22}do part(g,'ArrowRivet',V(.075,.075,.03),cf*CF(x,0,.1),P.brass,Enum.Material.Metal)end
end
local function lowLight(g,cf)
 local p=part(g,'RecessedWayfindingLamp',V(.45,.14,.4),cf,Color3.fromRGB(255,223,171),Enum.Material.Neon)
 local l=Instance.new('PointLight');l.Color=p.Color;l.Range=8;l.Brightness=.3;l.Shadows=false;l.Parent=p
end
function Landscape.Site(garden,offset)
 if garden:FindFirstChild('RemasterWayfinding')then return end
 offset=offset or Vector3.zero
 local g=Instance.new('Model');g.Name='RemasterWayfinding';g:SetAttribute('VisualOnly',true)
 local function w(x,y,z)return CF(offset+V(x,y,z))end
 -- Signs mount outside the existing gateway opening; no new supports on paths.
 for i,s in ipairs({{'КАРЬЕР  ↖',true},{'ПРОДАЖА ПЕСКА  ↗',false},{'УЛУЧШЕНИЯ  ↗',false},{'ЭЛЕКТРОКАР  ↓',false}})do
  arrow(g,w(27.5,5.85-(i-1)*.93,6),s[1],s[2],6.2)
 end
 part(g,'GatewayDirectionMount',V(.18,4.2,.25),w(24.2,4.5,6),P.wood,Enum.Material.Wood)
 lowLight(g,w(27.5,6.4,6.4))
 -- One rear junction marker serves both complete promenades.
 part(g,'RearWayfindingFoot',V(1,.3,1),w(-37,.15,-446),P.stone,Enum.Material.Limestone)
 part(g,'RearWayfindingPost',V(.27,5.4,.27),w(-37,2.85,-446),P.wood,Enum.Material.Wood)
 arrow(g,w(-37,4.8,-446),'ЗАПАДНАЯ АЛЛЕЯ',true,6.3)
 arrow(g,w(-37,3.85,-446),'ВОСТОЧНАЯ АЛЛЕЯ',false,6.3)
 arrow(g,w(-37,2.9,-446),'ВХОД • АВТОМАТЫ',false,6.3)
 lowLight(g,w(-37,5.7,-445.6))
 -- Existing viewpoint labels get a matching slim frame and stone feet.
 local polish=garden:FindFirstChild('OasisPolish')
 if polish then for _,name in {'WestQuarryView','RearQuarryView'}do
  local model=polish:FindFirstChild(name);local b=model and model:FindFirstChild('QuarryViewSign')
  if b then
   for _,y in {-.51,.51}do part(g,'ViewSignFrame',V(7.85,.1,.2),b.CFrame*CF(0,y,0),P.wood,Enum.Material.Wood)end
   for _,x in {-3.88,3.88}do part(g,'ViewSignFrame',V(.1,1.1,.2),b.CFrame*CF(x,0,0),P.wood,Enum.Material.Wood)end
  end
 end end
 g.Parent=garden;garden:SetAttribute('RemasterWayfindingVersion',1)
end
function Landscape.Station(station)
 local existing=station:FindFirstChild('RemasterStationDetails');if existing then return end
 local work=station:FindFirstChild('QuarryWorksiteV14');local board=work and work:FindFirstChild('SiteInformation')
 local g=Instance.new('Model');g.Name='RemasterStationDetails';g:SetAttribute('VisualOnly',true)
 if board then
  board:SetAttribute('RemasterOriginalSize',board.Size);board.Size=V(7.8,3.5,.2);board.Color=P.green;board.Material=Enum.Material.Wood
  for _,gui in board:GetChildren()do if gui:IsA('SurfaceGui')then gui.Enabled=false end end
  local gui=Instance.new('SurfaceGui');gui.Name='RemasterSiteGuide';gui.Face=Enum.NormalId.Back;gui.CanvasSize=Vector2.new(1100,510);gui.LightInfluence=.7;gui.MaxDistance=120;gui.Parent=board
  local function line(message,pos,size,color)
   local t=Instance.new('TextLabel');t.Text=message;t.BackgroundTransparency=1;t.Position=pos;t.Size=size;t.TextScaled=true;t.TextColor3=color or P.cream;t.Font=Enum.Font.GothamMedium;t.Parent=gui
  end
  line('DIG THE MOUNTAIN',UDim2.fromScale(.05,.05),UDim2.fromScale(.9,.12),P.brass)
  line('ВАШ МАРШРУТ ПО КАРЬЕРУ',UDim2.fromScale(.05,.21),UDim2.fromScale(.9,.12))
  for i,s in ipairs({'01  КОПАЙТЕ ПЕСОК У ГОРЫ','02  ПРОДАВАЙТЕ У АВТОМАТА','03  УЛУЧШАЙТЕ СНАРЯЖЕНИЕ'})do line(s,UDim2.fromScale(.08,.39+(i-1)*.16),UDim2.fromScale(.84,.11))end
  for _,y in {-1.88,1.88}do part(g,'GuideTimberFrame',V(8.15,.15,.28),board.CFrame*CF(0,y,0),P.wood,Enum.Material.Wood)end
  for _,x in {-4,4}do part(g,'GuideTimberFrame',V(.15,3.9,.28),board.CFrame*CF(x,0,0),P.wood,Enum.Material.Wood)end
  lowLight(g,board.CFrame*CF(0,2.2,.4))
 end
 -- Keep all original machine surfaces and prompts; only outline existing headings.
 for _,spec in {{'SandExchangeV7','Header'},{'UpgradeMachine','HeaderPlate'}}do
  local m=station:FindFirstChild(spec[1]);local b=m and m:FindFirstChild(spec[2],true)
  if b then
   local width=b.Size.X
   part(g,'MachineHeadingBrassEdge',V(width,.035,.03),b.CFrame*CF(0,-b.Size.Y/2-.04,.06),P.brass,Enum.Material.Metal)
  end
 end
 g.Parent=station
end
return Landscape