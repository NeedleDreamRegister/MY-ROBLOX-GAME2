-- Studio Play only, with SandPrototype.Enabled=false. Uses an in-memory store.
-- Run this as a temporary ModuleScript and call the returned function. Fire one
-- client dig at ownerId=LocalPlayer.UserId,x=6,y=0,z=0, then call result.Finish().
return function()
	local p=assert(game.Players:GetPlayers()[1])
	game.Players.CharacterAutoLoads=false
	local origin=Vector3.new(602,2,-66)
	local character=Instance.new("Model")character.Name="QACharacter"
	for _,name in {"HumanoidRootPart","Torso","Head"}do
		local part=Instance.new("Part")part.Name=name part.Anchored=true
		part.Size=name=="Head"and Vector3.new(2,1,1)or Vector3.new(2,2,1)
		part.Position=origin+Vector3.new(32,name=="Head"and 5.5 or 4,0)part.Parent=character
	end
	local humanoid=Instance.new("Humanoid")humanoid.RequiresNeck=false humanoid.Parent=character
	character.PrimaryPart=character.HumanoidRootPart character.Parent=workspace p.Character=character
	local tool=Instance.new("Tool")tool.Name="QAProbe"tool.RequiresHandle=false
	tool:SetAttribute("SandPrototypeTool",true)tool.Parent=character
	local scripts=game.ServerScriptService
	assert(not scripts:FindFirstChild("QAInMemoryStore"))
	local stub=Instance.new("ModuleScript")stub.Name="QAInMemoryStore"
	stub.Source=[[
	local store={records={}}
	local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
	function store:UpdateAsync(key,cb)local nextValue=cb(copy(self.records[key]))if nextValue then self.records[key]=copy(nextValue)end return copy(nextValue)end
	return store
	]]stub.Parent=scripts
	local cloned=scripts.SandPrototypeWorld:Clone()cloned.Name="QADeferredWorld"
	local source=cloned.Source
	local needle='local store = game:GetService("DataStoreService"):GetDataStore("DigMountainPlots_v1")'
	local first,last=source:find(needle,1,true)assert(first,"store injection point changed")
	cloned.Source=source:sub(1,first-1).."local store=require(script.Parent.QAInMemoryStore)"..source:sub(last+1)
	cloned.Parent=scripts
	local World=require(cloned)
	local Finds=require(scripts.SandPrototypeFindData)
	local initial=assert(Finds.Validator(p.UserId)(require(scripts.SandPrototypePlotData).Fresh()))
	local function create()
		local mountain=workspace.SandPrototype:Clone()mountain.Name="DeferredQAWorld"
		mountain:SetAttribute("TerrainOrigin",origin)mountain:SetAttribute("OwnerUserId",p.UserId)
		for _,v in mountain.Cells:GetChildren()do if v:IsA("BasePart")then
			v.Position=origin+Vector3.new(v:GetAttribute("GridX"),v:GetAttribute("GridY"),v:GetAttribute("GridZ"))*4 v.Size=Vector3.new(4,4,4)
		end end
		mountain.Parent=workspace
		local station=workspace.SandPrototypeStation:Clone()station.Name="DeferredQAStation"station.Parent=workspace
		local world=assert(World.Start({owner=p,mountain=mountain,station=station,persistent=true,terrain=true,initial=initial,key="isolated-world",validate=Finds.Validator(p.UserId)}))
		return {world=world,mountain=mountain,station=station}
	end
	local firstWorld=create()
	local blocker=Instance.new("Part")blocker.Name="QACharacterOccupancy"blocker.Anchored=true blocker.CanCollide=false
	blocker.Size=Vector3.new(2,3,2)blocker.Position=origin+Vector3.new(24,0,0)blocker.Parent=character
	local result={mountain=firstWorld.mountain,character=character,humanoid=humanoid}
	function result.Finish()
		assert(firstWorld.mountain:GetAttribute("DugCells")==1 and firstWorld.mountain:GetAttribute("MovedCells")==0,"blocked dig not reproduced")
		assert(firstWorld.world.Close())
		local raw=require(stub).records["isolated-world"]
		assert(raw.formatVersion==2 and #raw.snapshot.pendingCollapses==1 and raw.snapshot.pendingCollapses[1].budget==6,"pending not captured at World.Close")
		firstWorld.mountain:Destroy()firstWorld.station:Destroy()
		local restored=create()task.wait(0.4)
		assert(restored.mountain:GetAttribute("DugCells")==1 and restored.mountain:GetAttribute("MovedCells")==0 and restored.mountain:GetAttribute("PendingCollapses")==1,"pending not restored by World.Start")
		blocker:Destroy()task.wait(0.7)
		assert(restored.mountain:GetAttribute("MovedCells")==6 and restored.mountain:GetAttribute("PendingCollapses")==0,"restored queue did not resume")
		assert(restored.world.Close())raw=require(stub).records["isolated-world"]
		assert(raw.snapshot.dugCells==1 and raw.snapshot.movedCells==6 and raw.snapshot.account.XP==1 and raw.snapshot.account.CarriedCells==1 and #raw.snapshot.pendingCollapses==0)
		restored.mountain:Destroy()restored.station:Destroy()
		return {worldCloseAndStart=true,moved=6,dug=1,xp=1,carried=1,pending=0,productionCalls=0,inMemoryStore=true}
	end
	return result
end
