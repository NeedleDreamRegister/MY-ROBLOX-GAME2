-- Edit-mode migration of the temporary tool; preserves its input script.
assert(not game:GetService("RunService"):IsRunning(), "Build the shovel in Edit")
local pack=game:GetService("StarterPack")
local tool=pack:FindFirstChild("Лопата") or pack:FindFirstChild("SandProbe")
assert(tool and tool:IsA("Tool"), "Temporary sand tool missing")
assert(tool:FindFirstChild("SandProbeClient"), "Input script missing")
tool.Name="Лопата"
tool.ToolTip="Копай песок: клик мышью или касание горы"
tool:SetAttribute("SandPrototypeTool",true)
tool.CanBeDropped=false
tool.RequiresHandle=true
tool.Grip=CFrame.new(0,1.2,0)*CFrame.Angles(0,0,math.rad(-20))
if not tool:FindFirstChild("Handle") then
	local handle=Instance.new("Part")
	handle.Name="Handle"
	handle.Size=Vector3.new(0.25,3.6,0.25)
	handle.Material=Enum.Material.Wood
	handle.Color=Color3.fromRGB(134,90,52)
	handle.CFrame=CFrame.new(0,5,0)
	handle.Parent=tool
	local function piece(name,size,relative,color,material)
		local part=Instance.new("Part")
		part.Name=name part.Size=size part.Color=color part.Material=material
		part.CFrame=handle.CFrame*relative
		part.Parent=tool
		local weld=Instance.new("WeldConstraint")
		weld.Part0=handle weld.Part1=part weld.Parent=part
		return part
	end
	piece("Blade",Vector3.new(1.3,1.5,0.18),CFrame.new(0,-2.2,0.05)*CFrame.Angles(math.rad(12),0,0),Color3.fromRGB(111,126,139),Enum.Material.Metal)
	piece("GripBar",Vector3.new(0.85,0.18,0.3),CFrame.new(0,1.8,0),Color3.fromRGB(54,64,72),Enum.Material.SmoothPlastic)
end
for _,part in tool:GetChildren() do
	if part:IsA("BasePart") then
		part.Anchored=false part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Massless=true
	end
end
return tool:GetFullName()
