-- Temporary Studio multiplayer fixture, never ship.
if not game:GetService("RunService"):IsStudio()then return end
local player=game.Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild("FourLargeQA",30)
assert(remote,"Missing QA remote")
local phase
local samples={idle={},dig={}}
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
		if phase then table.insert(samples[phase],{receive=stats.DataReceiveKbps,send=stats.DataSendKbps})end
		task.wait(.25)
	end
end)
remote.OnClientEvent:Connect(function(action,target)
	if action=="phase"then phase=target
	elseif action=="dig"then game.ReplicatedStorage.SandPrototypeDig:FireServer(target)
	elseif action=="report"then
		phase=nil
		task.wait(1)
		local m=player:WaitForChild("SandPrototypeMountain").Value
		remote:FireServer("report",{cells=m and #m.Cells:GetChildren(),idle=summarize(samples.idle),dig=summarize(samples.dig)})
	end
end)
remote:FireServer("ready")
