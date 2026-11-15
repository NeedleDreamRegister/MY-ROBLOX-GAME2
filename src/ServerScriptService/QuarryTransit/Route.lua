-- One continuous loop. Existing side promenades supply most of this alignment.
local Route = {}
Route.RoadHalfWidth = 12
Route.VehicleOffset = -5.2
Route.RootHeight = 1.5
local V = Vector3.new
Route.Controls = {
 V(45,0,43), V(-20,0,43), V(-90,0,35), V(-149,0,20),
 V(-193,0,-8), V(-220,0,-38), V(-229,0,-65), V(-229,0,-121),
 V(-235,0,-192), V(-229,0,-262), V(-226,0,-335), V(-217,0,-382),
 V(-185,0,-410), V(-128,0,-417), V(-76,0,-425), V(-34,0,-425),
 V(7,0,-425), V(50,0,-418), V(110,0,-411), V(145,0,-389),
 V(163,0,-359), V(172,0,-309), V(169,0,-251), V(171,0,-190),
 V(174,0,-125), V(178,0,-65), V(173,0,-26), V(160,0,7),
 V(135,0,30), V(100,0,42),
}
local function curve(a,b,c,d,t)
 return .5*((b*2)+(c-a)*t+(a*2-b*5+c*4-d)*t*t+(-a+b*3-c*3+d)*t*t*t)
end
local raw={}
local controls=Route.Controls
for i=1,#controls do
 local a,b,c,d=controls[(i-2)%#controls+1],controls[i],controls[i%#controls+1],controls[(i+1)%#controls+1]
 local steps=math.max(10,math.ceil((c-b).Magnitude/.8))
 for j=0,steps-1 do table.insert(raw,{P=curve(a,b,c,d,j/steps),Segment=i,T=j/steps}) end
end
local samples={}
local total=0
for i,item in raw do
 if i>1 then total+=(item.P-raw[i-1].P).Magnitude end
 samples[i]={P=item.P,D=total,Segment=item.Segment,T=item.T}
end
total+=(raw[1].P-raw[#raw].P).Magnitude
Route.Length=total
Route.Samples=samples
local function evaluate(distance)
 distance=distance%total
 local low,high=1,#samples
 while low<high do
  local mid=math.ceil((low+high)/2)
  if samples[mid].D<=distance then low=mid else high=mid-1 end
 end
 local left,right=samples[low],samples[low%#samples+1]
 local finish=low==#samples and total or right.D
 local fraction=(distance-left.D)/(finish-left.D)
 local nextT=right.Segment==left.Segment and right.T or 1
 local t=left.T+(nextT-left.T)*fraction
 local i=left.Segment
 local a,b,c,d=controls[(i-2)%#controls+1],controls[i],controls[i%#controls+1],controls[(i+1)%#controls+1]
 local tangent=.5*((c-a)+(a*2-b*5+c*4-d)*(2*t)+(-a+b*3-c*3+d)*(3*t*t))
 return curve(a,b,c,d,t),tangent.Unit
end
function Route.RoadAt(distance)
 -- The analytic spline tangent prevents wheel/body yaw from wavering at samples.
 local p,tangent=evaluate(distance)
 return p,Vector3.new(-tangent.Z,0,tangent.X),tangent
end
function Route.VehiclePosition(distance)
 local p,n=Route.RoadAt(distance)
 return p+n*Route.VehicleOffset+Vector3.new(0,Route.RootHeight,0)
end
function Route.Frame(distance)
 local p=Route.VehiclePosition(distance)
 local tangent=(Route.VehiclePosition(distance+.35)-Route.VehiclePosition(distance-.35)).Unit
 return CFrame.lookAt(p,p+tangent)
end
-- Convert road stationing to actual wheel travel, including the outside offset.
local arc={{D=0,S=0}}
local s=0
local prev=Route.VehiclePosition(0)
for d=1,math.ceil(total) do
 local rd=math.min(d,total)
 local p=Route.VehiclePosition(rd)
 s+=(p-prev).Magnitude
 table.insert(arc,{D=rd,S=s})
 prev=p
end
Route.TravelLength=s
function Route.DistanceAtTravel(travel)
 travel=travel%s
 local low,high=1,#arc
 while low<high do local mid=math.ceil((low+high)/2) if arc[mid].S<=travel then low=mid else high=mid-1 end end
 local a,b=arc[low],arc[math.min(low+1,#arc)]
 if b.S==a.S then return a.D end
 return a.D+(b.D-a.D)*(travel-a.S)/(b.S-a.S)
end
function Route.TravelFrame(travel)
 return Route.Frame(Route.DistanceAtTravel(travel))
end
function Route.WithOffset(offset)
 local world=setmetatable({}, {__index=Route})
 function world.RoadAt(d) local p,n,t=Route.RoadAt(d) return p+offset,n,t end
 function world.VehiclePosition(d) return Route.VehiclePosition(d)+offset end
 function world.Frame(d) return Route.Frame(d)+offset end
 function world.TravelFrame(s) return Route.TravelFrame(s)+offset end
 return world
end
return Route

