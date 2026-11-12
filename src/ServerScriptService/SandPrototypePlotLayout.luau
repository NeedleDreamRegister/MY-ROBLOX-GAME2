-- Runtime layout only. Scene templates keep their original names and transforms.
local Geometry=require(game:GetService("ReplicatedStorage").SandPrototypeGeometry)
local Layout={DefaultHeight=12}
function Layout.Get(height)
 assert(height>=6 and Geometry.Size(height),"unsupported plot height")
 local extra=(height-6)*4
 local origin=Vector3.new(-22,2,-66-extra)
 local edge=math.ceil((height+1)/4)*4
 local minimum=Vector3.new(origin.X-edge*4-2,0,origin.Z-edge*4)
 local maximum=Vector3.new(40+extra,0,14)
 local size=maximum-minimum
 return {height=height,cells=Geometry.Size(height),origin=origin,minimum=minimum,maximum=maximum,
  groundSize=size,groundCenter=(minimum+maximum)/2,equipmentShift=Vector3.new(extra,0,0),
  spacing=math.ceil((math.max(size.X,size.Z)+16)/16)*16}
end
return Layout
