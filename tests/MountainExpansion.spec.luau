-- Edit-mode check with an injected store. No real DataStore calls.
return function(modules)
	local PlotData=modules.SandPrototypePlotData
	local Finds=modules.SandPrototypeFindData
	local SaveSession=modules.SandPrototypeSaveSession
	local core={}
	for _,cell in PlotData.Fresh().cells do
		local radius=4-cell.y
		if cell.y<=4 and math.abs(cell.x)<=radius and math.abs(cell.z)<=radius then table.insert(core,cell) end
	end
	assert(#core==165)
	local checked=0
	local function check(value,message) assert(value,message) checked+=1 end
	local function open(snapshot,lease)
		local record={formatVersion=1,snapshot=snapshot,lease=lease}
		local store={record=record,writes=0}
		function store:UpdateAsync(_,callback)
			local nextValue=callback(self.record)
			if nextValue then self.record=nextValue self.writes+=1 end
			return nextValue
		end
		local fresh=assert(Finds.Validator(42,false)(PlotData.Fresh()))
		local session,reason=SaveSession.Open(store,"player_42",fresh,{
			owner="test-session",now=function()return 100 end,
			validate=Finds.Validator(42,false),transition=Finds.Advances,
			migrate=function(raw)return PlotData.Expand(42,raw)end})
		return session,reason,store,record
	end
	local remaining={}
	for i=11,#core do table.insert(remaining,core[i]) end
	local old={schemaVersion=3,ownerId="42",revision=7,initialCells=165,dugCells=10,movedCells=2,cells=remaining,
		account={CarriedCells=3,CapacityCells=20,CapacityLevel=0,BarrowOwned=0,Coins=3,XP=6},
		outbound={["43"]=4},imports={},accessMode="Friends",
		artifact={kind="PotteryShard",finderId="43",counter=1},collection={}}
	local session,reason,store=open(old,nil)
	check(session~=nil,tostring(reason))
	check(store.writes==1,"migration must write once")
	local data=store.record.snapshot
	check(data.initialCells==455 and data.dugCells==10 and #data.cells==445,"mass or holes changed")
	check(data.account.CarriedCells==3 and data.account.Coins==3 and data.account.XP==6,"wallet changed")
	check(data.outbound["43"]==4 and data.accessMode=="Friends","helper state changed")
	check(data.artifact.finderId=="43" and data.artifact.counter==1,"find proof changed")
	check(data.revision==7 and old.initialCells==165,"source mutated")
	check(store.record.legacy165Backup==old,"original snapshot not archived")
	local keys={}for _,cell in data.cells do keys[cell.x..","..cell.y..","..cell.z]=true end
	for i=1,10 do local c=core[i]check(not keys[c.x..","..c.y..","..c.z],"dug cell reappeared")end
	local saved,saveReason=session:Save(data,true)
	check(saved,tostring(saveReason))
	check(store.record.snapshot.revision==8 and store.record.lease==nil,"save/release failed")
	check(store.record.legacy165Backup==old,"original snapshot lost on save")
	local reopened,reopenReason=SaveSession.Open(store,"player_42",assert(Finds.Validator(42,false)(PlotData.Fresh())),{
		owner="next-session",now=function()return 101 end,validate=Finds.Validator(42,false),
		migrate=function(raw)return PlotData.Expand(42,raw)end})
	check(reopened~=nil,tostring(reopenReason))
	check(reopened.snapshot.dugCells==10 and #reopened.snapshot.cells==445,"second load duplicated new sand")
	check(store.record.legacy165Backup==old,"original snapshot lost on second load")
	local locked,lockReason,lockStore,lockRecord=open(old,{owner="other",expiresAt=200})
	check(locked==nil and lockReason=="locked" and lockStore.writes==0 and lockStore.record==lockRecord,"active lease ignored")
	local expired,expiredReason=open(old,{owner="other",expiresAt=50})
	check(expired~=nil,tostring(expiredReason))
	local invalid=table.clone(old)invalid.dugCells=11
	local blocked,_,badStore,badRecord=open(invalid,nil)
	check(blocked==nil and badStore.writes==0 and badStore.record==badRecord,"invalid save overwritten")
	local full={schemaVersion=1,revision=0,initialCells=165,dugCells=165,movedCells=0,cells={},
		accounts={["42"]={CarriedCells=0,CapacityCells=20,CapacityLevel=0,Coins=165,XP=165}}}
	local fullSession,fullReason,fullStore=open(full,nil)
	check(fullSession~=nil,tostring(fullReason))
	check(fullStore.record.snapshot.dugCells==165 and #fullStore.record.snapshot.cells==290,"completed core reset")
	check(type(fullStore.record.snapshot.artifact)=="table","new find not seeded")
	local shared={formatVersion=1,snapshot=full,lease={owner="old-server",expiresAt=50}}
	local copied,source=PlotData.Initial(42,shared,100)
	check(copied~=nil and source=="copied legacy 165",tostring(source))
	check(copied.dugCells==165 and #copied.cells==290,"shared legacy copy reset")
	local newcomer,newSource=PlotData.Initial(43,shared,100)
	check(newcomer~=nil and newSource=="fresh" and newcomer.initialCells==455,"new player blocked by old shared record")
	local active,activeReason=PlotData.Initial(42,{formatVersion=1,snapshot=full,lease={owner="old-server",expiresAt=200}},100)
	check(active==nil and activeReason=="legacy world is still active","shared lease ignored")
	return {checked=checked,partialRemaining=#data.cells,fullRemaining=#fullStore.record.snapshot.cells,realDataStoreCalls=0}
end
