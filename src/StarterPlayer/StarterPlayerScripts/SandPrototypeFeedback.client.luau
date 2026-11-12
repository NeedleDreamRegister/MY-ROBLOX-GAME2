-- Cosmetic only. Inventory and geometry are owned by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Context=require(ReplicatedStorage:WaitForChild("SandPrototypeClientContext"))
local mountain = Context.GetMountain(player)
local cells = mountain:WaitForChild("Cells")
local digEvent = ReplicatedStorage:WaitForChild("SandPrototypeDig")
local digSoundTemplate = ReplicatedStorage:FindFirstChild("DTM_Sounds")
	and ReplicatedStorage.DTM_Sounds:FindFirstChild("DigSound")

local effects = Instance.new("Folder")
effects.Name = "SandPrototypeLocalEffects"
effects.Parent = workspace
local highlight = Instance.new("Highlight")
highlight.Name = "DigTarget"
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.FillTransparency = 0.85
highlight.OutlineColor = Color3.fromRGB(255, 233, 163)
highlight.FillColor = highlight.OutlineColor
highlight.Enabled = false
highlight.Parent = effects
local terrainSelection=Instance.new("SelectionBox")
terrainSelection.Name="TerrainDigTarget"terrainSelection.LineThickness=0.025
terrainSelection.Color3=highlight.OutlineColor terrainSelection.SurfaceTransparency=1 terrainSelection.Parent=effects
local terrainMarker=Instance.new("Part")terrainMarker.Name="TerrainTargetMarker"
terrainMarker.Anchored=true terrainMarker.Transparency=1
terrainMarker.CanCollide=false terrainMarker.CanTouch=false terrainMarker.CanQuery=false
terrainMarker.Size=Vector3.new(4,4,4)terrainMarker.Parent=effects

-- Успешный раскоп: короткая вспышка света только после серверного подтверждения.
local function playSuccessFlash(position)
	local flash = Instance.new("PointLight")
	flash.Name = "DigFlash"
	flash.Brightness = 4
	flash.Range = 10
	flash.Color = Color3.fromRGB(255, 233, 163)
	flash.Shadows = false
	flash.Parent = effects
	local anchor = Instance.new("Part")
	anchor.Name = "DigFlashAnchor"
	anchor.Anchored = true
	anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = position
	anchor.Parent = effects
	flash.Parent = anchor
	local tween = TweenService:Create(flash, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 })
	tween:Play()
	tween.Completed:Once(function() anchor:Destroy() end)
	Debris:AddItem(anchor, 0.4)
end

local gui = Instance.new("ScreenGui")
gui.Name = "SandPrototypeFeedback"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.Parent = player:WaitForChild("PlayerGui")
local aimDot=Instance.new("Frame")aimDot.Name="CenterAim"
aimDot.AnchorPoint=Vector2.new(0.5,0.5)aimDot.Size=UDim2.fromOffset(6,6)
aimDot.BackgroundColor3=highlight.OutlineColor aimDot.BorderSizePixel=0 aimDot.Visible=false aimDot.Parent=gui
local aimCorner=Instance.new("UICorner")aimCorner.CornerRadius=UDim.new(1,0)aimCorner.Parent=aimDot
local aimStroke=Instance.new("UIStroke")aimStroke.Color=Color3.fromRGB(24,31,39)aimStroke.Thickness=1.5 aimStroke.Parent=aimDot
local toast = Instance.new("TextLabel")
toast.Name = "DigToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0.25, 0)
toast.Size = UDim2.fromOffset(240, 30)
toast.BackgroundColor3 = Color3.fromRGB(24, 31, 39)
toast.BackgroundTransparency = 0.15
toast.TextColor3 = Color3.fromRGB(255, 233, 163)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 18
toast.TextScaled = true
toast.Text = "+1 песок"
toast.Visible = false
toast.Parent = gui
local toastSize = Instance.new("UITextSizeConstraint")
toastSize.MinTextSize = 14
toastSize.MaxTextSize = 18
toastSize.Parent = toast
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toast
local toastSequence, activeBursts, activeDigSounds = 0, 0, 0
local random = Random.new()

local function showToast(message)
	toast.Text = message
	toastSequence += 1
	local sequence = toastSequence
	toast.Visible = true
	task.delay(0.8, function()
		if sequence == toastSequence then toast.Visible = false end
	end)
end

local actionHint=Instance.new("BindableEvent")
actionHint.Name="ActionHint"actionHint.Parent=gui
actionHint.Event:Connect(showToast)

local function coinWord(amount)
	local lastTwo=amount%100
	if lastTwo>=11 and lastTwo<=14 then return "монет" end
	local last=amount%10
	if last==1 then return "монета" end
	if last>=2 and last<=4 then return "монеты" end
	return "монет"
end

-- State attributes are replicated after the server has accepted a sale or purchase.
-- Coalesce the attribute changes before comparing them to avoid partial updates.
task.spawn(function()
	local state = player:WaitForChild("SandPrototypeState")
	local previous, queued
	local function read()
		local carried=state:GetAttribute("CarriedCells")
		local coins=state:GetAttribute("Coins")
		local level=state:GetAttribute("CapacityLevel")
		local barrow=state:GetAttribute("BarrowOwned")
		if carried==nil or coins==nil or level==nil or barrow==nil then return nil end
		return {carried=carried,coins=coins,level=level,barrow=barrow,shovel=state:GetAttribute("ShovelLevel")or 0}
	end
	local function update()
		if queued then return end
		queued=true
		task.delay(0.1,function()
			queued=false
			local current=read()
			if not current then return end
			if previous then
				if current.shovel>previous.shovel then
					showToast("Лопата II · широкий захват")
				elseif current.level>previous.level then
					showToast("Вместимость: "..(state:GetAttribute("CapacityCells")or 40).." ячеек")
				elseif current.barrow>previous.barrow then
					showToast("Тачка куплена · +80 ячеек")
				elseif current.carried<previous.carried and current.coins>previous.coins then
					local earned=current.coins-previous.coins
					showToast("+"..earned.." "..coinWord(earned).." · песок продан")
				end
			end
			previous=current
		end)
	end
	state.AttributeChanged:Connect(update)
	update()
end)

local lastDigToastAt,digToastCount,burstFind=0,0,false
local falling,activeFalls={},0
local function showCollapse(motions)
	if type(motions)~="table"then return end
	local camera=workspace.CurrentCamera
	if not camera then return end
	for index,motion in motions do
		if index>8 or activeFalls>=16 then break end
		local part=motion.part
		local hasPart=typeof(part)=="Instance"and part:IsA("BasePart")and part:IsDescendantOf(workspace)
		local terrainMotion=part==nil and typeof(motion.size)=="Vector3"and typeof(motion.color)=="Color3"
		if (hasPart or terrainMotion)and typeof(motion.from)=="Vector3"and typeof(motion.to)=="Vector3"
			and(motion.from-motion.to).Magnitude>0.01 and(motion.from-motion.to).Magnitude<7
			and(camera.CFrame.Position-motion.from).Magnitude<=80 then
			part=hasPart and part or motion
			local previous=falling[part]
			local from=previous and previous.ghost.Position or motion.from
			if previous then previous.finish()end
			local ghost=Instance.new("Part")ghost.Name="FallingSand"
			ghost.Anchored=true ghost.CanCollide=false ghost.CanTouch=false ghost.CanQuery=false
			ghost.Size=hasPart and part.Size or motion.size ghost.Color=hasPart and part.Color or motion.color ghost.Material=Enum.Material.Sand
			ghost.CFrame=CFrame.new(from) ghost.Parent=effects
			if terrainMotion then
				-- Terrain already contains the authoritative destination. An opaque
				-- four-stud cube would duplicate its volume and reveal the grid.
				ghost.Name="SandFallDust"ghost.Size=Vector3.new(0.1,0.1,0.1)ghost.Transparency=1
				local direction=(motion.to-from).Unit
				ghost.CFrame=CFrame.lookAt(from,motion.to,math.abs(direction.Y)>0.95 and Vector3.xAxis or Vector3.yAxis)
				local dust=Instance.new("ParticleEmitter")dust.Name="SandDust"
				dust.Texture="rbxasset://textures/particles/smoke_main.dds"
				dust.Enabled=false dust.Rate=0 dust.Lifetime=NumberRange.new(0.16,0.28)
				dust.EmissionDirection=Enum.NormalId.Front dust.SpreadAngle=Vector2.new(12,12)
				local speed=(motion.to-from).Magnitude/0.22
				dust.Speed=NumberRange.new(speed*0.55,speed*0.8) dust.Acceleration=Vector3.new(0,-16,0)
				dust.Rotation=NumberRange.new(0,360) dust.RotSpeed=NumberRange.new(-40,40)
				dust.Color=ColorSequence.new(motion.color:Lerp(Color3.new(1,1,1),0.08))
				dust.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(0.4,0.7),NumberSequenceKeypoint.new(1,0.12)})
				dust.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(0.5,0.55),NumberSequenceKeypoint.new(1,1)})
				dust.LightInfluence=1 dust.LightEmission=0 dust.Parent=ghost dust:Emit(4)
			end
			if hasPart then part.LocalTransparencyModifier=1 end
			activeFalls+=1
			local entry={ghost=ghost}
			local finished=false
			function entry.finish()
				if finished then return end finished=true activeFalls-=1
				if falling[part]==entry then falling[part]=nil;if hasPart and part.Parent then part.LocalTransparencyModifier=0 end end
				ghost:Destroy()
			end
			falling[part]=entry
			TweenService:Create(ghost,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=motion.to}):Play()
			task.delay(terrainMotion and 0.35 or 0.2,entry.finish)
		end
	end
end
digEvent.OnClientEvent:Connect(function(position, color, userId,found,motions,collapseOnly)
	if typeof(position) ~= "Vector3" or typeof(color) ~= "Color3" then return end
	local view=workspace.CurrentCamera
	local close=view and(view.CFrame.Position-position).Magnitude<=80
	if close then showCollapse(motions)end
	if collapseOnly then return end
	-- Звук удара лопаты для всех близких игроков: привязываем к невидимой точке в пространстве
	if digSoundTemplate and close and activeDigSounds<6 then
		activeDigSounds+=1
		local sound = digSoundTemplate:Clone()
		local anchorPart = Instance.new("Part")
		anchorPart.Name = "DigSoundAnchor"
		anchorPart.Anchored = true
		anchorPart.CanCollide, anchorPart.CanTouch, anchorPart.CanQuery = false, false, false
		anchorPart.Transparency = 1
		anchorPart.Size = Vector3.new(0.1, 0.1, 0.1)
		anchorPart.Position = position
		anchorPart.Parent = workspace
		sound.Parent = anchorPart
		sound:Play()
		local finished=false
		local function finishSound()
			if finished then return end finished=true activeDigSounds-=1 anchorPart:Destroy()
		end
		sound.Ended:Once(finishSound)
		task.delay(2,finishSound)
	end
	-- Вспышка только на подтверждённом сервером раскопе.
	if close then playSuccessFlash(position)end
	if userId == player.UserId then
		local now=os.clock()
		if now-lastDigToastAt>0.08 then digToastCount=0 burstFind=false end
		lastDigToastAt=now
		digToastCount+=1
		burstFind=burstFind or found
		showToast(burstFind and "Найден осколок!"or "Песок +"..digToastCount)
	end
	local camera = workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - position).Magnitude > 80 or activeBursts >= 8 then return end
	activeBursts += 1
	local burst = Instance.new("Folder")
	burst.Name = "DigBurst"
	burst.Parent = effects
	for _ = 1, 6 do
		local chip = Instance.new("Part")
		chip.Name = "SandChip"
		chip.Size = Vector3.new(0.18, 0.18, 0.18)
		chip.Color = color
		chip.Material = Enum.Material.Sand
		chip.Anchored = true
		chip.CanCollide, chip.CanTouch, chip.CanQuery = false, false, false
		chip.Position = position + Vector3.new(random:NextNumber(-0.5, 0.5), 0.4, random:NextNumber(-0.5, 0.5))
		chip.Parent = burst
		TweenService:Create(chip, TweenInfo.new(0.45), {
			Position = chip.Position + Vector3.new(random:NextNumber(-1.4, 1.4), random:NextNumber(0.2, 1.5), random:NextNumber(-1.4, 1.4)),
			Transparency = 1,
		}):Play()
	end
	Debris:AddItem(burst, 0.5)
	task.delay(0.5, function() activeBursts -= 1 end)
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.08 then return end
	elapsed = 0
	highlight.Enabled = false
	highlight.Adornee = nil
	terrainSelection.Adornee=nil
	aimDot.Visible=false
	local camera=workspace.CurrentCamera
	if not camera then return end
	local character=player.Character
	local tool=character and character:FindFirstChildOfClass("Tool")
	if not tool or tool:GetAttribute("SandPrototypeTool")~=true then return end
	if Context.CenterAim()then
		local inset=game:GetService("GuiService"):GetGuiInset()
		aimDot.Position=UDim2.fromOffset(camera.ViewportSize.X/2-inset.X,camera.ViewportSize.Y/2-inset.Y)
		aimDot.BackgroundColor3=Color3.fromRGB(132,141,149)aimDot.Visible=true
	end
	local status = mountain:GetAttribute("PersistenceStatus")
	if status ~= "Saved" and status ~= "Saving" and status ~= "Dirty" and status ~= "SessionOnly" then return end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local state = player:FindFirstChild("SandPrototypeState")
	if not root or not humanoid or humanoid.Health <= 0 or not state then return end
	if state:GetAttribute("PushingCart")==true or Context.FreeCapacity(state)<=(state:GetAttribute("PendingCells")or 0)then return end
	local ray=Context.AimRay(mouse)
	if not ray then return end
	local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={character}
	local target=Context.ResolveHit(player,workspace:Raycast(ray.Origin,ray.Direction*200,params),cells)
	if tool and tool:GetAttribute("SandPrototypeTool") == true and Context.CanTarget(player,target,cells)
		and (root.Position - target.Position).Magnitude <= 24 then
		aimDot.BackgroundColor3=highlight.OutlineColor
		if type(target)=="table"then terrainMarker.Position=target.Position terrainSelection.Adornee=terrainMarker
		else highlight.Adornee = target highlight.Enabled = true end
	end
end)
