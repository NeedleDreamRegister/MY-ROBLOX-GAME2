-- Decorative additions to the existing quarry garden. No terrain or gameplay edits.
local Oasis = {}
local V, CF = Vector3.new, CFrame.new
local C = {
 stone=Color3.fromRGB(211,199,166), cream=Color3.fromRGB(240,226,188),
 wood=Color3.fromRGB(144,104,67), dark=Color3.fromRGB(81,67,49),
 green=Color3.fromRGB(62,95,72), brass=Color3.fromRGB(191,150,83),
 leaf=Color3.fromRGB(110,142,94), sage=Color3.fromRGB(147,163,117),
 soil=Color3.fromRGB(126,108,74), glow=Color3.fromRGB(255,222,164),
}
local function part(parent,name,size,cf,color,material,collide)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf
 p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=false;p.CanQuery=collide==true
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.CastShadow=material==Enum.Material.Wood or collide==true
 p:SetAttribute('OasisDecor',true);p.Parent=parent;return p
end
local function beam(g,name,a,b,w,h,color,mat)
 return part(g,name,V(w,h,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,mat)
end
local function label(board,text,face)
 local gui=Instance.new('SurfaceGui');gui.Name='OasisLettering';gui.Face=face or Enum.NormalId.Front
 gui.CanvasSize=Vector2.new(1000,math.max(160,math.floor(1000*board.Size.Y/board.Size.X)))
 gui.LightInfluence=.65;gui.MaxDistance=150;gui.Parent=board
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(.93,.84);t.Position=UDim2.fromScale(.035,.08)
 t.BackgroundTransparency=1;t.Text=text;t.Font=Enum.Font.GothamMedium;t.TextScaled=true
 t.TextColor3=C.cream;t.Parent=gui;return gui
end
local function sign(g,name,size,cf,text)
 local b=part(g,name,size,cf,C.green,Enum.Material.Wood)
 label(b,text);label(b,text,Enum.NormalId.Back);return b
end
local function light(p,range,brightness)
 local l=Instance.new('PointLight');l.Name='WarmGardenLight';l.Color=C.glow
 l.Range=range;l.Brightness=brightness;l.Shadows=false;l.Parent=p;return l
end
local function lantern(g,cf,height,lit)
 part(g,'LanternStoneFoot',V(.8,.25,.8),cf*CF(0,.125,0),C.stone,Enum.Material.Limestone)
 part(g,'BronzeLanternPost',V(.16,height-.6,.16),cf*CF(0,(height-.6)/2+.25,0),C.dark,Enum.Material.Metal)
 local body=part(g,'HoneyGlass',V(.48,.65,.48),cf*CF(0,height,0),C.glow,Enum.Material.Neon)
 part(g,'LanternCrown',V(.8,.12,.8),cf*CF(0,height+.4,0),C.dark,Enum.Material.Metal)
 part(g,'LanternSill',V(.65,.1,.65),cf*CF(0,height-.38,0),C.brass,Enum.Material.Metal)
 for _,x in {-1,1}do for _,z in {-1,1}do
  part(g,'LanternFrame',V(.045,.68,.045),cf*CF(x*.25,height,z*.25),C.dark,Enum.Material.Metal)
 end end
 if lit~=false then light(body,12,.42)end
end
local function stone(g,cf,scale)
 local p=part(g,'TumbledDesertStone',V(1.6,.6,1.15)*scale,cf*CF(0,.25*scale,0)*CFrame.Angles(.1,.6,.08),C.stone,Enum.Material.Limestone)
 local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
end
local function shrub(g,cf,scale)
 local asset=game.ReplicatedStorage.QuarryGardenAssets.FacetedCanopy
 for i=1,3 do
  local p=asset:Clone();p.Name='SageCushion';p.Size=V(1.2+i*.16,.9+i*.12,1.3)*scale
  p.CFrame=cf*CF((i-2)*.65*scale,.52*scale,math.sin(i)*.25)*CFrame.Angles(0,i,0)
  p.Color=i==2 and C.leaf or C.sage;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p:SetAttribute('OasisDecor',true);p.Parent=g
 end
end
local function flower(g,cf,shade,scale)
 local p=part(g,'WildflowerStem',V(.045,.62,.045)*scale,cf*CF(0,.31*scale,0),C.leaf)
 local asset=game.ReplicatedStorage.QuarryGardenAssets.GardenPetalRosette
 local petals=asset:Clone();petals.Name='DesertBloom';petals.Size=asset.Size*.85*scale
 petals.CFrame=cf*CF(0,.66*scale,0)*CFrame.Angles(0,scale,0);petals.Color=shade
 petals.Anchored=true;petals.CanCollide=false;petals.CanTouch=false;petals.CanQuery=false;petals.CastShadow=false
 petals:SetAttribute('OasisDecor',true);petals.Parent=g
 local heart=part(g,'PollenHeart',V(.18,.13,.18)*scale,cf*CF(0,.72*scale,0),C.brass);heart.Shape=Enum.PartType.Ball
end
local function agave(g,cf,scale)
 for i=1,9 do
  local angle=i*math.pi*2/9
  local start=cf*CF(math.cos(angle)*.12,.12,math.sin(angle)*.12)
  local tip=cf*CF(math.cos(angle)*1.25*scale,(i%3==0 and 1.6 or .8)*scale,math.sin(angle)*1.25*scale)
  local leaf=Instance.new('WedgePart');leaf.Name='AgaveLeaf';leaf.Size=V(.09,.4*scale,(tip.Position-start.Position).Magnitude)
  leaf.CFrame=CFrame.lookAt((tip.Position+start.Position)/2,tip.Position)*CFrame.Angles(0,0,math.pi)
  leaf.Color=i%2==0 and C.sage or C.leaf;leaf.Material=Enum.Material.SmoothPlastic
  leaf.Anchored=true;leaf.CanCollide=false;leaf.CanTouch=false;leaf.CanQuery=false;leaf.CastShadow=false
  leaf:SetAttribute('OasisDecor',true);leaf.Parent=g
 end
end
local colors={Color3.fromRGB(231,190,100),Color3.fromRGB(215,159,132),Color3.fromRGB(190,175,211),C.cream}
local function planter(g,cf,width,depth)
 part(g,'LimestonePlanter',V(width,.55,depth),cf*CF(0,.275,0),C.stone,Enum.Material.Limestone)
 part(g,'SunkenSoil',V(width-.35,.07,depth-.35),cf*CF(0,.57,0),C.soil,Enum.Material.Ground)
 for i=1,3 do shrub(g,cf*CF((i-2)*width*.25,.6,0),.5)end
 for i=1,5 do flower(g,cf*CF((i-3)*width*.16,.6,depth*.25),colors[i%4+1],.75)end
end
local function bench(g,cf,length)
 for i=1,4 do part(g,'CedarSeatSlat',V(length,.13,.29),cf*CF(0,1.18,(i-2.5)*.34),C.wood,Enum.Material.Wood)end
 for _,side in {-1,1}do
  part(g,'BenchStoneLeg',V(.45,.95,1.55),cf*CF(side*(length/2-.6),.58,0),C.stone,Enum.Material.Limestone)
  part(g,'BenchBackSupport',V(.13,1.4,.13),cf*CF(side*(length/2-.6),1.4,.6),C.dark,Enum.Material.Metal)
 end
 for i=1,2 do part(g,'CedarBackSlat',V(length,.28,.12),cf*CF(0,1.65+(i-1)*.36,.65),C.wood,Enum.Material.Wood)end
end
function Oasis.Build(garden,offset)
 offset=offset or Vector3.zero
 local old=garden:FindFirstChild('OasisPolish')
 if old and old:GetAttribute('Ready')and old:GetAttribute('Version')==2 then return old end
 if old then old:Destroy()end -- only an incomplete build owned by this module
 local root=Instance.new('Folder');root.Name='OasisPolish';root:SetAttribute('VisualOnly',true);root:SetAttribute('Version',2);root.Parent=garden
 local function world(x,y,z)return CF(offset+V(x,y,z))end
 local function group(name,fn)
  local g=Instance.new('Model');g.Name=name;fn(g);g.Parent=root;task.wait();return g
 end
 group('EntranceStopShelter',function(g)
  -- Existing landing, safe exit and crossing stay entirely open. Shelter is behind them.
  part(g,'WaitingTerrace',V(21,.18,7),world(45,.09,68),C.stone,Enum.Material.Limestone,true)
  for i=1,13 do part(g,'TerraceJoint',V(.025,.012,6.7),world(34.5+i*1.5,.186,68),C.cream)end
  for _,x in {35.5,54.5}do for _,z in {65,71}do
   part(g,'ShelterFoot',V(.9,.4,.9),world(x,.35,z),C.stone,Enum.Material.Limestone)
   part(g,'ShelterCedarPost',V(.34,7.3,.34),world(x,4.1,z),C.wood,Enum.Material.Wood)
   for _,h in {.65,7.2}do part(g,'PostBronzeCollar',V(.41,.12,.41),world(x,h,z),C.brass,Enum.Material.Metal)end
  end end
  for _,z in {65,71}do
   beam(g,'ShelterMainBeam',V(34.8,7.65,z)+offset,V(55.2,7.65,z)+offset,.38,.38,C.dark,Enum.Material.Wood)
   for _,x in {35.5,54.5}do
    local s=x<45 and 1 or -1
    beam(g,'ShelterDiagonalBrace',V(x,6.2,z)+offset,V(x+s*1.5,7.55,z)+offset,.18,.22,C.wood,Enum.Material.Wood)
   end
  end
  for i=0,12 do part(g,'ShadeRafter',V(.2,.25,7.6),world(34.8+i*1.7,7.95,68),C.wood,Enum.Material.Wood)end
  part(g,'SandCanvasShade',V(22,.1,7.5),world(45,8.15,68),C.cream,Enum.Material.Fabric)
  for _,z in {64.2,71.8}do part(g,'CedarRoofFascia',V(22,.38,.16),world(45,8,z),C.dark,Enum.Material.Wood)end
  sign(g,'ShelterName',V(10,.8,.12),world(45,7.3,64.1),'САД КАРЬЕРА  •  ЭЛЕКТРОКАР')
  bench(g,world(45,.18,70),7)
  for _,x in {32,58}do planter(g,world(x,0,69),3.2,4.5)end
  for _,x in {37.2,52.8}do
   part(g,'ShelterPendant',V(.04,.45,.04),world(x,7.6,68),C.brass,Enum.Material.Metal)
   local p=part(g,'ShelterWarmLight',V(.4,.55,.4),world(x,7.1,68),C.glow,Enum.Material.Neon);light(p,12,.4)
   part(g,'PendantCrown',V(.65,.12,.65),world(x,7.43,68),C.dark,Enum.Material.Metal)
  end
  part(g,'StopPole',V(.17,6.8,.17),world(60,3.4,62),C.dark,Enum.Material.Metal)
  sign(g,'StopName',V(4.8,1.15,.15),world(60,6.1,62),'ОСТАНОВКА')
  sign(g,'RouteInformation',V(4.7,2,.15),world(60,4.2,62),'КРУГ ВОКРУГ КАРЬЕРА\nПосадка — когда электрокар стоит\nВыход — на свободную площадку')
  stone(g,world(63,0,68),1);agave(g,world(61.5,0,70.5),.65)
 end)
 local function deck(name,cf,width,depth)
  return group(name,function(g)
   part(g,'FlushStoneFoundation',V(width+.4,.18,depth+.4),cf*CF(0,.09,0),C.stone,Enum.Material.Limestone,true)
   for i=1,math.floor(depth/.5)do
    part(g,'CedarDeckBoard',V(width,.13,.46),cf*CF(0,.245,-depth/2+(i-.5)*.5),i%3==0 and C.dark or C.wood,Enum.Material.Wood,true)
   end
   -- Open central entrance at the back; rails never fence off the approach.
   for _,x in {-width/2,width/2}do
    for _,z in {-depth/2,depth/2}do part(g,'ViewRailPost',V(.2,2.25,.2),cf*CF(x,1.4,z),C.dark,Enum.Material.Wood)end
    for _,h in {1.1,2.25}do beam(g,'ViewRail', (cf*CF(x,h,-depth/2)).Position,(cf*CF(x,h,depth/2)).Position,.12,.14,C.wood,Enum.Material.Wood)end
   end
   sign(g,'QuarryViewSign',V(7.5,.9,.15),cf*CF(0,2.75,-depth/2+.3),'ЛУЧШИЙ ВИД НА КАРЬЕР')
   for _,x in {-width/2,width/2}do lantern(g,cf*CF(x,0,depth/2),2.8)end
   for _,side in {-1,1}do
    shrub(g,cf*CF(side*(width/2+1.7),0,-1),.75)
    for i=1,4 do flower(g,cf*CF(side*(width/2+1.8),0,1+i*.7),colors[i],.9)end
    stone(g,cf*CF(side*(width/2+2.4),0,-depth/2),.8)
   end
   local approach=part(g,'ViewApproach',V(4,.12,7.7),cf*CF(0,.15,depth/2+3.7),C.stone,Enum.Material.Limestone,true)
   for i=1,5 do part(g,'ApproachInset',V(3.7,.015,.12),approach.CFrame*CF(0,.07,(i-3)*1.4),C.cream)end
   g:SetAttribute('QuarryViewpoint',true)
  end)
 end
 -- Local -Z faces the mountain; back of each deck joins the existing footway.
 deck('WestQuarryView',world(-213,0,-210)*CFrame.Angles(0,-math.pi/2,0),12,8)
 deck('RearQuarryView',world(55,0,-397)*CFrame.Angles(0,math.pi,0),12,8)
 group('EntrancePickaxeMonument',function(g)
  local function monumentWorld(x,y,z)return world(x+24,y,z+3)end
  local cf=monumentWorld(-30,0,14)
  part(g,'MonumentLimestoneStep',V(11,.25,5),cf*CF(0,.125,0),C.stone,Enum.Material.Limestone)
  part(g,'MonumentPlinth',V(7,1.1,2.8),cf*CF(0,.8,0),C.cream,Enum.Material.Limestone)
  part(g,'PlinthBronzeInlay',V(7.04,.07,2.84),cf*CF(0,1.25,0),C.brass,Enum.Material.Metal)
  local pick=cf*CF(0,5.2,0)*CFrame.Angles(0,0,-.42)
  part(g,'PickaxeSculptureHandle',V(.32,6.5,.32),pick,C.wood,Enum.Material.Wood)
  part(g,'PickaxeGrip',V(.4,1.25,.4),pick*CF(0,-2.25,0),C.dark,Enum.Material.Wood)
  local head=pick*CF(0,2.85,0)
  part(g,'PickaxeBronzeSocket',V(.65,.65,.6),head,C.brass,Enum.Material.Metal)
  for _,side in {-1,1}do
   beam(g,'ForgedPickaxeBlade',(head*CF(side*.2,0,0)).Position,(head*CF(side*2.25,-.38,0)).Position,.25,.42,C.green,Enum.Material.Metal)
   beam(g,'ForgedPickaxeTip',(head*CF(side*2.25,-.38,0)).Position,(head*CF(side*3.15,-.88,0)).Position,.12,.19,C.brass,Enum.Material.Metal)
  end
  sign(g,'GardenSubtitle',V(8.5,.9,.16),monumentWorld(-30,1.85,15.2),'САД КАРЬЕРА')
  for _,x in {-37,-23}do planter(g,monumentWorld(x,0,14.5),2.8,3)end
  local glow=part(g,'MonumentFootlight',V(.8,.12,.45),monumentWorld(-30,.3,17),C.glow,Enum.Material.Neon);light(glow,11,.45)
 end)
 local identity=garden:FindFirstChild('GardenIdentity')
 if identity then
  local original=identity:GetAttribute('OasisOriginalPivot')or identity:GetPivot()
  identity:SetAttribute('OasisOriginalPivot',original)
  identity:PivotTo(CFrame.new(24,0,3)*original)
  local b=identity:FindFirstChild('QuarryGardenWelcome')
  if b then
   b:SetAttribute('OasisOriginalSize',b:GetAttribute('OasisOriginalSize')or b.Size)
   b.Color=C.green;b.Size=V(12,2,.22)
   for _,v in b:GetDescendants()do if v:IsA('TextLabel')then v.Text='DIG THE MOUNTAIN';v.TextColor3=C.cream;v.Font=Enum.Font.GothamBold end end
  end
 end
 group('BotanicalAccents',function(g)
  -- Enrich selected existing beds; no new trees and no broad lawn surfaces.
  for i,p in ipairs({{-102,-18},{-58,-8},{62,8},{103,5}})do
   local cf=world(p[1]+3,0,p[2]-1.5);agave(g,cf,.7)
   for j=1,5 do flower(g,cf*CF(math.cos(j*1.9)*1.8,0,math.sin(j*1.9)*1.4),colors[(i+j)%4+1],.85)end
  end
  for i,p in ipairs({{194,-112},{192,-236},{190,-321},{-259,-120},{-260,-300},{77,-447}})do
   local cf=world(p[1],0,p[2]);agave(g,cf,.65+i%2*.15)
   stone(g,cf*CF(1.8,0,.7),.7);stone(g,cf*CF(-1.2,0,-.6),.4)
  end
 end)
 group('PromenadeLanterns',function(g)
  local route=require(game.ServerScriptService.QuarryTransit.Route).WithOffset(offset)
  for s=90,route.TravelLength-60,140 do
   local p,n=route.RoadAt(route.DistanceAtTravel(s));local cf=CF(p+n*16)
   lantern(g,cf,4.1)
  end
 end)
 group('ReflectingPoolAccents',function(g)
  for _,p in ipairs({{-132,-23},{-120,-25}})do
   local cf=world(p[1],1.1,p[2]);stone(g,cf,.6)
   local glow=part(g,'RecessedPoolLight',V(.32,.12,.32),cf*CF(0,.3,0),C.glow,Enum.Material.Neon);light(glow,7,.25)
  end
 end)
 root:SetAttribute('Ready',true);return root
end
function Oasis.DressStation(station,offset)
 offset=offset or Vector3.zero
 local market=station:FindFirstChild('VisualMarket');if not market then return end
 if market:FindFirstChild('OasisCanopyCraft')then return end
 local g=Instance.new('Model');g.Name='OasisCanopyCraft'
 local function w(x,y,z)return CF(offset+V(x,y,z))end
 -- Retain the exact canopy footprint and all original machine/prompt locations.
 for _,p in market:GetDescendants()do if p:IsA('BasePart')then
  if p.Name=='CanvasStripe'then
   p:SetAttribute('OasisOriginalColor',p.Color)
   p.Color=p.Position.X-offset.X<0 and C.cream or (math.floor((p.Position.X-offset.X-13)/3.25)%2==0 and C.cream or C.green)
   p.Material=Enum.Material.Fabric;p.CastShadow=true
  elseif p.Name=='TimberPost'then
   p.Color=C.wood;p.Size=V(.46,p.Size.Y,.46);p.CastShadow=true
  elseif p.Name=='CanopyRail'or p.Name=='RidgeBeam'then p.Color=C.dark;p.CastShadow=true
  end
 end end
 for _,x in {13.78,38.22}do for _,z in {-28,-16}do
  part(g,'CarvedPostFoot',V(.8,.35,.8),w(x,.2,z),C.stone,Enum.Material.Limestone)
  for _,y in {.7,10.7}do part(g,'BronzePostBand',V(.53,.13,.53),w(x,y,z),C.brass,Enum.Material.Metal)end
  local side=x<26 and 1 or -1
  beam(g,'CanopyKneeBrace',V(x,9.3,z)+offset,V(x+side*1.65,10.95,z)+offset,.2,.24,C.wood,Enum.Material.Wood)
 end end
 for _,z in {-15.65,-28.35}do
  part(g,'LongCedarFascia',V(26.8,.35,.22),w(26,10.98,z),C.dark,Enum.Material.Wood)
  part(g,'BrassFasciaLine',V(26.7,.055,.04),w(26,11.15,z+.13),C.brass,Enum.Material.Metal)
  for i=0,15 do
   part(g,'CanvasValance',V(1.63,.48,.08),w(13.8+i*1.63,10.58,z),i%2==0 and C.cream or C.green,Enum.Material.Fabric)
   part(g,'ValanceHem',V(1.6,.065,.1),w(13.8+i*1.63,10.3,z),C.brass,Enum.Material.Fabric)
  end
 end
 for _,x in {13,39}do
  for _,side in {-1,1}do
   beam(g,'CanvasSeam',V(x,11,-22+side*7.2)+offset,V(x,12.72,-22)+offset,.07,.08,C.cream,Enum.Material.Fabric)
   beam(g,'TimberGable',V(x,10.9,-22+side*6)+offset,V(x,12.5,-22)+offset,.16,.2,C.wood,Enum.Material.Wood)
  end
 end
 for i=1,7 do
  local x=14+i*3
  beam(g,'StitchedCanvasSeam',V(x,11.08,-15.2)+offset,V(x,12.71,-22)+offset,.03,.035,C.brass,Enum.Material.Fabric)
  beam(g,'StitchedCanvasSeam',V(x,11.08,-28.8)+offset,V(x,12.71,-22)+offset,.03,.035,C.brass,Enum.Material.Fabric)
 end
 sign(g,'MarketFascia',V(11,1.1,.16),w(26,11.35,-15.3),'МАСТЕРСКАЯ КАРЬЕРА')
 for _,x in {22.8,29.2}do
  part(g,'HangingLanternChain',V(.04,.7,.04),w(x,10.3,-23.8),C.brass,Enum.Material.Metal)
  local p=part(g,'WorkshopAmberGlass',V(.45,.6,.45),w(x,9.7,-23.8),C.glow,Enum.Material.Neon)
  part(g,'WorkshopLanternCap',V(.7,.12,.7),w(x,10.07,-23.8),C.dark,Enum.Material.Metal);light(p,11,.32)
 end
 g:SetAttribute('VisualOnly',true);g.Parent=market
end
return Oasis