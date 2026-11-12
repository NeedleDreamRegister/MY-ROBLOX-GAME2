-- Shared coordinate conversion. The server separately checks ownership and visibility.
local Grid={CellSize=4}
function Grid.Position(origin,x,y,z)return origin+Vector3.new(x*4,y*4,z*4)end
function Grid.Coordinates(origin,position)
	local v=(position-origin)/4
	return math.floor(v.X+0.5),math.floor(v.Y+0.5),math.floor(v.Z+0.5)
end
function Grid.Resolve(origin,position,normal,getCell,bounds)
	local x,y,z=Grid.Coordinates(origin,position-normal*0.25)
	if bounds then
		local lo,hi=bounds.min,bounds.max
		if x<lo.X-1 or x>hi.X or y<lo.Y-1 or y>hi.Y or z<lo.Z-1 or z>hi.Z then return nil end
	elseif math.abs(x)>8 or y< -1 or y>8 or math.abs(z)>8 then return nil end
	local direct=getCell(x,y,z)
	if direct then return direct end
	local closest,distance
	for dx=-1,1 do for dy=-1,1 do for dz=-1,1 do
		local cell=getCell(x+dx,y+dy,z+dz)
		if cell then
			local d=(Grid.Position(origin,x+dx,y+dy,z+dz)-position).Magnitude
			if d<=4.1 and(not distance or d<distance)then closest=cell distance=d end
		end
	end end end
	return closest
end
return Grid
