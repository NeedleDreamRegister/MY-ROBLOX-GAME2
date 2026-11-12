-- Inject a QA DataStore and a unique key for the real persistence check.
-- Default store is in memory; never pass a production player key.
return function(modules,store,key)
	local Finds,Plot,Session,Collapse,Field=modules.SandPrototypeFindData,modules.SandPrototypePlotData,modules.SandPrototypeSaveSession,modules.SandPrototypeCollapse,modules.SandPrototypeVoxelField
	local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
	local realStore=store~=nil
	if not store then
		store={records={}}
		function store:SetAsync(k,value)self.records[k]=copy(value)end
		function store:UpdateAsync(k,callback)
			callback(copy(self.records[k]))local value=callback(copy(self.records[k]))
			if value then self.records[k]=copy(value)end return copy(value)
		end
	end
	key=key or "in-memory-continuation"
	local validate=Finds.Validator(1)
	local initial=assert(validate(Plot.Fresh()))
	local legacy=copy(initial)
	for i,c in legacy.cells do if c.x==0 and c.y==0 and c.z==0 then table.remove(legacy.cells,i)break end end
	legacy.dugCells=1 legacy.account.CarriedCells=1 legacy.account.XP=1
	legacy.pendingCollapses={{x=0,y=0,z=0,budget=8}} -- old saved job, before height-based seeding
	assert(validate(legacy))
	store:SetAsync(key,{formatVersion=1,snapshot=legacy})
	local function open(owner)
		return assert(Session.Open(store,key,initial,{owner=owner,validate=validate,transition=Finds.Advances,compact=true}))
	end
	local first=open("blocked")
	assert(first.snapshot.pendingCollapses[1].budget==8,"legacy continuation lost")
	assert(first:Save(first.snapshot,true))
	local function advance(snapshot,frameBudget)
		local data=copy(snapshot)
		local cells=Field.Create()for _,c in data.cells do cells.Set(c.x,c.y,c.z,true)end
		local moves,retry=Collapse.Advance(data.pendingCollapses[1],function(x,y,z)return cells.Has(x,y,z)end,
			function(_,sx,sy,sz,x,y,z)
				cells.Set(sx,sy,sz,false)cells.Set(x,y,z,true)
				data.artifact=Finds.Move(data.artifact,sx,sy,sz,x,y,z)
			end,function()return true end,frameBudget,1)
		data.movedCells+=moves data.pendingCollapses=retry and {retry}or {}
		data.cells={}cells.Each(function(x,y,z)data.cells[#data.cells+1]={x=x,y=y,z=z}end)
		return assert(validate(data))
	end
	local second=open("partial")
	local partial=advance(second.snapshot,2)
	assert(partial.movedCells==2 and #partial.pendingCollapses==1 and partial.pendingCollapses[1].y==2)
	assert(second:Save(partial,true))
	local third=open("resume")
	assert(third.snapshot.movedCells==2 and third.snapshot.pendingCollapses[1].y==2,"unfinished state not restored")
	local complete=advance(third.snapshot,8)
	assert(third:Save(complete,true))
	local fourth=open("verify")
	local final=fourth.snapshot
	assert(final.dugCells==1 and final.movedCells==6 and #final.pendingCollapses==0 and #final.cells==454)
	assert(final.account.CarriedCells==1 and final.account.XP==1 and final.account.Coins==0 and final.artifact.y==0,"collapse created rewards or lost find")
	assert(fourth:Save(final,true))
	return {key=key,realDataStore=realStore,dug=1,moved=6,carried=1,xp=1,coins=0,remaining=454,partialStateRestored=true,oldJobRead=true,pending=0}
end
