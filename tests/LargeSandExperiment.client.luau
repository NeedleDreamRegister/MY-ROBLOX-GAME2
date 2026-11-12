-- Temporary input fixture for the non-persistent large-mountain experiment.
if not game:GetService("RunService"):IsStudio()then return end
local remote=game.ReplicatedStorage:WaitForChild("LargeSandQA",20)
if remote then remote.OnClientEvent:Connect(function(target)game.ReplicatedStorage.SandPrototypeDig:FireServer(target)end)end
