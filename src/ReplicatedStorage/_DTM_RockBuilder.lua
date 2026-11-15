local RNG = Random.new(5150)
local CX, CZ = 84, 26
local BX0, BX1, BZ0, BZ1 = -133, 301, -199, 251

local function boxDist(x, z)
	local dx = math.max(BX0 - x, 0, x - BX1)
	local dz = math.max(BZ0 - z, 0, z - BZ1)
	return math.sqrt(dx*dx + dz*dz)
end

local function plateOK(x, z, pad)
	return math.abs(x) < 1024 - pad and math.abs(z) < 1024 - pad
end

local function newFolder(name)
	local env = workspace.DTM_Environment
	local f = env:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = env
	end
	for _, c in ipairs(f:GetChildren()) do c:Destroy() end
	return f
end

local function rocky(name, size, pos, rotY, tilt, mat, col)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Block
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = mat
	p.Color = col
	p.CFrame = CFrame.new(pos) * CFrame.Angles(tilt, rotY, tilt * 0.6)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Scale = Vector3.new(1, 1, 1)
	m.Parent = p
	return p
end

local M = {RNG = RNG, boxDist = boxDist, plateOK = plateOK, newFolder = newFolder, rocky = rocky, CX = CX, CZ = CZ}
local function cyl(name, H, D, pos, rotY, mat, col)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(H, D, D)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = mat
	p.Color = col
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, rotY, math.rad(90))
	return p
end

function M.mesas(count)
	local f = M.newFolder("Mesas")
	local sand = Color3.fromRGB(223, 200, 158)
	local c1 = Color3.fromRGB(166, 136, 104)
	local c2 = Color3.fromRGB(188, 156, 120)
	local c3 = Color3.fromRGB(210, 180, 140)
	local made, tries = 0, 0
	while made < count and tries < 200 do
		tries = tries + 1
		local a = RNG:NextNumber() * math.pi * 2
		local r = 620 + RNG:NextNumber() * 330
		local x, z = CX + math.cos(a) * r, CZ + math.sin(a) * r
		if M.boxDist(x, z) > 340 and M.plateOK(x, z, 300) then
			local w = 150 + RNG:NextNumber() * 150
			local h = 38 + RNG:NextNumber() * 34
			local rot = RNG:NextNumber() * 3
			local p = M.rocky("MesaSkirt", Vector3.new(w * 2.1, h * 1.0, w * 1.8), Vector3.new(x, h * 0.02, z), rot, 0, Enum.Material.Sand, sand)
			p.Parent = f
			cyl("MesaBase", h * 0.55, w, Vector3.new(x, h * 0.27, z), rot, Enum.Material.Sandstone, c1).Parent = f
			cyl("MesaBand", h * 0.07, w * 0.9, Vector3.new(x, h * 0.57, z), rot, Enum.Material.Slate, Color3.fromRGB(140, 112, 86)).Parent = f
			cyl("MesaStep", h * 0.36, w * 0.78, Vector3.new(x, h * 0.77, z), rot, Enum.Material.Sandstone, c2).Parent = f
			cyl("MesaCap", h * 0.3, w * 0.56, Vector3.new(x, h * 1.12, z), rot, Enum.Material.Sandstone, c3).Parent = f
			made = made + 1
		end
	end
	return made, #f:GetChildren()
end

function M.rocks(count)
	local f = M.newFolder("Boulders")
	local made, tries = 0, 0
	while made < count and tries < 1500 do
		tries = tries + 1
		local a = RNG:NextNumber() * math.pi * 2
		local r = 200 + RNG:NextNumber() * 760
		local x, z = CX + math.cos(a) * r, CZ + math.sin(a) * r
		if M.boxDist(x, z) > 110 and M.plateOK(x, z, 80) then
			local k = 1 + RNG:NextInteger(0, 2)
			for i = 1, k do
				local s = 5 + RNG:NextNumber() * 15
				local g = RNG:NextInteger(-16, 16)
				local col = Color3.fromRGB(150 + g, 132 + g, 112 + g)
				local p = M.rocky("Boulder", Vector3.new(s * (1 + RNG:NextNumber() * 0.8), s * (0.7 + RNG:NextNumber() * 0.5), s * (0.85 + RNG:NextNumber() * 0.7)), Vector3.new(x + (RNG:NextNumber() - 0.5) * s * 2.4, s * 0.3, z + (RNG:NextNumber() - 0.5) * s * 2.4), RNG:NextNumber() * 6.28, (RNG:NextNumber() - 0.5) * 0.5, Enum.Material.Slate, col)
				p.Parent = f
				made = made + 1
			end
		end
	end
	return made, #f:GetChildren()
end

return M
