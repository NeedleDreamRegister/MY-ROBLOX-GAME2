-- Temporary Studio fixture; never install as production gameplay code.
if not game:GetService("RunService"):IsStudio()then return end
local remote=game.ReplicatedStorage:WaitForChild("FindHelperQA",20)
if not remote then return end
remote.OnClientEvent:Connect(function(command,target)
	if command=="open"then game.ReplicatedStorage.SandPrototypeAccess:FireServer("Open")
	elseif command=="dig"then game.ReplicatedStorage.SandPrototypeDig:FireServer(target)
	elseif command=="sell"then
		-- Allow the server teleport and the prompt's visible state to replicate.
		task.wait(0.4)
		local p=game.Players.LocalPlayer
		local prompt=p.SandPrototypeMountain.Value.Parent.SandPrototypeStation.SellPad.SellPrompt
		prompt:InputHoldBegin()task.wait(0.4)prompt:InputHoldEnd()
	end
end)
