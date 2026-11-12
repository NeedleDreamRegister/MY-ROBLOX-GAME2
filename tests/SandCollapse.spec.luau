return function(Collapse)
	local function key(x,y,z)return x..","..y..","..z end
	local function run(cells,budget,blocked)
		local before=0 for _ in cells do before+=1 end
		local moves=Collapse.Run(0,0,0,function(x,y,z)return cells[key(x,y,z)]end,
			function(source,sx,sy,sz,x,y,z)
				assert(cells[key(sx,sy,sz)]==source and cells[key(x,y,z)]==nil,"mass duplicated")
				cells[key(sx,sy,sz)]=nil cells[key(x,y,z)]=source
			end,function()return not blocked end,budget,0)
		local after=0 for _ in cells do after+=1 end assert(before==after,"mass changed")
		return moves
	end
	local tower={}for y=1,6 do tower[key(0,y,0)]={id=y}end
	assert(run(tower,8,false)==6 and tower[key(0,6,0)]==nil,"unsupported tall column remains")
	local priority={[key(0,1,0)]={id="above"},[key(1,1,0)]={id="side"}}
	assert(run(priority,1,false)==1 and priority[key(0,0,0)].id=="above","diagonal taken before vertical")
	local protected={[key(0,1,0)]={id=1}}
	assert(run(protected,8,true)==0 and protected[key(0,1,0)]~=nil,"buried a character")
	local bounded={}for y=1,6 do bounded[key(0,y,0)]={id=y}end
	assert(run(bounded,2,false)==2,"budget exceeded")
	local diagonal={[key(1,1,0)]={id=1}}
	assert(run(diagonal,8,false)==1 and diagonal[key(0,0,0)]~=nil,"side sand did not slide")
	assert(run({},8,false)==0,"created sand")
	return {scenarios=6,massConserved=true,verticalFirst=true,protectedCharacter=true}
end
