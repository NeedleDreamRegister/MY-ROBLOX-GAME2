return function(modules)
	local Collapse=modules.SandPrototypeCollapse
	local queue=Collapse.Queue(2)
	queue.Push({x=0,y=0,z=0,budget=8})queue.Push({x=0,y=0,z=0,budget=4})
	queue.Push({x=1,y=0,z=0,budget=8})queue.Push({x=2,y=0,z=0,budget=8})
	assert(queue.Count()==2,"queue did not deduplicate or bound work")
	local visited={}
	queue.Step(function(entry)visited[#visited+1]=entry.x return entry end,1)
	queue.Step(function(entry)visited[#visited+1]=entry.x end,1)
	assert(visited[1]==0 and visited[2]==1 and queue.Count()==1,"blocked job starved its neighbour")
	local tower={}
	for y=1,6 do tower[y]=true end
	local moves,blocked,x,y,z=Collapse.Run(0,0,0,function(_,cy)return tower[cy]end,function()error("buried character")end,function()return false end,8,1)
	assert(moves==0 and blocked and x==0 and y==0 and z==0,"blocked vacancy lost")
	local resumed=Collapse.Run(x,y,z,function(_,cy)return tower[cy]end,function(_,_,sy,_,_,dy)tower[sy]=nil tower[dy]=true end,function()return true end,8-moves,1)
	assert(resumed==6 and tower[0]and not tower[6],"unblocked column did not resume")
	local Finds,Plot,Session=modules.SandPrototypeFindData,modules.SandPrototypePlotData,modules.SandPrototypeSaveSession
	local validate=Finds.Validator(1)
	local before=assert(validate(Plot.Fresh()))
	for i,c in before.cells do if c.x==0 and c.y==0 and c.z==0 then table.remove(before.cells,i)break end end
	before.dugCells=1 before.account.XP=1 before.account.CarriedCells=1
	before.pendingCollapses={{x=0,y=0,z=0,budget=8}}
	before=assert(validate(before))
	local after=game:GetService("HttpService"):JSONDecode(game:GetService("HttpService"):JSONEncode(before))
	for _,c in after.cells do if c.x==0 and c.y==1 and c.z==0 then c.y=0 break end end
	after.artifact=Finds.Move(after.artifact,0,1,0,0,0,0)
	assert(not Finds.Advances(before,after),"artifact moved without any collapse")
	after.movedCells=1 after.pendingCollapses={}after=assert(validate(after))
	assert(Finds.Advances(before,after),"delayed collapse requires another reward")
	assert(not Finds.Advances(after,before),"collapse count rolled back")
	local store={}
	function store:UpdateAsync(_,callback)local result=callback(self.value)if result then self.value=result end return result end
	local s=assert(Session.Open(store,"qa",before,{owner="test",validate=validate,transition=Finds.Advances,compact=true}))
	assert(#s.snapshot.pendingCollapses==1 and s.snapshot.pendingCollapses[1].budget==8,"pending collapse lost on load")
	assert(s:Save(after,true),"delayed artifact position not saved")
	s=assert(Session.Open(store,"qa",before,{owner="reload",validate=validate,transition=Finds.Advances,compact=true}))
	assert(s.snapshot.artifact.y==0 and s.snapshot.dugCells==1 and s.snapshot.account.XP==1 and s.snapshot.account.CarriedCells==1,"delayed collapse minted rewards or lost find")
	assert(s:Save(s.snapshot,true))
	local corrupt=table.clone(before)corrupt.pendingCollapses={{x=0,y=0,z=0,budget=8},{x=1,y=0,z=0,budget=1}}
	assert(not validate(corrupt),"pending jobs exceed original dig budget")
	return {boundedQueue=true,fairRetry=true,resumedMoves=resumed,noExtraRewards=true,artifactSaved=true}
end
