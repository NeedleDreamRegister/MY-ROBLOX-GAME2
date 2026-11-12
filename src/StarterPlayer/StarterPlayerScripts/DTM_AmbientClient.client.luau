-- Ambient sounds: wind + ocean. Мягкая атмосфера, отключается кнопкой M.
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local group = SoundService:WaitForChild("Ambient")
local sounds = {
	{ id = "rbxassetid://3308152153", volume = 0.12, name = "Wind" },
	{ id = "rbxassetid://94143372522318", volume = 0.08, name = "Ocean" },
}
for _, data in sounds do
	local sound = Instance.new("Sound")
	sound.Name = "Ambient_" .. data.name
	sound.SoundId = data.id
	sound.Volume = data.volume
	sound.Looped = true
	sound.SoundGroup = group
	sound.Parent = SoundService
	sound:Play()
end

-- Кнопка/клавиша M: включить/выключить атмосферу
local enabled = true
local function updateAudio()
	group.Volume = enabled and 1 or 0
	player:SetAttribute("AmbientEnabled", enabled)
end
updateAudio()

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.M then
		enabled = not enabled
		updateAudio()
	end
end)