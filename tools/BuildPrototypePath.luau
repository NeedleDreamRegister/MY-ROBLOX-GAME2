-- Decorative route only; does not change cells, stations or saved data.
assert(not game:GetService("RunService"):IsRunning(), "Build the path in Edit")
if workspace:FindFirstChild("SandPrototypePath") then return "Path already exists" end
local cells = workspace.SandPrototype.Cells
local front = cells:FindFirstChild("Cell_0_0_4")
assert(front, "Initial mountain front missing")
local sale = workspace.SandPrototypeStation.SellPad
local path = Instance.new("Model")
path.Name = "SandPrototypePath"
local start = front.Position + Vector3.new(0, 0, 4)
local finish = sale.Position + Vector3.new(0, 0, 5)
local delta = Vector3.new(finish.X-start.X, 0, finish.Z-start.Z)
local count = math.max(1, math.ceil(delta.Magnitude / 3))
for i = 0, count do
	local point = start:Lerp(finish, i / count)
	local stone = Instance.new("Part")
	stone.Name = "Step_" .. i
	stone.Size = Vector3.new(2.8, 0.1, 1.7)
	stone.CFrame = CFrame.lookAt(Vector3.new(point.X, 0.06, point.Z), Vector3.new(point.X, 0.06, point.Z) + delta.Unit)
	stone.Material = Enum.Material.Slate
	stone.Color = Color3.fromRGB(183, 176, 149)
	stone.Anchored = true
	stone.CanCollide, stone.CanTouch, stone.CanQuery = false, false, false
	stone.Parent = path
end
path.Parent = workspace
return {path=path:GetFullName(),steps=#path:GetChildren()}
