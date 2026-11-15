-- Presentation only. No references to seats, prompts, route targets or physics.
-- Local coordinates were audited against QuarryTransit.CartTemplate QG Touring v2.
local Presentation = {}
local C = {
	forest = Color3.fromRGB(34, 65, 53),
	ivory = Color3.fromRGB(230, 220, 190),
	brass = Color3.fromRGB(171, 145, 89),
	dark = Color3.fromRGB(25, 36, 32),
	warm = Color3.fromRGB(255, 227, 172),
	green = Color3.fromRGB(149, 212, 160),
}

function Presentation.Build()
	local model = Instance.new("Model")
	model.Name = "DTMTouringPresentation"
	model:SetAttribute("DTMPresentationVersion", 1)
	local displays, bars, entryLights = {}, {}, {}
	local function part(name, size, cf, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local function textOn(p, face, caption, size)
		local surface = Instance.new("SurfaceGui")
		surface.Name = "FleetMarking"
		surface.Face = face
		surface.CanvasSize = Vector2.new(720, 150)
		surface.LightInfluence = .5
		surface.AlwaysOnTop = false
		surface.MaxDistance = 75
		surface.Parent = p
		local text = Instance.new("TextLabel")
		text.Name = "Caption"
		text.Size = UDim2.fromScale(.94, .9)
		text.Position = UDim2.fromScale(.03, .05)
		text.BackgroundTransparency = 1
		text.Text = caption
		text.TextColor3 = C.ivory
		text.Font = Enum.Font.GothamMedium
		text.TextSize = size or 42
		text.Parent = surface
		return text
	end
	local origin = part("PresentationOrigin", Vector3.new(.05,.05,.05), CFrame.identity, C.dark)
	origin.Transparency = 1
	model.PrimaryPart = origin

	-- Warm linen headliner, timber cross battens and inset brass fasteners.
	-- Existing three longitudinal teak rails remain exposed beneath this panel.
	part("LinenCanopyLiner", Vector3.new(5.65,.024,13.1), CFrame.new(0,6.34,.4), C.ivory, Enum.Material.Fabric)
	for _, z in {-5.65,-1.75,2.25,6.45} do
		part("CanopyCrossBatten", Vector3.new(5.65,.055,.095), CFrame.new(0,6.277,z), Color3.fromRGB(116,88,57), Enum.Material.Wood)
		for _, x in {-2.65,2.65} do
			local screw = part("BattenFixing", Vector3.new(.068,.018,.068), CFrame.new(x,6.242,z), C.brass, Enum.Material.Metal)
			screw.Shape = Enum.PartType.Ball
		end
	end
	for _, side in {-1,1} do
		-- Thin, recessed canopy seam, open cabin edges remain unobstructed.
		part("CanopyInsetSeam", Vector3.new(.045,.026,12.9), CFrame.new(side*2.72,6.312,.4), C.brass, Enum.Material.Metal)
		for _, z in {-1.95,2.4,6.55} do
			-- Safety nosings and small warm entry lenses, within original step width.
			part("StepSafetyNosing", Vector3.new(.055,.022,2.38), CFrame.new(side*3.405,.115,z), C.brass, Enum.Material.Metal)
			local lens = part("EntryCourtesyInset", Vector3.new(.025,.048,.62), CFrame.new(side*3.169,.08,z), C.warm, Enum.Material.Neon)
			lens.Transparency = .4
		end
		-- One light per side serves all three entry steps.
		local emitter = part("BoardingLightMount", Vector3.new(.03,.03,.03), CFrame.new(side*2.82,.39,2.3), C.dark)
		emitter.Transparency = 1
		local light = Instance.new("PointLight")
		light.Name = "BoardingPool"
		light.Color = C.warm
		light.Range = 5
		light.Brightness = 0
		light.Shadows = false
		light.Parent = emitter
		table.insert(entryLights, light)

		-- A single small fascia on each side replaces floating status text.
		local face = side<0 and Enum.NormalId.Left or Enum.NormalId.Right
		local panel = part("BoardingInformation", Vector3.new(.055,.56,3.6), CFrame.new(side*3.025,5.96,.15), C.forest)
		local caption = textOn(panel, face, "САДОВЫЙ КРУГ  ·  01", 36)
		table.insert(displays, caption)
		local bar = part("BoardingStatusLine", Vector3.new(.06,.033,3.38), CFrame.new(side*3.03,5.65,.15), C.brass, Enum.Material.Neon)
		table.insert(bars, bar)
		-- Muted amber side marker at the front, red rear reflector.
		for _, spec in {{-7.12,Color3.fromRGB(200,128,45)},{6.65,Color3.fromRGB(173,61,42)}} do
			part("ReflectorHousing", Vector3.new(.036,.21,.52), CFrame.new(side*3.18,.385,spec[1]), C.dark)
			part("InsetReflector", Vector3.new(.045,.115,.36), CFrame.new(side*3.20,.385,spec[1]), spec[2])
		end
		-- Small aft fleet panel, clear of existing QG Touring side badge.
		local fleet = part("FleetIdentity", Vector3.new(.026,.28,1.55), CFrame.new(side*2.847,1.24,6.73), C.forest)
		textOn(fleet,face,"01  ·  ELECTRIC",40)
		-- Coachwork joint / access hatch detail, under the rear row only.
		for _, z in {5.95,6.95} do
			part("RearServiceJoint", Vector3.new(.035,.5,.018), CFrame.new(side*2.849,.9,z), C.dark)
		end
	end
	-- Subtle, deeply inset rear cooling slots and a small zero-emission plaque.
	for i=-3,3 do
		part("BatteryVentRecess", Vector3.new(.19,.12,.014), CFrame.new(i*.29,.53,7.427), C.dark)
	end
	local rearBadge = part("RearElectricPlaque", Vector3.new(1.44,.16,.018), CFrame.new(0,1.43,7.402), C.forest)
	textOn(rearBadge,Enum.NormalId.Back,"QUIET ELECTRIC",42)

	local lastState
	local api = {Model=model}
	function api.Update(cart, dt, night)
		local docked = cart:GetAttribute("Docked") == true
		local free = math.clamp(tonumber(cart:GetAttribute("FreeSeats")) or 5,0,5)
		local state = docked and ("ПОСАДКА  ·  МЕСТ: "..free) or "САДОВЫЙ КРУГ  ·  01"
		if state ~= lastState then
			lastState = state
			for _, label in displays do label.Text = state end
			for _, bar in bars do bar.Color = docked and free>0 and C.green or C.brass end
		end
		local target = docked and (night and .32 or .10) or 0
		local alpha = 1-math.exp(-4*math.min(dt,.1))
		for _, light in entryLights do
			light.Brightness += (target-light.Brightness)*alpha
			light.Enabled = light.Brightness > .005
		end
	end
	return api
end

return Presentation