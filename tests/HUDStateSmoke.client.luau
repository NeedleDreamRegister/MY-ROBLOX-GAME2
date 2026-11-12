-- Run through execute_luau in Client during an isolated, non-persistent Play.
-- Only local replicated attributes are changed; no remotes or DataStores used.
local player = game:GetService("Players").LocalPlayer
assert(player, "Run in Client")
local mountain = require(game.ReplicatedStorage.SandPrototypeClientContext).GetMountain(player)
assert(mountain:GetAttribute("PersistenceStatus") == "SessionOnly", "Use an isolated non-persistent Play")
local state = player:WaitForChild("SandPrototypeState")
local card = player.PlayerGui:WaitForChild("SandPrototypeHUD"):WaitForChild("InventoryCard")
local originalStatus = mountain:GetAttribute("PersistenceStatus")
local originalCarried = state:GetAttribute("CarriedCells")
local originalCapacity = state:GetAttribute("CapacityCells")
local originalCoins = state:GetAttribute("Coins")
local originalXP = state:GetAttribute("XP")
local originalLevel = state:GetAttribute("CapacityLevel")
local passed = 0
local ok, reason = pcall(function()
	for _, status in { "Loading", "Saved", "Dirty", "Saving", "SessionOnly", "SaveFailed", "Locked", "LoadFailed", "LockLost" } do
		for _, carried in { 0, 1, originalCapacity } do
			mountain:SetAttribute("PersistenceStatus", status)
			state:SetAttribute("CarriedCells", carried)
			task.wait(0.05)
			local halted = status == "Loading" or status == "SaveFailed" or status == "Locked" or status == "LoadFailed" or status == "LockLost"
			if halted then
				assert(not string.find(card.Hint.Text, "копать", 1, true), status .. " still suggests digging")
				assert(not string.find(card.Hint.Text, "продай", 1, true), status .. " still suggests selling")
				assert(card.Hint.Text ~= "Зелёная станция покупает песок", status .. " still suggests a station action")
			end
			for _, label in card:GetChildren() do
				if label:IsA("TextLabel") then
					assert(label.TextFits, status .. "/" .. carried .. ": " .. label.Name .. " overflows")
				end
			end
			assert(state:GetAttribute("Coins") == originalCoins and state:GetAttribute("XP") == originalXP, "HUD changed rewards")
			assert(state:GetAttribute("CapacityCells") == originalCapacity and state:GetAttribute("CapacityLevel") == originalLevel, "HUD changed capacity")
			passed += 1
		end
	end
end)
mountain:SetAttribute("PersistenceStatus", originalStatus)
state:SetAttribute("CarriedCells", originalCarried)
task.wait()
assert(ok, reason)
return { passed = passed, viewport = tostring(workspace.CurrentCamera.ViewportSize), card = tostring(card.AbsoluteSize) }
