return function(Grid)
	local origin=Vector3.new(-22,2,-66)
	for x=-6,6 do for y=0,6 do for z=-6,6 do
		local a,b,c=Grid.Coordinates(origin,Grid.Position(origin,x,y,z))
		assert(a==x and b==y and c==z,"grid round trip failed")
	end end end
	local cell={}
	local getCell=function(x,y,z)if x==0 and y==0 and z==0 then return cell end end
	assert(Grid.Resolve(origin,origin+Vector3.new(0,2,0),Vector3.yAxis,getCell)==cell,"surface not resolved")
	assert(Grid.Resolve(origin,origin+Vector3.new(0,2.1,0),Vector3.yAxis,getCell)==cell,"rounded surface not resolved")
	assert(Grid.Resolve(origin,origin+Vector3.new(128,0,0),Vector3.yAxis,getCell)==nil,"neighbour plot was targeted")
	return {roundTrips=1183,surface=true,foreignPlotRejected=true}
end
