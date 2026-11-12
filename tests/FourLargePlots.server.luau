-- Isolated four-client experiment. No production DataStore access.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio(),"Studio only")
local main=game.ServerScriptService.SandPrototype
assert(not main.Enabled and main:GetAttribute("PersistenceEnabled")==false,"Production must be disabled")
local Players=game:GetService("Players")
local StudioTest=game:GetService("StudioTestService")
local template=workspace.SandPrototype
local cellTemplate=template.Cells:FindFirstChildWhichIsA("BasePart"):Clone()
local origin=template.Cells.Cell_0_0_0.Position
local stationTemplate=workspace.SandPrototypeStation
local remote=Instance.new("RemoteEvent")remote.Name="FourLargeQA"remote.Parent=game.ReplicatedStorage
local ready,reports,worlds={},{},{}
local phase
local traffic={idle={},dig={}}
local roundTimes={}
local function summarize(values)
	local out={count=#values}
	for _,key in {"receive","send"}do
		local ordered={}local sum=0
		for _,v in values do table.insert(ordered,v[key])sum+=v[key]end
		table.sort(ordered)
		out[key]={mean=#values>0 and sum/#values or 0,p95=ordered[math.ceil(#ordered*.95)]or 0}
	end
	return out
end
task.spawn(function()
	local stats=game:GetService("Stats")
	while remote.Parent do
		if phase then table.insert(traffic[phase],{receive=stats.DataReceiveKbps,send=stats.DataSendKbps})end
		task.wait(.25)
	end
end)
remote.OnServerEvent:Connect(function(player,action,value)
	if action=="ready"then ready[player]=true
	elseif action=="report"and type(value)=="table"then reports[player]=value end
end)
local function waitUntil(check,message)
	local deadline=os.clock()+35
	while not check()and os.clock()<deadline do task.wait(.05)end
	assert(check(),message)
end
local ok,result=pcall(function()
	waitUntil(function()return #Players:GetPlayers()==4 end,"Four clients did not join")
	local players=Players:GetPlayers()
	table.sort(players,function(a,b)return a.UserId<b.UserId end)
	local root=Instance.new("Folder")root.Name="SandPlots"root.Parent=workspace
	workspace:SetAttribute("PersonalPlotsEnabled",true)
	local factory=require(game.ServerScriptService.SandPrototypeWorld)
	for index,player in players do
		local offset=Vector3.new(((index-1)%2)*85,0,math.floor((index-1)/2)*85)
		local mountain=Instance.new("Model")mountain.Name="Large_"..player.UserId
		local cells=Instance.new("Folder")cells.Name="Cells"cells.Parent=mountain
		mountain.Parent=root
		local initial={schemaVersion=3,ownerId=tostring(player.UserId),initialCells=1771,revision=0,dugCells=0,movedCells=0,cells={},outbound={},imports={},collection={},artifact=false,accessMode="Closed",
			account={CapacityLevel=0,CapacityCells=20,CarriedCells=0,Coins=0,XP=0}}
		local batch=Instance.new("Folder")local count=0
		local function flush()
			batch.Parent=cells
			for _,part in batch:GetChildren()do part.Parent=cells end
			batch:Destroy()batch=Instance.new("Folder")count=0 task.wait()
		end
		for y=0,10 do for x=-(10-y),10-y do for z=-(10-y),10-y do
			local part=cellTemplate:Clone()part.Name=string.format("Cell_%d_%d_%d",x,y,z)
			part:SetAttribute("GridX",x)part:SetAttribute("GridY",y)part:SetAttribute("GridZ",z)
			part.Position=origin+offset+Vector3.new(x*2,y*2,z*2)part.Parent=batch
			table.insert(initial.cells,{x=x,y=y,z=z})count+=1
			if count==200 then flush()end
		end end end
		if count>0 then flush()end batch:Destroy()
		local station=stationTemplate:Clone()station.Parent=root
		station.SellPad.Position=Vector3.new(14,.5,-6)+offset
		station.UpgradePad.Position=Vector3.new(22,.5,-6)+offset
		local ref=Instance.new("ObjectValue")ref.Name="SandPrototypeMountain"ref.Value=mountain ref.Parent=player
		local function validate(raw)
			assert(raw.initialCells==1771 and #raw.cells+raw.dugCells==1771,"Experiment mass mismatch")return raw
		end
		local world=factory.Start({owner=player,mountain=mountain,station=station,persistent=false,key="unused",initial=initial,validate=validate})
		worlds[player]={world=world,mountain=mountain}
	end
	template:Destroy()stationTemplate:Destroy()cellTemplate:Destroy()
	waitUntil(function()for _,p in players do if not ready[p]or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart")then return false end end return true end,"Clients not ready")
	for _,p in players do
		local c=p.Character c.HumanoidRootPart.Anchored=true
		c.Humanoid:EquipTool(c:FindFirstChildOfClass("Tool")or p.Backpack:WaitForChild("Лопата",10))
		local target=worlds[p].mountain.Cells.Cell_0_0_10
		c.HumanoidRootPart.CFrame=CFrame.new(target.Position+Vector3.new(0,3,8),target.Position)
	end
	task.wait(2)
	phase="idle"remote:FireAllClients("phase","idle")task.wait(8)
	phase="dig"remote:FireAllClients("phase","dig")
	for round=1,10 do
		local targets={}
		for _,p in players do
			local m=worlds[p].mountain local target
			for _,cell in m.Cells:GetChildren()do if cell:GetAttribute("GridY")==0 and cell:GetAttribute("GridZ")==10 then target=cell break end end
			assert(target,"No exposed front cell")targets[p]=target
			p.Character.HumanoidRootPart.CFrame=CFrame.new(target.Position+Vector3.new(0,3,8),target.Position)
		end
		task.wait(.4)
		local sentAt=os.clock()
		for _,p in players do remote:FireClient(p,"dig",targets[p])end
		waitUntil(function()for _,p in players do if worlds[p].mountain:GetAttribute("DugCells")~=round then return false end end return true end,"Simultaneous round failed: "..round)
		table.insert(roundTimes,(os.clock()-sentAt)*1000)
		task.wait(.4)
	end
	phase=nil
	for _,p in players do remote:FireClient(p,"report")end
	waitUntil(function()for _,p in players do if not reports[p]then return false end end return true end,"Client reports missing")
	local output={initialTotal=7084,remainingTotal=0,carriedTotal=0,players={},serverTraffic={idle=summarize(traffic.idle),dig=summarize(traffic.dig)},roundCompletionMs=roundTimes}
	for _,p in players do
		local entry=worlds[p]local state=entry.world.GetAccount()local n=#entry.mountain.Cells:GetChildren()
		assert(n==1761 and reports[p].cells==n,"Client/server geometry mismatch")
		assert(reports[p].idle.count>=16 and reports[p].dig.count>=16,"Too few client traffic samples")
		assert(state.CarriedCells==10 and state.XP==10 and state.Coins==0,"Wrong personal reward")
		output.remainingTotal+=n output.carriedTotal+=state.CarriedCells
		table.insert(output.players,{userId=p.UserId,cells=n,clientCells=reports[p].cells,carried=state.CarriedCells,xp=state.XP,moved=entry.mountain:GetAttribute("MovedCells"),traffic={idle=reports[p].idle,dig=reports[p].dig}})
	end
	assert(output.remainingTotal+output.carriedTotal==7084,"Mass mismatch")
	return output
end)
for _,entry in worlds do entry.world.Close()end
StudioTest:EndTest({ok=ok,result=tostring(result),data=ok and result or nil})
