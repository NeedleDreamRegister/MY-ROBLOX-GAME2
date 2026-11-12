-- Temporary Studio fixture. Requires two local clients and persistence disabled.
local test=game:GetService("StudioTestService")
if not game:GetService("RunService"):IsStudio()or test:GetTestArgs()~="FindHelperSmoke"then return end
local function waitUntil(condition,seconds,message)
	local deadline=os.clock()+seconds
	while not condition()and os.clock()<deadline do task.wait(0.05)end
	assert(condition(),message)
end
local ok,result=pcall(function()
	assert(game.ServerScriptService.SandPrototype:GetAttribute("PersistenceEnabled")==false,"Disable persistence for local QA")
	local remote=Instance.new("RemoteEvent")remote.Name="FindHelperQA"remote.Parent=game.ReplicatedStorage
	local players=game:GetService("Players")
	waitUntil(function()
		if #players:GetPlayers()~=2 then return false end
		for _,p in players:GetPlayers()do if not p:FindFirstChild("SandPrototypeState")or not p.Character then return false end end
		return true
	end,30,"Players not ready")
	local owner=players:GetPlayerByUserId(-1)
	local helper=players:GetPlayerByUserId(-2)
	assert(owner and helper,"Use local simulated clients")
	local source=owner.SandPrototypeMountain.Value
	local relic=source.Cells.Cell_0_1_0
	for _,p in{owner,helper}do p.Character:WaitForChild("HumanoidRootPart").Anchored=true end
	owner.Character.HumanoidRootPart.CFrame=source.Parent.SpawnLocation.CFrame+Vector3.new(0,4,0)
	helper.Character.Humanoid:EquipTool(helper.Backpack:WaitForChild("Лопата"))
	task.wait(0.5)
	remote:FireClient(owner,"open")
	waitUntil(function()return source:GetAttribute("AccessMode")=="Open"end,4,"Owner did not open plot")
	local function sell()
		local pad=helper.SandPrototypeMountain.Value.Parent.SandPrototypeStation.SellPad
		helper.Character.HumanoidRootPart.CFrame=CFrame.new(pad.Position+Vector3.new(0,3,4),pad.Position)
		remote:FireClient(helper,"sell")
		waitUntil(function()return helper.SandPrototypeState:GetAttribute("CarriedCells")==0 end,4,"Sell failed")
	end
	local function aim(target)
		helper.Character.HumanoidRootPart.CFrame=CFrame.new(target.Position+Vector3.new(0,9,0))
	end
	-- First request prepares the durable source subscription, without mining.
	local top=source.Cells:FindFirstChild("Cell_-1_3_0")assert(top)
	aim(top)remote:FireClient(helper,"dig",top)task.wait(0.5)
	local digs=0
	local function dig(target)
		if helper.SandPrototypeState:GetAttribute("CarriedCells")>=20 then sell()end
		aim(target)
		local before=source:GetAttribute("DugCells")
		remote:FireClient(helper,"dig",target)
		waitUntil(function()return source:GetAttribute("DugCells")==before+1 end,3,"Dig rejected")
		digs+=1 task.wait(0.18)
	end
	while relic:GetAttribute("GridX")==0 and relic:GetAttribute("GridY")==1 and digs<60 do
		local target
		for y=3,0,-1 do target=source.Cells:FindFirstChild("Cell_-1_"..y.."_0")if target then break end end
		assert(target)dig(target)
	end
	assert(relic:GetAttribute("GridX")==-1 and relic:GetAttribute("GridY")==0,"Artifact did not follow falling mass")
	assert(helper.SandPrototypeState:GetAttribute("FindCount")==0,"Awarded before item cell removal")
	local movedName=relic.Name
	dig(relic)
	waitUntil(function()return helper.SandPrototypeState:GetAttribute("FindCount")==1 end,3,"Helper find not delivered")
	assert(owner.SandPrototypeState:GetAttribute("FindCount")==0,"Owner stole helper find")
	assert(helper.SandPrototypeMountain.Value:GetAttribute("RemainingCells")==165,"Helper mountain changed")
	sell()
	assert(helper.SandPrototypeState:GetAttribute("FindCount")==1,"Selling lost collectible")
	return{dug=source:GetAttribute("DugCells"),remaining=source:GetAttribute("RemainingCells"),movedName=movedName,
		helper=helper.SandPrototypeState:GetAttributes(),museum=helper.SandPrototypeMountain.Value.Parent.Museum:GetAttribute("FindCount")}
end)
test:EndTest({ok=ok,result=result})
