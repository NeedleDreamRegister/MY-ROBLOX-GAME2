return function(garden,offset,keepBackup)
offset=offset or Vector3.zero
local Route=require(game.ServerScriptService.QuarryTransit.Route).WithOffset(offset)
assert(not garden:FindFirstChild('FrontGardenLink'),'Road update already installed')
local backup
if keepBackup then backup=Instance.new('Folder') backup.Name='QuarryTransitOriginalRoads' backup.Parent=game.ServerStorage end
-- Preserve the two existing Model identities, and retain their original entrance spurs.
for _,name in {'WestPromenade','EastPromenade'} do
 local model=garden[name]
 local old=keepBackup and Instance.new('Model') or nil
 if old then old.Name=name old.Parent=backup end
 for _,p in model:GetChildren() do
  local pos=p:IsA('BasePart') and p.Position-offset or Vector3.zero
  local keep=p:IsA('BasePart') and (name=='WestPromenade' and pos.X>-198 and pos.Z>-55 or name=='EastPromenade' and pos.X<164 and pos.Z>-40)
  if not keep then if old then p.Parent=old else p:Destroy() end end
 end
 model:SetAttribute('Width',24)
 model:SetAttribute('FootwayWidth',9)
 model:SetAttribute('TransportWidth',15)
 model:SetAttribute('TransitUpgrade',true)
end
local front=Instance.new('Model') front.Name='FrontGardenLink' front.Parent=garden
local count=0
local function part(parent,name,size,cf,color,material,collide)
 local p=Instance.new('Part') p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true p.CanCollide=collide==true p.CanTouch=false p.CanQuery=collide==true p.CastShadow=false
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p:SetAttribute('QuarryTransit',true) p.Parent=parent count+=1 return p
end
local function triangle(parent,name,a,b,c,color,material,collide)
 local ab,ac,bc=b-a,c-a,c-b
 if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c elseif ac.Magnitude>bc.Magnitude then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local cross=ac:Cross(ab) if cross.Magnitude<.001 then return end
 local right=cross.Unit local up=bc:Cross(right).Unit local back=bc.Unit local h=math.abs(ab:Dot(up))
 for _,x in {{math.abs(ab:Dot(back)),(a+b)/2,right},{math.abs(ac:Dot(back)),(a+c)/2,-right}} do
  if x[1]>.015 and h>.015 then
   local p=Instance.new('WedgePart') p.Name=name p.Size=Vector3.new(.035,h,x[1]) p.CFrame=CFrame.fromMatrix(x[2],x[3],up,x[3]:Cross(up))
   p.Color=color p.Material=material p.Anchored=true p.CanCollide=collide==true p.CanQuery=collide==true p.CanTouch=false p.CastShadow=false p:SetAttribute('QuarryTransit',true) p.Parent=parent count+=1
  end
 end
end
local function strip(parent,name,a,b,c,d,color,material,collide)
 triangle(parent,name,a,b,c,color,material,collide) triangle(parent,name,a,c,d,color,material,collide)
end
local function beam(parent,name,a,b,width,height,color,mat)
 return part(parent,name,Vector3.new(width,height,(b-a).Magnitude+.015),CFrame.lookAt((a+b)/2,b),color,mat,false)
end
local stone=Color3.fromRGB(218,214,192)
local drive=Color3.fromRGB(156,166,147)
local edge=Color3.fromRGB(232,226,202)
local batches={}
local function flush()
 for parent,chunk in batches do chunk.Parent=parent end
 batches={} task.wait()
end
local function batch(parent)
 if not batches[parent] then local f=Instance.new('Model') f.Name='ParkLaneRibbon' batches[parent]=f end
 return batches[parent]
end
local step=4
for d=0,Route.Length-.001,step do
 local d2=math.min(d+step,Route.Length)
 local p,n=Route.RoadAt(d) local q,m=Route.RoadAt(d2)
 local localP=p-offset
 local parent=localP.Z<-22 and (localP.X<-34 and garden.WestPromenade or garden.EastPromenade) or front
 local g=batch(parent)
 local y=Vector3.new(0,.25,0)
 local foundation=part(g,'RoadFoundation',Vector3.new(24,.2,(q-p).Magnitude+1.5),CFrame.lookAt((p+q)/2+Vector3.new(0,.1,0),q+Vector3.new(0,.1,0)),drive,Enum.Material.Concrete,true)
 foundation.Transparency=1
 strip(g,'ElectricCartLane',p-n*12+y,p+n*3+y,q+m*3+y,q-m*12+y,drive,Enum.Material.Concrete,true)
 strip(g,'LimestoneFootway',p+n*3+y,p+n*12+y,q+m*12+y,q+m*3+y,stone,Enum.Material.Limestone,true)
 beam(g,'FlatLaneDivider',p+n*3+Vector3.new(0,.278,0),q+m*3+Vector3.new(0,.278,0),.17,.025,edge,Enum.Material.Limestone)
 if math.floor(d/step)%3==0 then
  for _,side in {-1,1} do beam(g,'FlushPathEdge',p+n*(side*11.8)+Vector3.new(0,.28,0),q+m*(side*11.8)+Vector3.new(0,.28,0),.13,.025,edge,Enum.Material.Limestone) end
 end
 -- A narrow planted verge only on the new front link; existing meadows are retained.
 if parent==front then
  for _,side in {-1,1} do
   strip(g,'FrontMeadowVerge',p+n*(side*12)+Vector3.new(0,.08,0),p+n*(side*18)+Vector3.new(0,.08,0),q+m*(side*18)+Vector3.new(0,.08,0),q+m*(side*12)+Vector3.new(0,.08,0),Color3.fromRGB(132,164,96),Enum.Material.Grass,false)
  end
 end
 if math.floor(d/step)%45==44 then flush() end
end
flush()
-- Sparse directional arrows, rather than highway center lines.
local markings=Instance.new('Model') markings.Name='ParkLaneMarkings' markings.Parent=front
for s=45,Route.TravelLength,105 do
 local cf=Route.TravelFrame(s)*CFrame.new(0,-1.205,0)
 part(markings,'DirectionStem',Vector3.new(.16,.025,1.6),cf,edge,nil,false)
 for _,side in {-1,1} do part(markings,'DirectionTip',Vector3.new(.14,.025,1.2),cf*CFrame.new(side*.34,0,-.65)*CFrame.Angles(0,side*-.65,0),edge,nil,false) end
end
-- The only boarding area. No text, stop sign, pavilion, or rear station.
local stop=Instance.new('Model') stop.Name='BoardingPlace' stop.Parent=front
local dock=Route.Frame(0)
local padCF=dock*CFrame.new(-11.3,-1.345,0)
local pad=part(stop,'LimestoneLanding',Vector3.new(9,.25,24),padCF,stone,Enum.Material.Limestone,true)
local marker=part(stop,'SafeExit',Vector3.new(1,1,1),padCF*CFrame.new(0,3,0),stone,nil,false) marker.Transparency=1
for _,z in {-11.5,11.5} do part(stop,'LandingInset',Vector3.new(8.7,.025,.12),padCF*CFrame.new(0,.14,z),Color3.fromRGB(147,154,130),Enum.Material.Limestone,false) end
-- Gentle pedestrian approach from the existing gate to the inside footway.
local approach={Vector3.new(17,.25,7)+offset,Vector3.new(23,.25,19)+offset,Vector3.new(34,.25,25)+offset,Vector3.new(44,.25,32)+offset}
local approachEdges={}
for i,p in approach do
 local before=(p-approach[math.max(1,i-1)])
 local after=(approach[math.min(#approach,i+1)]-p)
 if before.Magnitude<.01 then before=after end
 if after.Magnitude<.01 then after=before end
 local n1=Vector3.new(-before.Z,0,before.X).Unit
 local n2=Vector3.new(-after.Z,0,after.X).Unit
 local miter=(n1+n2).Unit
 local edge=miter*(3.2/math.max(.7,miter:Dot(n1)))
 approachEdges[i]={p+edge,p-edge}
end
for i=1,#approach-1 do strip(stop,'GateApproach',approachEdges[i][1],approachEdges[i][2],approachEdges[i+1][2],approachEdges[i+1][1],stone,Enum.Material.Limestone,true) end
-- Flush crossing stones connect the footway and the landing.
for x=-10,8,3 do part(stop,'CrossingStone',Vector3.new(1.25,.018,3.5),dock*CFrame.new(x,-1.205,0),edge,Enum.Material.Limestone,false) end
-- Keep actual existing plants, but shift clumps out of the widened paved corridor.
local stations={}
for d=0,Route.Length,4 do local p,n=Route.RoadAt(d) table.insert(stations,{P=p,N=n}) end
local function nearest(pos)
 local best,dist=nil,math.huge
 local flat=Vector3.new(pos.X,offset.Y,pos.Z)
 for _,s in stations do local v=(flat-s.P).Magnitude if v<dist then best,dist=s,v end end
 return best,dist
end
local shifted=0
for _,name in {'WestPromenadePlanting','EastPromenadePlanting'} do
 local g=garden[name] local anchors={} local groups={}
 for _,p in g:GetChildren() do
  if p:IsA('Model') then table.insert(groups,{Object=p,Center=p:GetPivot().Position})
  elseif p:IsA('BasePart') and (p.Name=='FlowerStem' or p.Name=='WeatheredLimestone') then table.insert(anchors,p) end
 end
 local used={}
 for _,anchor in anchors do local parts={}
  for _,p in g:GetChildren() do if p:IsA('BasePart') and not used[p] and (p.Position-anchor.Position).Magnitude<(anchor.Name=='FlowerStem' and 2 or 3.5) then table.insert(parts,p) used[p]=true end end
  table.insert(groups,{Parts=parts,Center=anchor.Position})
 end
 for _,p in g:GetChildren() do if p:IsA('BasePart') and not used[p] then table.insert(groups,{Parts={p},Center=p.Position}) end end
 for i,group in groups do
  local near,dist=nearest(group.Center)
  local allowance=group.Object and 6 or 2
  if dist<12+allowance then
   local side=(group.Center-near.P):Dot(near.N)>=0 and 1 or -1
   local displacement=near.N*(side*(14+allowance)-(group.Center-near.P):Dot(near.N))
   if group.Object then group.Object:SetAttribute('TransitOriginalPivot',group.Object:GetPivot()) group.Object:PivotTo(group.Object:GetPivot()+displacement)
   else for _,p in group.Parts do p:SetAttribute('TransitOriginalCFrame',p.CFrame) p.CFrame+=displacement end end
   shifted+=1
  end
  if i%75==0 then task.wait() end
 end
end
-- A few low garden lanterns. Their supports stand well outside the travel envelope.
local details=Instance.new('Model') details.Name='TransitGardenDetails' details.Parent=front
for _,s in {0,240,480,720,960,1200,1440} do
 local d=Route.DistanceAtTravel(s) local p,n=Route.RoadAt(d) local pos=p-n*16
 if s==0 then pos+=dock.LookVector*16 end
 part(details,'LanternFoot',Vector3.new(.8,.22,.8),CFrame.new(pos+Vector3.new(0,.11,0)),Color3.fromRGB(137,149,133),Enum.Material.Limestone,true)
 part(details,'LowLanternPost',Vector3.new(.18,3.1,.18),CFrame.new(pos+Vector3.new(0,1.75,0)),Color3.fromRGB(85,99,79),Enum.Material.Metal,false)
 local glass=part(details,'WarmLantern',Vector3.new(.55,.65,.55),CFrame.new(pos+Vector3.new(0,3.4,0)),Color3.fromRGB(255,229,171),Enum.Material.Neon,false)
 part(details,'LanternCap',Vector3.new(.8,.13,.8),CFrame.new(pos+Vector3.new(0,3.8,0)),Color3.fromRGB(94,108,85),Enum.Material.Metal,false)
 local light=Instance.new('PointLight') light.Color=glass.Color light.Brightness=.5 light.Range=11 light.Shadows=false light.Parent=glass
end
local stems={}
for _,p in garden.WestPromenadePlanting:GetChildren() do if p.Name=='FlowerStem' then table.insert(stems,p) end end
local flowers=Instance.new('Model') flowers.Name='LandingPlanting'
for i,loc in {Vector3.new(-16,0,-16),Vector3.new(-16,0,16),Vector3.new(-18,0,-14),Vector3.new(-18,0,14),Vector3.new(15,0,18),Vector3.new(15,0,-18)} do
 local stem=stems[i*3]
 if stem then
  local target=(dock*CFrame.new(loc)).Position target=Vector3.new(target.X,.45+offset.Y,target.Z)
  local displacement=target-stem.Position
  for _,p in garden.WestPromenadePlanting:GetChildren() do if p:IsA('BasePart') and (p.Position-stem.Position).Magnitude<1.65 and p.Name~='GardenFoliage' then local c=p:Clone() c.CFrame+=displacement c.Parent=flowers end end
 end
end
flowers.Parent=front
require(script.Parent.FloorSeamFix)(garden,offset)
front:SetAttribute('TransitReady',true)
return {partsCreated=count,plantClumpsShifted=shifted,roadWidth=24,landingPosition=tostring(pad.Position),routeLength=Route.TravelLength}
end

