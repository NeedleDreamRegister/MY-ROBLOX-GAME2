-- Visual shell for the shared test plot; no ownership or save migration.
assert(not game:GetService("RunService"):IsRunning(), "Build the plot in Edit")
if workspace:FindFirstChild("SandPrototypePlot") then return "Plot already exists" end
local plot = Instance.new("Model")
plot.Name = "SandPrototypePlot"
local function part(name, size, position, color, material)
	local item = Instance.new("Part")
	item.Name, item.Size, item.Position = name, size, position
	item.Color, item.Material = color, material
	item.Anchored = true
	item.CanCollide, item.CanTouch, item.CanQuery = false, false, false
	item.Parent = plot
	return item
end
part("Ground", Vector3.new(66,0.04,62), Vector3.new(-3,0.01,-23), Color3.fromRGB(107,133,91), Enum.Material.Grass)
local borderColor = Color3.fromRGB(152,149,131)
part("WestBorder",Vector3.new(0.4,0.5,62),Vector3.new(-36,0.25,-23),borderColor,Enum.Material.Slate)
part("EastBorder",Vector3.new(0.4,0.5,62),Vector3.new(30,0.25,-23),borderColor,Enum.Material.Slate)
part("NorthBorder",Vector3.new(66,0.5,0.4),Vector3.new(-3,0.25,-54),borderColor,Enum.Material.Slate)
-- Entrance opening towards the spawn.
part("SouthBorderLeft",Vector3.new(32,0.5,0.4),Vector3.new(-20,0.25,8),borderColor,Enum.Material.Slate)
part("SouthBorderRight",Vector3.new(22,0.5,0.4),Vector3.new(19,0.25,8),borderColor,Enum.Material.Slate)
local bay=part("EquipmentBay",Vector3.new(12,0.06,14),Vector3.new(19,0.035,-33),Color3.fromRGB(152,156,145),Enum.Material.Concrete)
for _, x in {-6,6} do
	part("BayEdge",Vector3.new(0.16,0.08,14),Vector3.new(19+x,0.1,-33),Color3.fromRGB(228,215,150),Enum.Material.SmoothPlastic)
end
local sign=part("EquipmentSign",Vector3.new(7,2,0.2),Vector3.new(19,2,-40),Color3.fromRGB(36,45,42),Enum.Material.Wood)
local surface=Instance.new("SurfaceGui")
surface.Name="SignText"
surface.Face=Enum.NormalId.Back
surface.CanvasSize=Vector2.new(560,160)
surface.Parent=sign
local text=Instance.new("TextLabel")
text.Size=UDim2.fromScale(1,1)
text.BackgroundTransparency=1
text.Text="МЕСТО ДЛЯ ТЕХНИКИ\nОборудование появится позже"
text.Font=Enum.Font.GothamBold
text.TextSize=25
text.TextColor3=Color3.fromRGB(242,235,201)
text.Parent=surface
plot.PrimaryPart=bay
plot.Parent=workspace
return {plot=plot:GetFullName(),parts=#plot:GetChildren()}
