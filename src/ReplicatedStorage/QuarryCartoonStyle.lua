-- Bright, visual-only quarry palette. Geometry, collisions and sand data stay intact.
local Style = {}

local VERSION = 2
local colors = {
	MeadowFacet = Color3.fromRGB(118, 181, 86),
	FrontMeadowVerge = Color3.fromRGB(114, 181, 82),
	ElectricCartLane = Color3.fromRGB(192, 169, 127),
	RoadFoundation = Color3.fromRGB(192, 169, 127),
	LimestoneFootway = Color3.fromRGB(249, 230, 187),
	FlatLaneDivider = Color3.fromRGB(235, 202, 132),
	FlushPathEdge = Color3.fromRGB(244, 217, 158),
	LowLimestonePathEdge = Color3.fromRGB(244, 217, 158),
	GrassBlade = Color3.fromRGB(91, 169, 75),
	GardenFoliage = Color3.fromRGB(83, 169, 95),
	SageCushion = Color3.fromRGB(91, 163, 105),
	SageLeafSprays = Color3.fromRGB(94, 167, 102),
	leaves_geom = Color3.fromRGB(102, 180, 87),
}

function Style.ApplyWorld()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 16.15
	lighting.Brightness = 2.35
	local grade = lighting:FindFirstChild("DTM_ColorGrade")
	if grade and grade:IsA("ColorCorrectionEffect") then
		grade.Saturation = 0.17
		grade.Contrast = 0.11
		grade.TintColor = Color3.fromRGB(255, 248, 231)
	end
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = Color3.fromRGB(247, 234, 205)
		atmosphere.Decay = Color3.fromRGB(214, 182, 129)
		atmosphere.Density = 0.2
		atmosphere.Haze = 0.75
	end
	workspace.Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(240, 204, 134))
end

local function addEntranceMarkers(garden)
	local rear = garden:GetAttribute("RearClearingWest")
	if typeof(rear) ~= "Vector3" or garden:FindFirstChild("CartoonEntryMarkers") then
		return
	end
	local offset = rear - Vector3.new(-145, 0, -490)
	local root = Instance.new("Model")
	root.Name = "CartoonEntryMarkers"
	root:SetAttribute("VisualOnly", true)
	local function part(name, size, cf, color, material)
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.CFrame = cf
		item.Color = color
		item.Material = material
		item.Anchored = true
		item.CanCollide = false
		item.CanTouch = false
		item.CanQuery = false
		item.CastShadow = true
		item.Parent = root
		return item
	end
	for _, marker in ipairs({
		{-42, 14, 1.4, Color3.fromRGB(246, 110, 82)},
		{76, 15, 1.25, Color3.fromRGB(52, 183, 171)},
	}) do
		local x, z, y, cloth = marker[1], marker[2], marker[3], marker[4]
		local base = offset + Vector3.new(x, y, z)
		part("MarkerFoot", Vector3.new(1.5, 0.5, 1.5), CFrame.new(base + Vector3.new(0, 0.25, 0)), Color3.fromRGB(244, 219, 155), Enum.Material.Limestone)
		part("MarkerPole", Vector3.new(0.3, 11, 0.3), CFrame.new(base + Vector3.new(0, 6, 0)), Color3.fromRGB(125, 78, 51), Enum.Material.Wood)
		part("MarkerCrossbar", Vector3.new(3.3, 0.18, 0.18), CFrame.new(base + Vector3.new(1.5, 11.2, 0)), Color3.fromRGB(251, 205, 95), Enum.Material.Wood)
		part("MarkerBanner", Vector3.new(2.4, 3.4, 0.12), CFrame.new(base + Vector3.new(1.65, 9.5, 0)), cloth, Enum.Material.Fabric)
		part("MarkerBannerStripe", Vector3.new(2.42, 0.25, 0.14), CFrame.new(base + Vector3.new(1.65, 10.7, 0)), Color3.fromRGB(255, 244, 194), Enum.Material.Fabric)
		local finial = part("MarkerFinial", Vector3.new(0.6, 0.6, 0.6), CFrame.new(base + Vector3.new(0, 11.5, 0)), Color3.fromRGB(255, 210, 91), Enum.Material.Metal)
		finial.Shape = Enum.PartType.Ball
	end
	root.Parent = garden
end

function Style.ApplySite(garden)
	if garden:GetAttribute("CartoonStyleVersion") == VERSION then
		return 0
	end
	local changed = 0
	for index, instance in ipairs(garden:GetDescendants()) do
		if instance:IsA("BasePart") then
			local target = colors[instance.Name]
			if target then
				-- Keep a little variation from the original garden instead of one flat green.
				instance.Color = target:Lerp(instance.Color, 0.12)
				changed += 1
			end
		end
		if index % 250 == 0 then task.wait() end
	end
	addEntranceMarkers(garden)
	garden:SetAttribute("CartoonStyleVersion", VERSION)
	return changed
end

return Style
