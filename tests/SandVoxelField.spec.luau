return function(Field)
	local field=Field.Create()
	assert(Field.Address(-0,0,-0)==Field.Address(0,0,0),"signed zero creates a separate chunk")
	field.Set(-0,6,-0,true)
	assert(field.Has(0,6,0),"template signed zero disappears from Terrain")
	field.Set(0,6,0,false)
	assert(field.Count()==0,"signed zero duplicates mass")
	local expected={}
	local function key(x,y,z)return x..","..y..","..z end
	for x=-5,5 do for y=0,6 do for z=-5,5 do
		local occupied=(x+y+z)%3~=0
		field.Set(x,y,z,occupied)
		if occupied then expected[key(x,y,z)]=true end
	end end end
	local count=0
	field.Each(function(x,y,z)
		assert(expected[key(x,y,z)],"unexpected cell in chunk iteration")
		expected[key(x,y,z)]=nil count+=1
	end)
	assert(next(expected)==nil and count==field.Count(),"chunk count/coordinates changed")
	local folder=Instance.new("Folder")
	local chunks=field.Publish(folder)
	assert(chunks>0 and chunks<64 and field.Publish(folder)==0,"dirty chunks not drained")
	for x=-5,5 do for y=0,6 do for z=-5,5 do
		local value=folder:FindFirstChild(Field.Address(x,y,z))
		assert((value and Field.Contains(value.Value,x,y,z)or false)==field.Has(x,y,z),"replicated occupancy differs")
	end end end
	assert(not Field.Decode("FFFFFFFFFFFFFFFF")and not Field.Decode("123")and not Field.Decode(false),"invalid payload accepted")
	local full=Field.Create()
	for x=0,3 do for y=0,3 do for z=0,3 do full.Set(x,y,z,true)end end end
	local one=Instance.new("Folder")full.Publish(one)
	assert(one:GetChildren()[1].Value=="ffffffffffffffff","32/64-bit boundary lost")
	assert(not full.Set(3,3,3,true)and full.Count()==64,"duplicate mass")
	full.Set(3,3,3,false)full.Set(4,3,3,true)
	assert(full.Count()==64 and full.Publish(one)==2,"cross-chunk transfer lost mass or dirty neighbour")
	for x=0,4 do for y=0,3 do for z=0,3 do full.Set(x,y,z,false)end end end
	full.Publish(one)
	assert(full.Count()==0,"empty chunk retains mass")
	for _,v in one:GetChildren()do assert(v.Value=="0000000000000000","empty chunk stale on client")end
	folder:Destroy()one:Destroy()
	return {roundTrips=847,cells=count,chunks=chunks,crossBorder=true,emptyReplication=true}
end
