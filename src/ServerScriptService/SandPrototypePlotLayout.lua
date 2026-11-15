local Geometry=require(game.ReplicatedStorage.SandPrototypeGeometry)
local Layout={DefaultHeight=36}
function Layout.Get(height)
 assert(height>=6 and Geometry.Size(height),'unsupported plot height')
 local extra=(height-6)*4
 local origin=Vector3.new(-34,2,-94-extra)
 local edge=math.ceil((height+1)/4)*4
 local minimum=Vector3.new(math.min(-164,origin.X-edge*4-22),0,math.min(-322,origin.Z-edge*4-44))
 local maximum=Vector3.new(math.max(140,origin.X+edge*4+58),0,14)
 local size=maximum-minimum
 return {height=height,cells=Geometry.Size(height),origin=origin,minimum=minimum,maximum=maximum,groundSize=size,groundCenter=(minimum+maximum)/2,
 equipmentShift=Vector3.new(extra,0,0),spacing=math.ceil((math.max(size.X,size.Z)+48)/16)*16}
end
return Layout

