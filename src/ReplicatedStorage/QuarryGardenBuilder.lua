local Garden={}
local Assets=game:GetService('ReplicatedStorage'):WaitForChild('QuarryGardenAssets')
Garden.Palette={
 Grass=Color3.fromRGB(112,151,83),Meadow=Color3.fromRGB(133,167,97),LightGrass=Color3.fromRGB(153,181,112),
 Stone=Color3.fromRGB(194,199,179),Limestone=Color3.fromRGB(221,216,192),Rock=Color3.fromRGB(139,152,140),
 Sand=Color3.fromRGB(213,192,147),Wood=Color3.fromRGB(131,98,65),DarkWood=Color3.fromRGB(97,78,55),
 Leaf=Color3.fromRGB(103,149,81),LeafLight=Color3.fromRGB(145,179,100),Cream=Color3.fromRGB(245,229,182),
}
local P=Garden.Palette
-- Two broad promenades share the spawn court and meet behind the unchanged quarry.
local routes={
 {Name='WestPromenade',Width=14,Green=true,Points={
  Vector3.new(3,0,-8),Vector3.new(-3,0,-17),Vector3.new(-18,0,-31),Vector3.new(-55,0,-39),Vector3.new(-104,0,-39),Vector3.new(-153,0,-37),
  Vector3.new(-188,0,-25),Vector3.new(-214,0,-36),Vector3.new(-229,0,-65),Vector3.new(-229,0,-121),Vector3.new(-235,0,-192),
  Vector3.new(-229,0,-262),Vector3.new(-226,0,-335),Vector3.new(-217,0,-382),Vector3.new(-185,0,-410),Vector3.new(-128,0,-417),Vector3.new(-76,0,-425),Vector3.new(-34,0,-425)}},
 {Width=11,Points={Vector3.new(6,0,-7),Vector3.new(12,0,-12),Vector3.new(20,0,-15),Vector3.new(31,0,-15)}},
 {Name='EastPromenade',Width=14,Green=false,Points={
  Vector3.new(31,0,-15),Vector3.new(57,0,-18),Vector3.new(90,0,-18),Vector3.new(120,0,-16),Vector3.new(145,0,-15),Vector3.new(170,0,-29),
  Vector3.new(178,0,-65),Vector3.new(174,0,-125),Vector3.new(171,0,-190),Vector3.new(169,0,-251),Vector3.new(172,0,-309),Vector3.new(163,0,-359),
  Vector3.new(145,0,-389),Vector3.new(110,0,-411),Vector3.new(50,0,-418),Vector3.new(7,0,-425),Vector3.new(-34,0,-425)}},
}
local function segmentDistance(p,a,b)
 local d=b-a;local t=math.clamp((p-a):Dot(d)/math.max(.01,d:Dot(d)),0,1);return(p-a-d*t).Magnitude
end
local function inside(p,r,padding)return p.X>=r[1]-padding and p.X<=r[2]+padding and p.Z>=r[3]-padding and p.Z<=r[4]+padding end
function Garden.Build(parent,offset,options)
 options=options or{};offset=offset or Vector3.zero
 local root=Instance.new('Folder');root.Name='QuarryGarden';root:SetAttribute('VisualOnly',true);root:SetAttribute('GardenVersion',5);root.Parent=parent
 if options.OnRoot then options.OnRoot(root)end
 local rng=Random.new(8431);local low=options.LowDetail==true
 local protected=options.Protected or{-200,132,-380,-48}
 local reserve={{-8,13,-12,9},{10,42,-35,-9},{13,38,-47,-27},{127,161,-57,-29},{-53,-37,-33,-22},{-92,-73,-34,-20}}
 local count=0
 local naturalBanks,bankByGroup={},{}
 local knolls={{X=-125,Z=-20,RX=18,RZ=12,H=1.7},{X=85,Z=0,RX=18,RZ=10,H=1.5}}
 local function groundHeight(p)
  local height=0
  for _,k in knolls do local r=math.sqrt(((p.X-k.X)/k.RX)^2+((p.Z-k.Z)/k.RZ)^2)
   if r<1 then height=math.max(height,r<.5 and k.H*(1-.4*r)or k.H*1.6*(1-r))end
  end
  for _,bank in naturalBanks do if math.abs(p.X-bank.X)<bank.RX*1.1 and math.abs(p.Z-bank.Z)<bank.RZ*1.1 then
   for _,t in bank.Triangles do local a,b,c=t[1],t[2],t[3]
    local d=(b.Z-c.Z)*(a.X-c.X)+(c.X-b.X)*(a.Z-c.Z)
    if math.abs(d)>.00001 then
     local u=((b.Z-c.Z)*(p.X-c.X)+(c.X-b.X)*(p.Z-c.Z))/d
     local v=((c.Z-a.Z)*(p.X-c.X)+(a.X-c.X)*(p.Z-c.Z))/d;local w=1-u-v
     if u>=-.00001 and v>=-.00001 and w>=-.00001 then height=math.max(height,u*a.Y+v*b.Y+w*c.Y+.065)end
    end
   end
  end end
  return height
 end
 local function plantLevel(p)if p.Y<.1 then return p+Vector3.new(0,groundHeight(p),0)end;return p end
 local function part(group,class,name,size,cf,color,material,collide)
  -- Furniture is retained in source and ServerStorage for later reuse.
  if options.IncludeFurniture~=true and string.find(name,'Bench',1,true)then return end
  local v=Instance.new(class or 'Part');v.Name=name;v.Size=size;v.CFrame=CFrame.new(offset)*cf;v.Color=color;v.Material=material or Enum.Material.SmoothPlastic
  v.Anchored=true;v.CanCollide=collide==true;v.CanTouch=false;v.CanQuery=false;v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth
  v.CastShadow=collide==true or material==Enum.Material.Wood;v:SetAttribute('QuarryGardenDecor',true)
  if collide then v:SetAttribute('GardenWalkSurface',true)end
  v.Parent=group;count+=1;return v
 end
 local function chunk(name,fn)
  if name=='GardenPergola'and options.IncludeFurniture~=true then return end
  local group=Instance.new('Model');group.Name=name;fn(group);group.Parent=root
  if options.OnChunk then options.OnChunk(name,count)end
  task.wait()
 end
 local function flatTriangle(group,a,b,c,color,mat,collide,thickness)
  local ab,ac,bc=b-a,c-a,c-b
  if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c elseif ac.Magnitude>bc.Magnitude then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b;local cross=ac:Cross(ab);if cross.Magnitude<.001 then return end
  if collide and bankByGroup[group]then table.insert(bankByGroup[group].Triangles,{a,b,c})end
  local right=cross.Unit;local up=bc:Cross(right).Unit;local back=bc.Unit;local h=math.abs(ab:Dot(up))
  for _,x in {{math.abs(ab:Dot(back)),(a+b)/2,right},{math.abs(ac:Dot(back)),(a+c)/2,-right}}do
   if x[1]>.03 and h>.03 then part(group,'WedgePart','MeadowFacet',Vector3.new(thickness or .12,h,x[1]),CFrame.fromMatrix(x[2],x[3],up,x[3]:Cross(up)),color,mat,collide)end
  end
 end
 local function disk(group,center,rx,rz,color,mat,collide,seed,n)
  n=n or 10;local points={}
  for i=1,n do local a=(i-1)*math.pi*2/n;local w=1+.07*math.sin(i*1.9+(seed or 0));points[i]=center+Vector3.new(math.cos(a)*rx*w,0,math.sin(a)*rz*w)end
  for i=1,n do flatTriangle(group,center,points[i],points[i%n+1],color:Lerp(P.LightGrass,(i%3)*.025),mat,collide)end
  return points
 end
 local function safe(p,radius)
  radius=radius or 0
  if inside(p,protected,radius)then return false end
  for _,box in reserve do if inside(p,box,radius)then return false end end
  local q=Vector3.new(p.X,0,p.Z)
  for _,route in routes do for i=1,#route.Points-1 do if segmentDistance(q,route.Points[i],route.Points[i+1])<route.Width/2+radius+2 then return false end end end
  if segmentDistance(q,Vector3.new(-18,0,-65),Vector3.new(15.5,0,-22))<7+radius then return false end
  return true
 end
 local function beam(group,name,a,b,width,color,mat)
  return part(group,'Part',name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,mat)
 end
 local function rock(group,pos,size,shade,collide)
  local v=part(group,'Part','WeatheredLimestone',size,CFrame.new(pos)*CFrame.Angles(rng:NextNumber(-.1,.1),rng:NextNumber(-3,3),rng:NextNumber(-.12,.12)),shade or P.Rock,Enum.Material.Limestone,collide)
  local cap=part(group,'WedgePart','ChiseledFace',Vector3.new(size.X*.95,size.Y*.36,size.Z*.96),CFrame.new(pos+Vector3.new(0,size.Y*.64,0))*CFrame.Angles(0,rng:NextNumber(-3,3),0),P.Stone,Enum.Material.Limestone,false)
  return v
 end
 local function tree(group,pos,scale,yaw)
  pos=plantLevel(pos)
  if not safe(pos,6.5*scale)then return end
  local model=Assets.GardenMaple:Clone();model.Name='GardenMaple';model:SetAttribute('GardenTree',true);model:ScaleTo(scale);model:PivotTo(CFrame.new(offset+pos)*CFrame.Angles(0,yaw or 0,0))
  local leafShades={Color3.fromRGB(94,140,88),Color3.fromRGB(119,158,93),Color3.fromRGB(143,170,109)}
  local leafIndex=0
  for _,v in model:GetDescendants()do if v:IsA('BasePart')then
   v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.CastShadow=not low or v.Name=='trunk_geom'
   if v.Name=='FacetedCanopy'then leafIndex+=1;v.Color=leafShades[(leafIndex+math.floor((yaw or 0)*2))%3+1]end
   v:SetAttribute('QuarryGardenDecor',true);count+=1
  end end
  model.Parent=group
 end
 local function foliage(group,pos,size,color,yaw)
  local v=Assets.FacetedCanopy:Clone();v.Name='GardenFoliage';v.Size=size;v.CFrame=CFrame.new(offset+pos)*CFrame.Angles(0,yaw or 0,0)
  v.Color=color;v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.CastShadow=false;v:SetAttribute('QuarryGardenDecor',true);v.Parent=group;count+=1;return v
 end
 local function shrub(group,pos,scale)
  pos=plantLevel(pos)
  if not safe(pos,1.7*scale)then return end
  foliage(group,pos+Vector3.new(-.45,.64,0)*scale,Vector3.new(2.1,1.65,1.85)*scale,Color3.fromRGB(95,139,89),scale*2)
  foliage(group,pos+Vector3.new(.57,.76,.16)*scale,Vector3.new(1.8,1.9,1.8)*scale,Color3.fromRGB(131,163,100),scale*3)
 end
 local function grass(group,pos,scale)
  pos=plantLevel(pos)
  if not safe(pos,.7*scale)then return end
  for i=1,(low and 2 or 3)do
   part(group,'WedgePart','GrassBlade',Vector3.new(.1,.7+i*.12,.32)*scale,CFrame.new(pos+Vector3.new((i-2)*.19*scale,.35*scale,0))*CFrame.Angles(-.15+i*.08,i*1.7,(i-2)*.22),i==2 and P.LightGrass or P.Grass)
  end
 end
 local flowerColors={Color3.fromRGB(243,207,102),Color3.fromRGB(233,171,149),Color3.fromRGB(202,190,229),Color3.fromRGB(246,238,209)}
 local function flower(group,pos,shade,scale)
  pos=plantLevel(pos)
  if not safe(pos,.8*scale)then return end
  part(group,'Part','FlowerStem',Vector3.new(.065,.85,.065)*scale,CFrame.new(pos+Vector3.new(0,.425*scale,0)),P.Leaf)
  for _,side in {-1,1}do
   part(group,'WedgePart','FlowerLeaf',Vector3.new(.08,.18,.37)*scale,CFrame.new(pos+Vector3.new(side*.12,.39*scale,0))*CFrame.Angles(0,side*math.pi/2,.25*side),Color3.fromRGB(98,143,91))
  end
  local bloom=Assets.GardenPetalRosette:Clone();bloom.Name='FlowerPetals';bloom.Size=Assets.GardenPetalRosette.Size*scale;bloom.CFrame=CFrame.new(offset+pos+Vector3.new(0,.85*scale,0))*CFrame.Angles(0,scale,0);bloom.Color=shade;bloom.Anchored=true;bloom.CanCollide=false;bloom.CanQuery=false;bloom.CanTouch=false;bloom.CastShadow=false;bloom.Parent=group;count+=1
  local v=part(group,'Part','FlowerHeart',Vector3.new(.26,.18,.26)*scale,CFrame.new(pos+Vector3.new(0,.93*scale,0)),Color3.fromRGB(235,187,76));v.Shape=Enum.PartType.Ball
 end
 local function transitionPatch(group,center,outline)
  -- Opaque, non-overlapping bands blend the garden into the unchanged sandy ground.
  local rings={}
  for j,f in {1,1.045,1.105,1.17}do
   rings[j]={};for i,p in outline do rings[j][i]=center+(p-center)*Vector3.new(f,0,f)+Vector3.new(0,.047-(j-1)*.007,0)end
  end
  local cols={Color3.fromRGB(153,165,102),Color3.fromRGB(185,179,125),Color3.fromRGB(214,195,151)}
  for i=1,#outline do local k=i%#outline+1
   flatTriangle(group,center+Vector3.new(0,.047,0),rings[1][i],rings[1][k],P.Grass,Enum.Material.Grass,false,.024)
   for j=1,3 do
    local mat=j==1 and Enum.Material.Grass or j==2 and Enum.Material.Ground or Enum.Material.Sand
    flatTriangle(group,rings[j][i],rings[j+1][i],rings[j+1][k],cols[j],mat,false,.024)
    flatTriangle(group,rings[j][i],rings[j+1][k],rings[j][k],cols[j],mat,false,.024)
   end
  end
 end
 chunk('CampGardenTransition',function(g)
  local outline={};for _,p in {{-178,-32},{-158,-49},{-126,-42},{-100,-46},{-70,-42},{-45,-43},{-18,-48},{9,-43},{37,-43},{62,-38},{88,-42},{113,-34},{142,-36},{171,-22},{179,-1},{166,17},{133,24},{99,19},{72,24},{45,21},{19,19},{-10,24},{-41,18},{-74,24},{-111,20},{-146,17},{-172,4}}do table.insert(outline,Vector3.new(p[1],0,p[2]))end
  transitionPatch(g,Vector3.new(-1,0,-10),outline)
 end)
 chunk('LawnKnolls',function(g)
  for _,k in knolls do
   local n=12;local inner,outer={},{}
   for i=1,n do local a=(i-1)*math.pi*2/n;inner[i]=Vector3.new(k.X+math.cos(a)*k.RX*.5,k.H*.8,k.Z+math.sin(a)*k.RZ*.5);outer[i]=Vector3.new(k.X+math.cos(a)*k.RX,-.08,k.Z+math.sin(a)*k.RZ)end
   local center=Vector3.new(k.X,k.H,k.Z)
   for i=1,n do local j=i%n+1
    flatTriangle(g,center,inner[i],inner[j],k.Dry and Color3.fromRGB(207,189,145)or P.Meadow,k.Dry and Enum.Material.Sand or Enum.Material.Grass,true)
    flatTriangle(g,inner[i],outer[i],outer[j],k.Dry and Color3.fromRGB(216,196,151)or P.Grass,k.Dry and Enum.Material.Sand or Enum.Material.Grass,true)
    flatTriangle(g,inner[i],outer[j],inner[j],k.Dry and Color3.fromRGB(210,192,147)or P.Grass:Lerp(P.Meadow,.35),k.Dry and Enum.Material.Sand or Enum.Material.Grass,true)
   end
  end
 end)
 chunk('GardenReflectingPool',function(g)
  local p=Vector3.new(-125,1.75,-20)
  local bed=part(g,'Part','PondStoneBasin',Vector3.new(.52,11.3,8.5),CFrame.new(p-Vector3.new(0,.29,0))*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(102,125,119),Enum.Material.Rock,false);bed.Shape=Enum.PartType.Cylinder
  local water=part(g,'Part','StillGardenWater',Vector3.new(.11,10.3,7.4),CFrame.new(p)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(93,157,165),Enum.Material.Glass,false)
  water.Shape=Enum.PartType.Cylinder;water.Transparency=.12;water.Reflectance=.12;water.CastShadow=false
  for i=1,3 do
   local v=Assets.GardenWaterRipple:Clone();v.Name='GardenWaterRipple';v.CFrame=CFrame.new(p+Vector3.new((i-2)*1.2,.075,math.sin(i)*.65))*CFrame.Angles(0,0,math.pi/2);v.Size=Vector3.new(.025,1.5,1.5);v:SetAttribute('RipplePhase',i/3);v.Parent=g;count+=1
  end
  for i=1,16 do local a=i*math.pi/8;rock(g,p+Vector3.new(math.cos(a)*5.7,-.1,math.sin(a)*4.2),Vector3.new(1.6,.75,1.3),i%3==0 and Color3.fromRGB(137,157,124)or P.Stone,false)end
  for i=1,3 do
   local pad=part(g,'Part','WaterLilyLeaf',Vector3.new(.055,.9,.85),CFrame.new(p+Vector3.new(-2+i*1.6,.09,-.6+math.sin(i)*1.3))*CFrame.Angles(0,i,math.pi/2),Color3.fromRGB(100,143,99));pad.Shape=Enum.PartType.Cylinder
  end
  for i=1,7 do local a=i*.7;local pos=Vector3.new(-125+math.cos(a)*7.2,0,-20+math.sin(a)*5.7);grass(g,pos,1.5);if i%2==0 then shrub(g,pos+Vector3.new(.4,0,1),.7)end end
  for i=1,10 do flower(g,Vector3.new(-134+rng:NextNumber()*8,0,-12+rng:NextNumber(-1,1)),flowerColors[i%4+1],1+rng:NextNumber()*.3)end
 end)
 chunk('GardenPergola',function(g)
  local center=Vector3.new(-104,0,-1)
  if not safe(center,6)then return end
  part(g,'Part','PergolaStoneFloor',Vector3.new(11,.08,8),CFrame.new(center+Vector3.new(0,.11,0)),P.Limestone,Enum.Material.Limestone)
  for _,x in {-4.5,4.5}do for _,z in {-3,3}do
   part(g,'Part','PergolaFoot',Vector3.new(.95,.5,.95),CFrame.new(center+Vector3.new(x,.25,z)),P.Stone,Enum.Material.Limestone)
   part(g,'Part','PergolaPost',Vector3.new(.36,6.7,.36),CFrame.new(center+Vector3.new(x,3.6,z)),P.Wood,Enum.Material.Wood)
  end end
  for _,z in {-3,3}do beam(g,'PergolaMainBeam',center+Vector3.new(-5.2,6.7,z),center+Vector3.new(5.2,6.7,z),.3,P.DarkWood,Enum.Material.Wood)end
  for i=1,7 do local x=-4.8+(i-1)*1.6;beam(g,'PergolaRafter',center+Vector3.new(x,7,-3.8),center+Vector3.new(x,7,3.8),.2,P.Wood,Enum.Material.Wood)end
  for i=1,6 do
   local pos=center+Vector3.new(-4.2+(i-1)*1.65,7.12,(i%2==0 and 2.6 or -2.6))
   foliage(g,pos,Vector3.new(2.6,.65,1.65),i%2==0 and P.Leaf or P.LeafLight,i)
  end
  for _,x in {-4.5,4.5}do for i=1,3 do foliage(g,center+Vector3.new(x,6.8-i*.8,3),Vector3.new(.9,1.1,.7),P.Leaf,i)end end
  for i=1,4 do part(g,'Part','PergolaBenchSeat',Vector3.new(5.5,.15,.35),CFrame.new(center+Vector3.new(0,1.05,(i-2.5)*.4+.8)),P.Wood,Enum.Material.Wood)end
  part(g,'Part','PergolaBenchBack',Vector3.new(5.5,.75,.16),CFrame.new(center+Vector3.new(0,1.7,1.65)),P.Wood,Enum.Material.Wood)
  for _,side in {-1,1}do part(g,'Part','PergolaBenchLeg',Vector3.new(.55,.9,1.65),CFrame.new(center+Vector3.new(side*2,.58,.8)),P.Stone,Enum.Material.Limestone)end
  for i=1,6 do beam(g,'PergolaTrellis',center+Vector3.new(-3.2+(i-1)*1.28,2.2,3),center+Vector3.new(-3.2+(i-1)*1.28,5.8,3),.09,P.Wood,Enum.Material.Wood)end
  for i=1,4 do foliage(g,center+Vector3.new(-3.3+(i-1)*2.2,3.2+(i%2)*1.3,3),Vector3.new(1.6,1.4,.6),Color3.fromRGB(116,153,98),i)end
  for i=1,6 do
   local p=Vector3.new(-117+(i-1)*1.8,0,-9+(i-1)*1.3)
   if safe(p,1.2)then part(g,'Part','GardenSteppingStone',Vector3.new(1.5,.08,1.1),CFrame.new(plantLevel(p)+Vector3.new(0,.13,0))*CFrame.Angles(0,.2*math.sin(i),0),P.Limestone,Enum.Material.Limestone)end
  end
  for i=1,5 do flower(g,center+Vector3.new(-5.7,0,(i-3)*1.25),Color3.fromRGB(193,175,221),1.05)end
 end)
 -- Ground-level ribbons use clipped triangles: no Terrain edits or new hills.
 local function catmull(a,b,c,d,t)
  return .5*((b*2)+(c-a)*t+(a*2-b*5+c*4-d)*(t*t)+(-a+b*3-c*3+d)*(t*t*t))
 end
 local function sampleRoute(route)
  local pts=route.Points;local samples={};local distance=0
  for i=1,#pts-1 do local steps=math.max(2,math.ceil((pts[i+1]-pts[i]).Magnitude/8))
   for j=0,steps-1 do table.insert(samples,catmull(pts[math.max(1,i-1)],pts[i],pts[i+1],pts[math.min(#pts,i+2)],j/steps))end
  end
  table.insert(samples,pts[#pts]);local result={}
  for i,p in samples do
   local before=samples[math.max(1,i-1)];local after=samples[math.min(#samples,i+1)]
   local d=(after-before).Unit;local n=Vector3.new(-d.Z,0,d.X)
   if i==#samples then n=route.Green and Vector3.new(0,0,1)or Vector3.new(0,0,-1)end
   if i>1 then distance+=(p-samples[i-1]).Magnitude end
   result[i]={P=p,N=n,D=distance}
  end
  route.Samples=result;route.Length=distance;return result
 end
 local function clip(poly,axis,bound,less)
  local result={}
  for i,a in poly do local b=poly[i%#poly+1];local av=axis==1 and a.X or a.Z;local bv=axis==1 and b.X or b.Z
   local ai=less and av<=bound or not less and av>=bound;local bi=less and bv<=bound or not less and bv>=bound
   if ai then table.insert(result,a)end
   if ai~=bi and math.abs(bv-av)>.00001 then table.insert(result,a:Lerp(b,(bound-av)/(bv-av)))end
  end
  return result
 end
 local function clippedTriangle(g,a,b,c,color,mat)
  local remaining={a,b,c};local outside={}
  -- Remove the complete protected mining rectangle plus a four-stud visual buffer.
  for _,s in {{1,protected[1]-4,false},{1,protected[2]+4,true},{2,protected[3]-4,false},{2,protected[4]+4,true}}do
   if #remaining<3 then break end
   local piece=clip(remaining,s[1],s[2],not s[3]);if #piece>=3 then table.insert(outside,piece)end
   remaining=clip(remaining,s[1],s[2],s[3])
  end
  for _,poly in outside do for i=2,#poly-1 do flatTriangle(g,poly[1],poly[i],poly[i+1],color,mat,false,.024)end end
 end
 local function strip(g,a,b,c,d,color,mat,clipped)
  if clipped then clippedTriangle(g,a,b,c,color,mat);clippedTriangle(g,a,c,d,color,mat)
  else flatTriangle(g,a,b,c,color,mat,false,.035);flatTriangle(g,a,c,d,color,mat,false,.035)end
 end
 for _,route in {routes[1],routes[3]}do
  local samples=sampleRoute(route)
  chunk(route.Name,function(g)
   g:SetAttribute('Promenade',true);g:SetAttribute('Width',route.Width);g:SetAttribute('Length',route.Length)
   g:SetAttribute('Start',offset+samples[1].P);g:SetAttribute('Finish',offset+samples[#samples].P)
   for i=1,#samples-1 do local a,b=samples[i],samples[i+1];local y=Vector3.new(0,.17,0)
    strip(g,a.P+a.N*7+y,a.P-a.N*7+y,b.P-b.N*7+y,b.P+b.N*7+y,route.Green and Color3.fromRGB(218,204,169)or Color3.fromRGB(224,207,170),Enum.Material.Ground,false)
    if i%3==0 then for _,side in {-1,1}do
     beam(g,'LowLimestonePathEdge',a.P+a.N*(side*7)+Vector3.new(0,.19,0),b.P+b.N*(side*7)+Vector3.new(0,.19,0),.16,P.Limestone,Enum.Material.Limestone)
    end end
   end
  end)
  chunk(route.Name..'Meadow',function(g)
   g:SetAttribute('FlatParkGround',true)
   for i=1,#samples-1,2 do local a,b=samples[i],samples[math.min(i+2,#samples)]
    -- Existing spawn lawn stays intact; the new planting begins at its outer edge.
    if math.min(a.P.Z,b.P.Z)>-49 then continue end
    local function width(s)
     local w=route.Green and 24+4*math.sin(s.D*.035)+2*math.sin(s.D*.11)or 17+2*math.sin(s.D*.04)
     local join=math.clamp((s.D-route.Length+65)/65,0,1);return w+(24-w)*join
    end
    local wa,wb=width(a),width(b)
    local green=route.Green and Color3.fromRGB(130,159,91)or Color3.fromRGB(169,165,109)
    if not route.Green then green=green:Lerp(Color3.fromRGB(130,159,91),math.clamp((a.D-route.Length+140)/140,0,1))end
    local h=Vector3.new(0,.047,0)
    strip(g,a.P+a.N*wa+h,a.P-a.N*wa+h,b.P-b.N*wb+h,b.P+b.N*wb+h,green,Enum.Material.Grass,true)
    for j,edge in {3,6.5}do local inner=j==1 and 0 or 3
     local y=Vector3.new(0,.039-(j-1)*.009,0);local color=j==1 and Color3.fromRGB(181,177,120)or Color3.fromRGB(214,195,151)
     for _,side in {-1,1}do strip(g,a.P+a.N*(side*(wa+inner))+y,a.P+a.N*(side*(wa+edge))+y,b.P+b.N*(side*(wb+edge))+y,b.P+b.N*(side*(wb+inner))+y,color,j==1 and Enum.Material.Ground or Enum.Material.Sand,true)end
    end
   end
  end)
  chunk(route.Name..'Planting',function(g)
   local lastTree,lastBed,lastStone=-100,-100,-100
   for i,s in samples do local p,n=s.P,s.N
    if p.Z>-58 then continue end
    local rear=p.Z< -390;local rich=route.Green or rear
    if s.D-lastTree>(rich and 36 or 86)then
     local side=(math.floor(s.D/35)%2==0)and 1 or -1
     tree(g,p+n*(side*(rich and 20 or 18)),rich and .9+(i%3)*.1 or .72,i*.71)
     if rich and i%3~=0 then
      local outside=route.Green and -1 or 1;local along=Vector3.new(-n.Z,0,n.X)
      tree(g,p+n*(outside*25)+along*7,.66+(i%2)*.08,i*.91)
      shrub(g,p+n*(outside*23)+along*4,.85)
     end
     lastTree=s.D
    end
    if s.D-lastBed>(rich and 12 or 26)then
     local side=i%2==0 and 1 or -1;local pos=p+n*(side*(11.5+math.sin(i)*1.5))
     shrub(g,pos,rich and .9 or .65);grass(g,pos+n*(side*1.5),rich and 1.15 or .85)
     for j=1,(rich and 3 or 1)do flower(g,pos+n*(side*(2+j*.7))+(Vector3.new(-n.Z,0,n.X))*(j-2)*1.1,flowerColors[(i+j)%4+1],rich and 1.05 or .85)end
     lastBed=s.D
    end
    if s.D-lastStone>44 then
     local pos=p-n*(13.5+math.sin(i)*2)
     if safe(pos,2)then rock(g,pos+Vector3.new(0,.38,0),Vector3.new(2.1,.75,1.7),Color3.fromRGB(206,186,144),false)end
     lastStone=s.D
    end
   end
  end)
 end
 chunk('ParkRestDetails',function(g)
  for _,spec in {{-112,-443},{55,-443}}do
   local center=Vector3.new(spec[1],0,spec[2]);disk(g,center+Vector3.new(0,.095,0),6.2,4,P.Limestone,Enum.Material.Limestone,false,spec[1],9)
   for j=1,4 do part(g,'Part','RearBenchPlank',Vector3.new(6,.16,.36),CFrame.new(center+Vector3.new(0,.95,(j-2.5)*.41)),P.Wood,Enum.Material.Wood)end
   for _,side in {-1,1}do part(g,'Part','RearBenchFoot',Vector3.new(.55,.8,1.6),CFrame.new(center+Vector3.new(side*2.2,.45,0)),P.Stone,Enum.Material.Limestone)end
   part(g,'Part','RearBenchBack',Vector3.new(6,.7,.14),CFrame.new(center+Vector3.new(0,1.55,-.9)),P.Wood,Enum.Material.Wood)
   for j=1,3 do flower(g,center+Vector3.new(4.6,0,(j-2)*1.1),flowerColors[j],1.05)end
  end
  for _,spec in {{-253,-146,0},{-251,-290,0},{-151,-443,math.pi/2}}do
   local center=Vector3.new(spec[1],0,spec[2]);local along=Vector3.new(math.sin(spec[3]),0,math.cos(spec[3]))*4.5
   if safe(center,5)then
    for _,side in {-1,1}do part(g,'Part','ParkFencePost',Vector3.new(.24,1.8,.24),CFrame.new(center+along*side+Vector3.new(0,.9,0)),P.DarkWood,Enum.Material.Wood)end
    for _,height in {.65,1.35}do beam(g,'ParkFenceRail',center-along+Vector3.new(0,height,0),center+along+Vector3.new(0,height,0),.15,P.Wood,Enum.Material.Wood)end
   end
  end
 end)
 chunk('ConveyorServiceApron',function(g)
  local a,b=Vector3.new(-18,.105,-65),Vector3.new(15.5,.105,-22)
  part(g,'Part','ConveyorServiceApron',Vector3.new(7.5,.05,(b-a).Magnitude+2),CFrame.lookAt((a+b)/2,b),P.Stone,Enum.Material.Pebble)
 end)
 chunk('ServiceGarden',function(g)
  -- Thin surface additions cannot alter prompts, collisions or working positions.
  for _,spec in {{-45,-28,14,7},{19,-22,8,8},{31,-22,11,8},{139,-48,17,10}}do
   part(g,'Part','LimestoneServiceBase',Vector3.new(spec[3],.045,spec[4]),CFrame.new(spec[1],.125,spec[2]),P.Limestone,Enum.Material.Limestone)
  end
  for _,spec in {{44,-7,7,3.2},{-60,-17,7,3},{-150,-20,8,4},{63,10,9,4},{115,-7,7,4},{45,-33,3,3},{1,-26,3,3}}do
   local p=Vector3.new(spec[1],0,spec[2]);if safe(p,2)then
    part(g,'Part','StonePlanterBase',Vector3.new(spec[3],.5,spec[4]),CFrame.new(p+Vector3.new(0,.27,0)),P.Stone,Enum.Material.Limestone)
    part(g,'Part','GardenSoil',Vector3.new(spec[3]-.4,.08,spec[4]-.4),CFrame.new(p+Vector3.new(0,.56,0)),Color3.fromRGB(94,84,63),Enum.Material.Ground)
    for i=1,4 do shrub(g,p+Vector3.new((i-2.5)*spec[3]/4,.56,0),.62)end
   end
  end
  for _,spec in {{-117,-8,1},{55,4,-1},{104,-4,1}}do
   local x,z=spec[1],spec[2]
   if safe(Vector3.new(x,0,z),4)then
    for i=1,4 do part(g,'Part','BenchPlank',Vector3.new(6,.16,.38),CFrame.new(x,.95,z+(i-2.5)*.43),P.Wood,Enum.Material.Wood)end
    for _,side in {-1,1}do part(g,'Part','BenchStoneLeg',Vector3.new(.7,.8,1.7),CFrame.new(x+side*2.2,.4,z),P.Stone,Enum.Material.Limestone)end
    part(g,'Part','BenchBack',Vector3.new(6,.65,.15),CFrame.new(x,1.6,z+.95),P.Wood,Enum.Material.Wood)
   end
  end
  for _,z in {-28,-39}do
   local p=Vector3.new(46,0,z)
   if safe(p,3)then
    part(g,'Part','WorkshopPlanterStone',Vector3.new(4,.45,5.5),CFrame.new(p+Vector3.new(0,.25,0)),P.Stone,Enum.Material.Limestone)
    part(g,'Part','WorkshopPlanterSoil',Vector3.new(3.6,.08,5.1),CFrame.new(p+Vector3.new(0,.53,0)),Color3.fromRGB(109,94,68),Enum.Material.Ground)
    for _,side in {-1,1}do part(g,'Part','WorkshopPlanterTimber',Vector3.new(.16,.22,5.5),CFrame.new(p+Vector3.new(side*1.94,.58,0)),P.Wood,Enum.Material.Wood)end
    for i=1,3 do shrub(g,p+Vector3.new(0,.59,(i-2)*1.6),.75)end
    for i=1,3 do flower(g,p+Vector3.new(-1.15,.59,(i-2)*1.4),flowerColors[(i+1)%4+1],.8)end
   end
  end
 end)
 -- Near-field giant rocks and raised side terraces have been retired.
 -- Original DTM_Environment / DTM_Decor and the distant Terrain remain untouched.
 chunk('QuarryFootDetails',function(g)
  for index,spot in {{-205,-100},{-207,-170},{-206,-250},{-204,-325},{140,-105},{142,-200},{141,-307},{-157,-390},{-65,-391},{40,-390},{111,-390}}do
   local p=Vector3.new(spot[1],0,spot[2])
   if safe(p,2.5)then
    rock(g,p+Vector3.new(0,.36,0),Vector3.new(2.7,.72,2.2),Color3.fromRGB(214,187,139),false)
    for j=1,3 do local q=p+Vector3.new(j*1.1,0,1.8-j*.65);if safe(q,.7)then
     local blade=part(g,'WedgePart','DryQuarryGrass',Vector3.new(.09,.65+j*.1,.28),CFrame.new(q+Vector3.new(0,.3,0))*CFrame.Angles(0,j*1.7,.15*(j-2)),Color3.fromRGB(185,167,104))
    end end
    if index%3==0 then shrub(g,p+Vector3.new(-1.8,0,1.4),.55)end
   end
  end
 end)
 -- Sparse planting continues behind the mountain; these broad rear clearings stay empty.
 root:SetAttribute('RearClearingWest',offset+Vector3.new(-145,0,-490))
 root:SetAttribute('RearClearingEast',offset+Vector3.new(75,0,-490))
 root:SetAttribute('RearClearingSize',Vector3.new(58,0,46))
 chunk('EasternDryWash',function(g)
  local points={Vector3.new(208,.03,-83),Vector3.new(216,.03,-144),Vector3.new(210,.03,-201),Vector3.new(214,.03,-274),Vector3.new(202,.03,-343),Vector3.new(185,.03,-372)}
  local left,right,outerLeft,outerRight={},{},{},{}
  for i,p in points do local d=(points[math.min(#points,i+1)]-points[math.max(1,i-1)]).Unit;local n=Vector3.new(-d.Z,0,d.X);local w=3+math.sin(i)*.7;left[i]=p+n*w;right[i]=p-n*w;outerLeft[i]=p+n*(w+2.2+math.cos(i)*.6);outerRight[i]=p-n*(w+2.2+math.sin(i)*.5)end
  for i=1,#points-1 do
   flatTriangle(g,left[i],right[i],right[i+1],Color3.fromRGB(201,181,134),Enum.Material.Ground,false,.022)
   flatTriangle(g,left[i],right[i+1],left[i+1],Color3.fromRGB(201,181,134),Enum.Material.Ground,false,.022)
   for _,s in {{left,outerLeft},{right,outerRight}}do flatTriangle(g,s[1][i],s[2][i],s[2][i+1],Color3.fromRGB(212,192,145),Enum.Material.Sand,false,.022);flatTriangle(g,s[1][i],s[2][i+1],s[1][i+1],Color3.fromRGB(212,192,145),Enum.Material.Sand,false,.022)end
   local a,b=points[i],points[i+1]
   for j=1,7 do local p=a:Lerp(b,j/8)+Vector3.new(math.sin(j*2+i)*2,.2,math.cos(j*3)*1.1);rock(g,p,Vector3.new(1.1+j%3*.25,.38,1.05),Color3.fromRGB(193,173,135),false)end
   for j=1,2 do local p=a:Lerp(b,j/3)+Vector3.new(5,0,0);if safe(p,2)then shrub(g,p,.65);grass(g,p+Vector3.new(1,0,.5),1.1)end end
  end
 end)
 local treeSpots={{-149,1},{-117,-11},{-98,7},{-72,-9},{-63,-23},{-25,15},{48,9},{70,-3},{98,-11},{116,7},{168,-12}}
 chunk('CourtyardTrees',function(g)for i,p in treeSpots do if not(low and i%4==0)then tree(g,Vector3.new(p[1],0,p[2]),.88+(i%3)*.16,i*1.4)end end end)
 local beds={{-142,-27},{-124,6},{-102,-18},{-72,3},{-58,-8},{-59,-36},{44,-9},{62,8},{83,-7},{103,5},{117,-20},{167,-23}}
 for index,spot in beds do
  chunk('BotanicalBed'..index,function(g)
   local center=Vector3.new(spot[1],0,spot[2])
   if not safe(center,3)then return end
   disk(g,center+Vector3.new(0,.075,0),5,3,P.Meadow,Enum.Material.Grass,false,index,8)
   for i=1,(low and 3 or 5)do local a=i*2.4;local pos=center+Vector3.new(math.cos(a)*2.7,0,math.sin(a)*1.5);shrub(g,pos,.8+rng:NextNumber()*.25);grass(g,pos+Vector3.new(1,0,.4),1)end
   for i=1,(low and 4 or 9)do local a=i*1.7;flower(g,center+Vector3.new(math.cos(a)*3.7,0,math.sin(a)*2.2),flowerColors[(i+index)%#flowerColors+1],1.1+rng:NextNumber()*.3)end
   for _,side in {-1,1}do rock(g,center+Vector3.new(side*3.9,.25,1.8),Vector3.new(1.1,.45,.8),P.Stone,false)end
  end)
 end
 chunk('WoodlandBoundary',function(g)
  for _,line in {{{-151,10},{-98,10}},{{52,11},{115,11}}}do
   local a,b=Vector3.new(line[1][1],0,line[1][2]),Vector3.new(line[2][1],0,line[2][2]);local n=math.ceil((b-a).Magnitude/9)
   for i=0,n do local pos=a:Lerp(b,i/n);part(g,'Part','TimberFencePost',Vector3.new(.26,2.3,.26),CFrame.new(pos+Vector3.new(0,1.15,0)),P.DarkWood,Enum.Material.Wood)end
   for _,height in {.8,1.6}do beam(g,'TimberFenceRail',a+Vector3.new(0,height,0),b+Vector3.new(0,height,0),.17,P.Wood,Enum.Material.Wood)end
  end
 end)
 chunk('GardenIdentity',function(g)
  local pos=Vector3.new(-30,0,11)
  for _,x in {-4.7,4.7}do part(g,'Part','GardenSignPost',Vector3.new(.18,4,.18),CFrame.new(pos+Vector3.new(x,2,0)),P.Wood,Enum.Material.Wood)end
  local board=part(g,'Part','QuarryGardenWelcome',Vector3.new(10,2,.18),CFrame.new(pos+Vector3.new(0,3.3,0)),Color3.fromRGB(53,91,65),Enum.Material.Wood)
  local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(700,160);gui.LightInfluence=.6;gui.MaxDistance=100;gui.Parent=board
  local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text='QUARRY GARDEN\nСАД КАРЬЕРА';label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.TextColor3=P.Cream;label.Parent=gui
  local back=gui:Clone();back.Face=Enum.NormalId.Back;back.Parent=board
 end)
 root:SetAttribute('PartCount',count);root:SetAttribute('Ready',true)
 return root
end
return Garden