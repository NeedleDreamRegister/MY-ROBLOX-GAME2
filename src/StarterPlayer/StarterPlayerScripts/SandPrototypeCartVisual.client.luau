-- Smooth local presentation; the server root remains authoritative for movement and sales.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Appearance=require(game:GetService("ReplicatedStorage"):WaitForChild("SandPrototypeCartAppearance"))
local visuals=Instance.new("Folder")visuals.Name="SandPrototypeCartVisuals"visuals.Parent=workspace
local entries={}
local function removeVisual(entry)
	if not entry.visual then return end
	for part,value in entry.hidden do if part.Parent then part.LocalTransparencyModifier=value end end
	for gui,value in entry.guis do if gui.Parent then gui.Enabled=value end end
	for control,target in entry.targets do if control.Parent then control.Target=target end end
	entry.visual:Destroy()entry.visual=nil entry.targets={}
end
local function createVisual(entry,root)
	local visual=Appearance.Build()
	entry.wheelAnchor=visual:GetAttribute("WheelAnchor")
	entry.bodyRest=visual.PrimaryPart.CFrame:ToObjectSpace(visual.TrayBottom.CFrame)
	entry.loadBottom=visual:GetAttribute("LoadBottom")entry.loadRotation=visual:GetAttribute("LoadRotation")
	entry.loadSize=visual:GetAttribute("LoadSize")
	entry.wheels={}
	for _,part in visual:GetChildren()do if part:IsA("BasePart")and part:GetAttribute("WheelRotates")==true then
		entry.wheels[part]=visual.WheelTire.CFrame:ToObjectSpace(part.CFrame)
	end end
	entry.hidden={}entry.guis={}entry.targets={}
	for _,part in entry.source:GetDescendants()do
		if part:IsA("BasePart")then entry.hidden[part]=part.LocalTransparencyModifier part.LocalTransparencyModifier=1
		elseif part:IsA("SurfaceGui")then entry.guis[part]=part.Enabled part.Enabled=false end
	end
	entry.pose=root.CFrame entry.angle=entry.source:GetAttribute("WheelAngle")or 0
	entry.fill=(entry.source:GetAttribute("CartCells")or 0)/80
	visual.Name="WheelbarrowVisual_"..tostring(entry.source:GetAttribute("OwnerUserId"))
	visual:PivotTo(entry.pose)visual.Parent=visuals entry.visual=visual
end
-- Predict only the owner's presentation. The server still moves the sale/load root.
local function presentationTarget(entry,root)
	local source=entry.source
	local player=Players.LocalPlayer
	if source:GetAttribute("OwnerUserId")~=player.UserId or source:GetAttribute("Pushing")~=true
		or source:GetAttribute("Blocked")==true then return root.CFrame end
	local character=player.Character
	local part=character and character:FindFirstChild("HumanoidRootPart")
	if not part then return root.CFrame end
	local look=Vector3.new(part.CFrame.LookVector.X,0,part.CFrame.LookVector.Z)
	if look.Magnitude<0.1 then return root.CFrame end look=look.Unit
	if look:Dot(root.CFrame.LookVector)<0.9 then return root.CFrame end
	local desired=part.Position+look*1.5
	local delta=Vector3.new(desired.X-root.Position.X,0,desired.Z-root.Position.Z)
	-- Clamp continuously: falling back at a hard threshold makes each delayed
	-- replication packet pull the cart backwards during otherwise steady walking.
	if delta.Magnitude>5 then delta=delta.Unit*5 end
	if delta.Magnitude>0.01 then
		local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude
		local excluded={source,visuals}
		for _,other in Players:GetPlayers()do if other.Character then table.insert(excluded,other.Character)end end
		params.FilterDescendantsInstances=excluded params.RespectCanCollide=true
		if workspace:Blockcast(root.CFrame*entry.bodyRest+Vector3.new(0,0.65,0),source:GetAttribute("BodyBoxSize"),delta,params)
			or workspace:Spherecast((root.CFrame*entry.wheelAnchor).Position,source:GetAttribute("WheelRadius")*0.9,delta,params)then
			return root.CFrame
		end
	end
	return root.CFrame+delta
end
local function watch(model)
	if model:IsA("Model")and model:GetAttribute("GroundCart")==true and not entries[model]then entries[model]={source=model}end
end
local function watchPlots(plots)
	for _,plot in plots:GetChildren()do for _,child in plot:GetChildren()do watch(child)end end
	plots.DescendantAdded:Connect(watch)
end
local plots=workspace:FindFirstChild("SandPlots")
if plots then watchPlots(plots)end
workspace.ChildAdded:Connect(function(child)if child.Name=="SandPlots"then watchPlots(child)end end)
RunService.RenderStepped:Connect(function(dt)
	local camera=workspace.CurrentCamera
	for source,entry in entries do
		local root=source:FindFirstChild("GripRoot")
		if not source:IsDescendantOf(workspace)then removeVisual(entry)entries[source]=nil
		elseif root and camera then
			if(camera.CFrame.Position-root.Position).Magnitude>180 then removeVisual(entry)
			else
				if not entry.visual then createVisual(entry,root)end
				local alpha=1-math.exp(-28*math.min(dt,0.1))
				if(entry.pose.Position-root.Position).Magnitude>12 then entry.pose=root.CFrame end
				entry.pose=entry.pose:Lerp(presentationTarget(entry,root),alpha)
				entry.angle+=((source:GetAttribute("WheelAngle")or 0)-entry.angle)*alpha
				entry.fill+=((source:GetAttribute("CartCells")or 0)/80-entry.fill)*alpha
				local visual=entry.visual
				visual:PivotTo(entry.pose)
				local wheelFrame=entry.pose*entry.wheelAnchor*CFrame.Angles(entry.angle,0,0)
				for part,rest in entry.wheels do part.CFrame=wheelFrame*rest end
				local height=0.04+entry.loadSize.Y*entry.fill
				visual.SandLoad.Transparency=entry.fill<0.001 and 1 or 0
				visual.SandLoad.Size=Vector3.new(entry.loadSize.X,height,entry.loadSize.Z)
				visual.SandLoad.CFrame=entry.pose*CFrame.new(entry.loadBottom+Vector3.new(0,height/2,0))*entry.loadRotation
				local owner=Players:GetPlayerByUserId(source:GetAttribute("OwnerUserId"))
				local humanoid=owner and owner.Character and owner.Character:FindFirstChildOfClass("Humanoid")
				for _,side in {"Left","Right"}do
					local control=humanoid and humanoid:FindFirstChild("CartGrip"..side)
					if control then
						local target=visual["Handle"..side].GripTarget
						if not entry.targets[control]then entry.targets[control]=control.Target end
						if control.Target~=target then control.Target=target end
					end
				end
				for control in entry.targets do if not control.Parent then entry.targets[control]=nil end end
			end
		end
	end
end)
