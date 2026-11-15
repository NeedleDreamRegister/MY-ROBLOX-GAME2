-- Cosmetic-only accompaniment for the existing QG Touring shuttle.
-- Does not hide or replace the shuttle, seats, prompts, wheels or controller.
local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Presentation = require(ReplicatedStorage:WaitForChild("DTMCartPresentation"))
local previous = workspace:FindFirstChild("DTMTouringClientPresentation")
if previous then previous:Destroy() end
local folder = Instance.new("Folder")
folder.Name = "DTMTouringClientPresentation"
folder.Parent = workspace
local entries = {}
local alive = true
local connections = {}
local motorTemplate = ReplicatedStorage:FindFirstChild("DTMAudioLibrary")
motorTemplate = motorTemplate and motorTemplate:FindFirstChild("RemasterElectricMotor")

local function remove(entry)
	if entry.visual then entry.visual.Model:Destroy() entry.visual=nil end
	if entry.sound then entry.sound:Destroy() entry.sound=nil end
	entry.loading = false
	entry.audioReady = false
end

local function attachMotor(entry, source)
	-- Only use a Sound explicitly imported and validated by the installation.
	-- No fallback to an untested asset or an unrelated default sound.
	if not motorTemplate or not motorTemplate:IsA("Sound") or motorTemplate.SoundId=="" then return end
	if motorTemplate:GetAttribute("DTMValidated") ~= true then return end
	local mount = source:FindFirstChild("Chassis")
	if not mount then return end
	local sound = motorTemplate:Clone()
	sound.SoundGroup = game:GetService("SoundService"):FindFirstChild("DTMEffects")
	sound.Name = "DTMLocalTractionHum"
	sound.Volume = 0
	sound.Looped = true
	sound.PlaybackSpeed = .78
	sound.RollOffMinDistance = 6
	sound.RollOffMaxDistance = 42
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.EmitterSize = 4
	for _, child in sound:GetChildren() do child:Destroy() end
	local eq = Instance.new("EqualizerSoundEffect")
	eq.LowGain = -8
	eq.MidGain = -5
	eq.HighGain = -17
	eq.Parent = sound
	sound.Parent = mount
	entry.sound = sound
	entry.loading = true
	entry.audioReady = false
	task.spawn(function()
		local ok = pcall(function() ContentProvider:PreloadAsync({sound}) end)
		if not alive or entry.sound~=sound or not source.Parent then return end
		entry.loading = false
		entry.audioReady = ok and sound.IsLoaded and sound.TimeLength>0
	end)
end

local function watch(source)
	if not source:IsA("Model") or source:GetAttribute("TransitOnly")~=true or entries[source] then return end
	-- Template and Edit preview are never watched; only physical runtime carts.
	if not source:IsDescendantOf(workspace) or source:GetAttribute("TransitPreview")==true then return end
	entries[source] = {volume=0, speed=0, quietFor=0}
end
for _, source in workspace:GetDescendants() do watch(source) end
table.insert(connections,workspace.DescendantAdded:Connect(watch))

table.insert(connections,Run.RenderStepped:Connect(function(delta)
	local dt = math.min(delta,.1)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local nearest
	local nearestDistance = math.huge
	for source, entry in entries do
		local root = source:FindFirstChild("Chassis")
		if not source:IsDescendantOf(workspace) then remove(entry) entries[source]=nil
		elseif root and root:IsA("BasePart") then
			local distance = (camera.CFrame.Position-root.Position).Magnitude
			if distance<nearestDistance then nearestDistance=distance nearest=entry end
			entry.distance = distance
			if distance>165 then remove(entry)
			elseif not entry.visual then
				entry.visual = Presentation.Build()
				entry.visual.Model:PivotTo((source:FindFirstChild("BodyPivot") or root).CFrame)
				entry.visual.Model.Parent = folder
				attachMotor(entry,source)
			end
		end
	end
	local night = Lighting.ClockTime<6 or Lighting.ClockTime>18
	for source, entry in entries do
		if entry.visual then
			local body = source:FindFirstChild("BodyPivot") or source:FindFirstChild("Chassis")
			if body then
				-- Single anchored visual model follows the already animated body.
				-- No additional constraints, welds, network ownership or assembly mass.
				entry.visual.Model:PivotTo(body.CFrame)
				entry.visual.Update(source,dt,night)
			end
			local speed = math.max(0,tonumber(source:GetAttribute("CurrentSpeed")) or 0)
			entry.speed += (speed-entry.speed)*(1-math.exp(-4*dt))
			local distanceGain = math.clamp(1-(entry.distance-7)/35,0,1)
			distanceGain = distanceGain*distanceGain
			-- Just the nearest cart may hum. Silence at docks and past 42 studs.
			local moving = source:GetAttribute("CurrentState")=="Driving" and speed>.15
			local target = entry==nearest and moving and .075*math.clamp(entry.speed/12,0,1)*distanceGain or 0
			entry.volume += (target-entry.volume)*(1-math.exp(-(target>entry.volume and 2.4 or 5)*dt))
			local sound = entry.sound
			if sound and entry.audioReady then
				sound.Volume = entry.volume
				sound.PlaybackSpeed = .78+.24*math.clamp(entry.speed/18,0,1)
				if entry.volume>.0015 then
					entry.quietFor=0
					if not sound.IsPlaying then sound:Play() end
				else
					entry.quietFor+=dt
					if entry.quietFor>.8 and sound.IsPlaying then sound:Stop() end
				end
			end
		end
	end
end))

local function cleanup()
	if not alive then return end
	alive = false
	for _, connection in connections do connection:Disconnect() end
	for _, entry in entries do remove(entry) end
end
table.insert(connections,folder.Destroying:Connect(cleanup))
table.insert(connections,script.Destroying:Connect(function()
	cleanup()
	folder:Destroy()
end))