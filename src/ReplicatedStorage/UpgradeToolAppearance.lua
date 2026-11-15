local C=require(script.Parent.UpgradeConfig)
local Art={}
function Art.Build(id)
 local d=assert(C.Tool(id));local tool=Instance.new('Tool');tool.Name=d.Name;tool.ToolTip=d.Name;tool.CanBeDropped=false;tool.RequiresHandle=true
 tool:SetAttribute('SandPrototypeTool',true);tool:SetAttribute('UpgradeToolId',id);tool:SetAttribute('VisualVersion',12)
 tool:SetAttribute('TwoHanded',id=='shovel'or id=='turbo'or id=='vortex'or id=='lava')
 local metal=Color3.fromRGB(91,108,122);local dark=Color3.fromRGB(28,39,52);local gold=Color3.fromRGB(194,151,80);local glow=d.Color
 local handle=Instance.new('Part');handle.Name='Handle';handle.Size=Vector3.new(.2,.3,.2);handle.Transparency=1;handle.CanCollide=false;handle.CanTouch=false;handle.CanQuery=false;handle.Massless=true;handle.Parent=tool
 local function p(n,size,cf,color,material,shape)
  local v=Instance.new(shape=='wedge'and 'WedgePart'or 'Part');v.Name=n;v.Size=size;v.CFrame=cf;v.Color=color or metal;v.Material=material or Enum.Material.Metal
  if shape=='ball'then v.Shape=Enum.PartType.Ball elseif shape=='cylinder'then v.Shape=Enum.PartType.Cylinder end
  v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.Massless=true;v.CastShadow=material~=Enum.Material.Neon;v.Parent=tool
  local weld=Instance.new('WeldConstraint');weld.Part0=handle;weld.Part1=v;weld.Parent=v;return v
 end
 local function at(x,y,z)return CFrame.new(x,y,z)end
 local function beam(n,a,b,r,col,mat)return p(n,Vector3.new(r,r,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),col,mat)end
 local function orb(n,pos,r,col,mat)return p(n,Vector3.new(r,r,r),CFrame.new(pos),col,mat,'ball')end
 local function neon(n,size,cf,col)return p(n,size,cf,col or glow,Enum.Material.Neon)end
 local function cylinder(n,pos,length,r,col,mat)return p(n,Vector3.new(length,r,r),CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2),col,mat,'cylinder')end
 local function bolt(pos,r)return p('Rivet',Vector3.new(r,r,.065),CFrame.new(pos),gold)end
 local function shaft(wood)
  cylinder('Shaft',Vector3.new(0,-.65,0),3.15,.21,wood and Color3.fromRGB(133,87,48)or dark,wood and Enum.Material.Wood or Enum.Material.Metal)
  for _,y in {-.9,-.72,-.54,-.36,-.18,0,.18}do cylinder('GripWrap',Vector3.new(0,y,0),.105,.265,Color3.fromRGB(34,40,44),Enum.Material.Rubber)end
  for _,y in {-2.12,.92}do cylinder('Ferrule',Vector3.new(0,y,0),.28,.34,metal)end
  beam('DGripLeft',Vector3.new(-.12,.9,0),Vector3.new(-.42,1.43,0),.15,metal)
  beam('DGripRight',Vector3.new(.12,.9,0),Vector3.new(.42,1.43,0),.15,metal)
  p('CrossGrip',Vector3.new(.84,.2,.23),at(0,1.45,0),dark,Enum.Material.Rubber)
  for _,x in {-.37,.37}do orb('GripCorner',Vector3.new(x,1.41,0),.21,metal)end
 end
 local function scoop(width,col)
  p('Blade',Vector3.new(width,.16,1.5),at(0,-2.47,.36)*CFrame.Angles(math.rad(-12),0,0),col)
  p('CuttingEdge',Vector3.new(width+.08,.11,.26),at(0,-2.64,1.05),Color3.fromRGB(190,202,208))
  for _,x in {-1,1}do p('ScoopFlange',Vector3.new(.13,.38,1.43),at(x*(width/2-.04),-2.32,.35)*CFrame.Angles(0,0,-x*.25),col)end
  p('BackLip',Vector3.new(width,.25,.16),at(0,-2.3,-.37),col)
  p('Neck',Vector3.new(.43,.62,.31),at(0,-2.07,-.15)*CFrame.Angles(-.22,0,0),col)
  for _,x in {-.14,.14}do bolt(Vector3.new(x,-2.06,.025),.085)end
  for _,x in {-.35,0,.35}do p('PressedRib',Vector3.new(.06,.055,1.02),at(x*width,-2.36,.3)*CFrame.Angles(-.2,0,0),metal)end
 end
 local function ring(center,radius,segments,col,tilt)
  local base=CFrame.new(center)*(tilt or CFrame.identity)
  for i=1,segments do local a=i/segments*math.pi*2;local b=(i+1)/segments*math.pi*2;beam('Arc',base:PointToWorldSpace(Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius)),base:PointToWorldSpace(Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius)),.09,col,Enum.Material.Neon)end
 end
 local function triangle(a,b,c,col)
  local ab,ac,bc=b-a,c-a,c-b
  if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c elseif ac.Magnitude>bc.Magnitude then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  local right=ac:Cross(ab).Unit;local up=bc:Cross(right).Unit;local back=bc.Unit
  local height=math.abs(ab:Dot(up))
  p('CrystalFacet',Vector3.new(.025,height,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back),col,Enum.Material.Glass,'wedge')
  p('CrystalFacet',Vector3.new(.025,height,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back),col,Enum.Material.Glass,'wedge')
 end
 local function crystal(pos,h,col)
  local radius=.23;local top=pos+Vector3.new(.03,h*.62,-.02);local bottom=pos-Vector3.new(0,h*.38,0)
  for i=1,4 do
   local angle=(i-1)*math.pi/2+math.pi/4;local nextAngle=i*math.pi/2+math.pi/4
   local a=pos+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
   local b=pos+Vector3.new(math.cos(nextAngle)*radius,0,math.sin(nextAngle)*radius)
   local shade=col:Lerp(Color3.new(1,1,1),i*.075)
   triangle(top,a,b,shade);triangle(bottom,b,a,col:Lerp(Color3.fromRGB(42,23,84),.12))
  end
  neon('CrystalCore',Vector3.new(.055,h*.7,.055),CFrame.new(pos),col)
 end
 if id=='shovel'then shaft(true);scoop(1.55,Color3.fromRGB(125,141,151));p('MakerPlate',Vector3.new(.32,.23,.06),at(0,-1.8,.15),gold)
 elseif id=='turbo'then
  shaft(false);scoop(1.95,dark)
  for _,x in {-1,1}do p('Turbine',Vector3.new(.37,.7,.5),at(x*.78,-1.96,-.05),metal);neon('PowerCell',Vector3.new(.16,.45,.52),at(x*.78,-1.96,-.05));neon('EdgeRail',Vector3.new(.09,.09,1.3),at(x*.92,-2.18,.4));cylinder('Cap',Vector3.new(x*.78,-1.62,-.05),.1,.43,gold)end
  neon('PoweredEdge',Vector3.new(1.94,.07,.11),at(0,-2.67,1.17));neon('StatusSpine',Vector3.new(.08,1.2,.08),at(0,-1.33,.18))
 elseif id=='crystal'then
  p('Gauntlet',Vector3.new(.76,.62,.6),at(0,0,0),dark);p('PalmArmor',Vector3.new(1.5,.44,1.3),at(0,-.35,-.55),metal)
  for i=1,4 do local x=(i-2.5)*.4;orb('Knuckle',Vector3.new(x,-.38,-1.1),.34,gold);beam('Claw',Vector3.new(x,-.3,-1.05),Vector3.new(x,-.72,-1.7),.28,dark);crystal(Vector3.new(x,-.5,-1.58),.86,glow)end
  crystal(Vector3.new(0,.08,-.65),1.05,glow);beam('Thumb',Vector3.new(-.6,-.35,-.2),Vector3.new(-1,-.65,-.6),.3,metal);crystal(Vector3.new(-.94,-.65,-.65),.6,glow)
 elseif id=='vortex'then
  shaft(false);local center=Vector3.new(0,-2.25,.15);p('TurbineCasing',Vector3.new(1.6,.38,1.6),CFrame.new(center),dark);orb('EnergyHeart',center+Vector3.new(0,.1,0),.65,glow,Enum.Material.Neon)
  for i=1,3 do local angle=i*math.pi*2/3;p('CurvedVane',Vector3.new(.48,.15,1.05),CFrame.new(center)*CFrame.Angles(0,angle,0)*at(.4,.24,.45)*CFrame.Angles(.3,.4,0),metal)end
  for i=1,3 do ring(center+Vector3.new(0,.2+i*.2,0),.55+i*.15,10,glow,CFrame.Angles(.18*i,0,.1))end
 elseif id=='lava'then
  shaft(false);p('BasaltJaw',Vector3.new(1.95,.45,1.45),at(0,-2.4,.3),Color3.fromRGB(43,37,37),Enum.Material.Slate,'wedge');p('UpperJaw',Vector3.new(1.85,.27,1.3),at(0,-1.81,.2)*CFrame.Angles(.15,0,0),dark,Enum.Material.Slate,'wedge')
  for _,side in {-1,1}do orb('JawHinge',Vector3.new(side*.9,-2.1,-.26),.34,metal);neon('EmberVein',Vector3.new(.08,.4,1),at(side*.72,-2.09,.4)*CFrame.Angles(.1,0,side*.1));orb('MonsterEye',Vector3.new(side*.5,-1.65,.48),.22,glow,Enum.Material.Neon)end
  for i=1,6 do local x=(i-3.5)*.28;p('ObsidianTooth',Vector3.new(.22,.43,.34),at(x,-2.02,.92)*CFrame.Angles(math.pi,0,0),Color3.fromRGB(226,188,111),Enum.Material.Metal,'wedge')end
  neon('MoltenInterior',Vector3.new(1.35,.07,.8),at(0,-2.14,.25))
 elseif id=='gravity'then
  p('ControlBrace',Vector3.new(.6,.5,.56),at(0,0,0),dark);neon('BraceLight',Vector3.new(.48,.06,.6),at(0,.25,0))
  local center=Vector3.new(0,.15,-1.15);orb('CoreShell',center,1.25,dark);orb('Gravitation',center+Vector3.new(0,0,-.11),.86,glow,Enum.Material.Neon)
  ring(center,1,14,glow,CFrame.Angles(.4,0,.2));ring(center,1.07,14,gold,CFrame.Angles(1.4,0,-.4))
  for i=1,3 do local a=i*2*math.pi/3;orb('Satellite',center+Vector3.new(math.cos(a)*1.15,.2,math.sin(a)*1.15),.3,metal)end
 elseif id=='abyss'then
  p('WristArmor',Vector3.new(.7,.65,.6),at(0,0,0),dark);p('ShadowPalm',Vector3.new(1.5,.45,1.25),at(0,-.22,-.65),Color3.fromRGB(30,19,43),Enum.Material.Slate)
  for i=1,4 do local x=(i-2.5)*.4;local a=Vector3.new(x,-.18,-1.12);local b=Vector3.new(x,-.33,-1.72);local c=Vector3.new(x,-.65,-2.03);orb('FingerJoint',a,.3,metal);beam('FingerBone',a,b,.27,dark);orb('FingerJoint',b,.28,metal);beam('DistalClaw',b,c,.2,dark);neon('VoidTendon',Vector3.new(.065,.05,.75),at(x,-.04,-1.25));p('VoidNail',Vector3.new(.17,.45,.3),CFrame.new(c)*CFrame.Angles(.5,0,0),glow,Enum.Material.Neon,'wedge')end
  beam('Thumb',Vector3.new(-.65,-.2,-.45),Vector3.new(-1.05,-.45,-1),.3,dark);orb('PalmSeal',Vector3.new(0,.05,-.6),.47,glow,Enum.Material.Neon)
 elseif id=='reality'then
  p('RealityBrace',Vector3.new(.6,.5,.6),at(0,0,0),dark);local center=Vector3.new(0,.25,-1.15);orb('VoidCore',center,.72,Color3.fromRGB(17,21,34));local colors={Color3.fromRGB(55,218,255),Color3.fromRGB(247,99,199),Color3.fromRGB(235,195,99)}
  for i=1,3 do ring(center,.85+i*.13,12,colors[i],CFrame.Angles(i*.55,.3*i,.3*i));local a=i*2;crystal(center+Vector3.new(math.cos(a)*1.3,.55,math.sin(a)*1.3),.6,colors[i])end
  neon('Fracture',Vector3.new(.06,.8,.06),CFrame.new(center)*CFrame.Angles(0,0,.3))
 end
 local left=Instance.new('Attachment');left.Name='LeftGrip';left.Position=Vector3.new(0,.35,0);left.Parent=handle
 tool.Grip=tool:GetAttribute('TwoHanded')and CFrame.new(0,1.45,0)or CFrame.new(.2,0,0)*CFrame.Angles(math.rad(-28),0,0)
 return tool
end
return Art

