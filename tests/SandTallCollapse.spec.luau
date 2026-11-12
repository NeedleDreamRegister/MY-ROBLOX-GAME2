return function(Collapse,Field)
	local field=Field.Create()
	for y=1,74 do field.Set(0,y,0,true)end
	local queue=Collapse.Queue(128)
	queue.Push({x=0,y=0,z=0,budget=74})
	local initialPotential=74*75/2
	local total,steps=0,0
	local function advance(entry)
		local moves,retry=Collapse.Advance(entry,function(x,y,z)return field.Has(x,y,z)end,function(_,sx,sy,sz,x,y,z)
			assert(sy-y==1 and field.Has(sx,sy,sz)and not field.Has(x,y,z),"invalid transfer")
			field.Set(sx,sy,sz,false)field.Set(x,y,z,true)
		end,function()return true end,8,1)
		assert(moves<=8,"frame exceeded transfer limit")total+=moves
		local mass,potential=0,0
		field.Each(function(_,y)mass+=1 potential+=y end)
		assert(mass==74 and potential+total==initialPotential,"mass or height potential changed")
		return retry
	end
	while queue.Count()>0 do
		queue.Step(advance,1)steps+=1 assert(steps<=10,"column never settles")
		if steps==3 then
			-- Save an unfinished logical field and continuation, then rebuild both.
			local encoded=game:GetService("HttpService"):JSONEncode({chunks=field.Export(),pending=queue.Export()})
			local restored=game:GetService("HttpService"):JSONDecode(encoded)
			field=Field.Create()
			for key,bits in restored.chunks do
				local cx,cy,cz=key:match("^(-?%d+),(-?%d+),(-?%d+)$")
				for x=0,3 do for y=0,3 do for z=0,3 do
					local gx,gy,gz=tonumber(cx)*4+x,tonumber(cy)*4+y,tonumber(cz)*4+z
					if Field.Contains(bits,gx,gy,gz)then field.Set(gx,gy,gz,true)end
				end end end
			end
			queue=Collapse.Queue(128)for _,job in restored.pending do queue.Push(job)end
		end
	end
	assert(total==74 and steps==10 and field.Has(0,0,0)and not field.Has(0,74,0))
	for y=0,73 do assert(field.Has(0,y,0),"gap left in the settled column")end
	local blocked={x=0,y=0,z=0,budget=74}
	local moves,retry=Collapse.Advance(blocked,function(_,y)return y==1 end,function()error("buried a character")end,function()return false end,8,1)
	assert(moves==0 and retry.budget==74,"character block lost remaining work")
	return {transfers=total,steps=steps,mass=74,potentialConserved=true,unfinishedStateRestored=true,noColumnGap=true}
end
