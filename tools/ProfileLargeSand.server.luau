-- execute_luau in Server, after installing the isolated LargeSandExperiment fixtures.
assert(workspace.SandPrototype:GetAttribute("InitialCells")==1771 and workspace.SandPrototype:GetAttribute("PersistenceStatus")=="SessionOnly","Large non-persistent experiment only")
local mp=require("@rbx/LibMP")
assert(mp.Control:IsBackendReady())
mp.Control:EnableProfiler(true)mp.Control:SetFrameLimit(128)mp.Control:EnableCapture(true)
local session
local ok,result=pcall(function()
	local player=game.Players:GetPlayers()[1]
	local character=player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("HumanoidRootPart").Anchored=true
	character.Humanoid:EquipTool(character:FindFirstChildOfClass("Tool")or player.Backpack:WaitForChild("Лопата"))
	local mountain=workspace.SandPrototype
	for _=1,10 do
		local target
		for _,cell in mountain.Cells:GetChildren()do
			if cell:IsA("BasePart")and cell:GetAttribute("GridY")==0 and cell:GetAttribute("GridZ")==10 then target=cell break end
		end
		assert(target,"No exposed front cell")
		character.HumanoidRootPart.CFrame=CFrame.new(target.Position+Vector3.new(0,3,8),target.Position)
		local before=mountain:GetAttribute("DugCells")
		game.ReplicatedStorage.LargeSandQA:FireClient(player,target)
		local deadline=os.clock()+2
		while mountain:GetAttribute("DugCells")==before and os.clock()<deadline do task.wait(0.05)end
		assert(mountain:GetAttribute("DugCells")==before+1,"Large dig failed")task.wait(0.18)
	end
	local bufferData=mp.Control:CaptureToBufferSync()
	mp.Control:EnableCapture(false)
	session=assert(mp.Session.OpenFromBuffer(bufferData))
	local timer=session:FindTimerId("DigMountain.Mutate")assert(timer~=0,"Mutation scope not captured")
	local scale=session:FetchGlobalDesc().TickToMsCpu
	local first,last=session:GetFrameIdMin(),session:GetFrameIdMax()
	local iter=session:CreateLogIterator()
	iter:Configure({StartFrameId=first,EndFrameId=last,TimerIds={timer},SkipGpuThreads=true,SkipEvents=true,SkipPausedFrames=true})
	local state=iter:GetState()
	local values={}
	while iter:Step()do
		if state:IsExit()and not state:ThreadStackIsUnderflowed()and not state:ThreadStackWasOverflowed()then
			local element=iter:GetCurrentThreadStackElement(state:ThreadStackDepth())
			if element and state:Timestamp()>=element:EnterTimestamp()then table.insert(values,(state:Timestamp()-element:EnterTimestamp())*scale)end
		end
	end
	iter:Dispose()
	assert(#values>=4,"Too few mutation samples")table.sort(values)
	return{initial=1771,remaining=mountain:GetAttribute("RemainingCells"),dug=mountain:GetAttribute("DugCells"),moved=mountain:GetAttribute("MovedCells"),
		profile=player.SandPrototypeState:GetAttributes(),samples=#values,medianMutationMs=values[math.ceil(#values*0.5)],
		p95MutationMs=values[math.ceil(#values*0.95)],maxMutationMs=values[#values],firstFrame=first,lastFrame=last,
		firstAbsoluteFrame=session:FetchFrameDesc(first).FrameAbsoluteId,lastAbsoluteFrame=session:FetchFrameDesc(last).FrameAbsoluteId}
end)
if session then session:Dispose()end
mp.Control:EnableCapture(false)
assert(ok,result)
return result
