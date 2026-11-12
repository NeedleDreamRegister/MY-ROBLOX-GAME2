-- Server-owned ground cart. Resource ownership stays in Economy, not in parts.
local RunService=game:GetService("RunService")
local Cart={}
function Cart.Create(config)
	local owner=config.owner
	local model,root,prompt,load
	local pushing,oldSpeed,driverHumanoid=false,nil,nil
	local connections={}
	local bodyRest,loadWeld
	local wheelAnchor,wheelRadius
	local loadBottom,loadSize,loadRotation
	local bodyBoxSize
	local wheelAngle=0
	local gripHeight=2
	local closed=false
	local gripControls={}
	local equipConnection
	local controller={}
	local parkModel
	local PUSH_PITCH=math.rad(-4)
	local MAX_TURN_SPEED=math.rad(120)
	local function characterRoot()
		local character=owner.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local part=character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health<=0 then return nil end
		return part,humanoid
	end
	local function release()
		if equipConnection then equipConnection:Disconnect()equipConnection=nil end
		for _,control in gripControls do control:Destroy()end
		table.clear(gripControls)
		if driverHumanoid and driverHumanoid.Parent and oldSpeed then driverHumanoid.WalkSpeed=oldSpeed end
		pushing,oldSpeed,driverHumanoid=false,nil,nil
		if model then model:SetAttribute("Pushing",false)end
		local state=owner:FindFirstChild("SandPrototypeState")if state then state:SetAttribute("PushingCart",false)end
		if prompt then prompt.ActionText="Взяться за ручки"end
		if parkModel then parkModel()end
	end
	local function parameters()
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		local excluded={model}
		for _,p in game:GetService("Players"):GetPlayers()do
			if p.Character then table.insert(excluded,p.Character)end
		end
		params.FilterDescendantsInstances=excluded
		params.RespectCanCollide=true
		return params
	end
	local function groundAt(position,params)
		local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-30,0),params)
		if not hit or hit.Normal.Y<0.82 then return nil end
		return hit.Position.Y
	end
	parkModel=function()
		if not root or not root.Parent then return end
		local look=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
		if look.Magnitude<0.1 then return end look=look.Unit
		local y=groundAt(root.Position+look*(-wheelAnchor.Position.Z),parameters())
		if y then
			local position=Vector3.new(root.Position.X,y+gripHeight,root.Position.Z)
			root.CFrame=CFrame.lookAt(position,position+look)
		end
	end
	local function createModel()
		model=require(game:GetService("ReplicatedStorage").SandPrototypeCartAppearance).Build()
		model:SetAttribute("OwnerUserId",owner.UserId)model:SetAttribute("GroundCart",true)
		model:SetAttribute("WheelAngle",0)
		root=model.PrimaryPart
		gripHeight=model:GetAttribute("GripHeight")
		load=model.SandLoad loadSize=model:GetAttribute("LoadSize")
		loadBottom=model:GetAttribute("LoadBottom")loadRotation=model:GetAttribute("LoadRotation")
		bodyBoxSize=model:GetAttribute("BodyBoxSize")
		wheelAnchor=model:GetAttribute("WheelAnchor")wheelRadius=model:GetAttribute("WheelRadius")
		bodyRest=root.CFrame:ToObjectSpace(model.TrayBottom.CFrame)
		for _,p in model:GetChildren()do if p:IsA("BasePart")and p~=root then
			p.Anchored=false p.Massless=true
			if p==load then
				loadWeld=Instance.new("Weld")loadWeld.Name="LoadJoint"
				loadWeld.Part0=root loadWeld.Part1=p loadWeld.C0=root.CFrame:ToObjectSpace(p.CFrame)loadWeld.Parent=p
			else
				local weld=Instance.new("WeldConstraint")weld.Part0=root weld.Part1=p weld.Parent=p
			end
		end end
		local box,size=config.bounds,config.size
		if not box then box,size=config.mountain:GetBoundingBox()end
		local park=Vector3.new(box.Position.X+size.X/2+4,box.Position.Y,box.Position.Z)
		local y=groundAt(park,parameters())or 0
		model:PivotTo(CFrame.new(park.X,y+gripHeight,park.Z))
		model.Parent=config.station.Parent
		prompt=Instance.new("ProximityPrompt")prompt.Name="PushPrompt"
		prompt.ActionText="Взяться за ручки"prompt.ObjectText="ТАЧКА · 80 ячеек"
		prompt.KeyboardKeyCode=Enum.KeyCode.Q prompt.HoldDuration=0.3 prompt.MaxActivationDistance=7
		prompt.RequiresLineOfSight=false prompt.Parent=root
		table.insert(connections,prompt.Triggered:Connect(function(player)
			if player~=owner or closed or not config.canMutate()then return end
			if pushing then release()return end
			local part,humanoid=characterRoot()
			if not part or(part.Position-root.Position).Magnitude>8 then return end
			driverHumanoid=humanoid oldSpeed=humanoid.WalkSpeed humanoid.WalkSpeed=math.min(oldSpeed,12)
			pushing=true model:SetAttribute("Pushing",true)prompt.ActionText="Оставить тачку"
			humanoid:UnequipTools()
			local character=owner.Character
			local supported=true
			for _,side in {"Left","Right"}do
				local upper=character:FindFirstChild(side.."UpperArm")
				local hand=character:FindFirstChild(side.."Hand")
				if upper and hand then
					local ik=Instance.new("IKControl")ik.Name="CartGrip"..side
					ik.Type=Enum.IKControlType.Position ik.ChainRoot=upper
					ik.EndEffector=hand:FindFirstChild(side.."GripAttachment")or hand
					ik.Target=model["Handle"..side].GripTarget
					ik.Weight=1 ik.SmoothTime=0.08 ik.Priority=5 ik.Parent=humanoid
					table.insert(gripControls,ik)
				else supported=false end
			end
			model:SetAttribute("GripPoseSupported",supported)
			equipConnection=character.ChildAdded:Connect(function(child)
				if child:IsA("Tool")then task.defer(function()
					if pushing and driverHumanoid==humanoid then humanoid:UnequipTools()end
				end)end
			end)
			local state=owner:FindFirstChild("SandPrototypeState")if state then state:SetAttribute("PushingCart",true)end
		end))
	end
	function controller.Update(state)
		if closed then return end
		if state.BarrowOwned~=1 then return end
		if not model then createModel()end
		local amount=state.CartCells or 0
		load.Transparency=amount==0 and 1 or 0
		local height=0.04+loadSize.Y*amount/80
		load.Size=Vector3.new(loadSize.X,height,loadSize.Z)
		loadWeld.C0=CFrame.new(loadBottom+Vector3.new(0,height/2,0))*loadRotation
		model:SetAttribute("CartCells",amount)
		prompt.ObjectText=string.format("ТАЧКА · %d / 80",amount)
	end
	function controller.CanLoad()
		local part=characterRoot()
		return root~=nil and part~=nil and(part.Position-root.Position).Magnitude<=20
	end
	function controller.CanSell(pad)
		return root~=nil and(root.Position-pad.Position).Magnitude<=12
	end
	function controller.Destroy()
		closed=true release()
		for _,c in connections do c:Disconnect()end
		if model then model:Destroy()end
	end
	local elapsed=0
	table.insert(connections,RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt if elapsed<0.05 then return end
		local step=math.min(elapsed,0.1)elapsed=0
		local state=owner:FindFirstChild("SandPrototypeState")
		if state then state:SetAttribute("CartNearby",controller.CanLoad())end
		if not pushing then return end
		local part,humanoid=characterRoot()
		if not part or humanoid~=driverHumanoid or not config.canMutate()or(part.Position-root.Position).Magnitude>9 then release()return end
		local look=Vector3.new(part.CFrame.LookVector.X,0,part.CFrame.LookVector.Z)
		if look.Magnitude<0.1 then return end
		look=look.Unit
		local target=part.Position+look*1.5
		-- Turning moves the wheel through an arc even when the grip barely moves.
		-- Limit the angular step, then sweep the actual wheel centres below.
		local current=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z).Unit
		local angle=math.atan2(current:Cross(look).Y,current:Dot(look))
		look=CFrame.Angles(0,math.clamp(angle,-MAX_TURN_SPEED*step,MAX_TURN_SPEED*step),0):VectorToWorldSpace(current)
		local params=parameters()
		local wheelOffset=(CFrame.Angles(PUSH_PITCH,0,0)*wheelAnchor).Position
		local y=groundAt(target+look*(-wheelOffset.Z),params)
		if not y then release()return end
		target=Vector3.new(target.X,y+wheelRadius-wheelOffset.Y,target.Z)
		local delta=target-root.Position
		if math.abs(delta.Y)>2 then release()return end
		local distance=delta.Magnitude
		if distance>18*step then delta=delta.Unit*18*step end
		if delta.Magnitude>0.01 then
			local bowlFrame=root.CFrame*bodyRest
			local hit=workspace:Blockcast(bowlFrame+Vector3.new(0,0.65,0),bodyBoxSize,delta,params)
			if hit then model:SetAttribute("Blocked",true)return end
		end
		model:SetAttribute("Blocked",false)
		local position=root.Position+delta
		local destination=CFrame.lookAt(position,position+look)*CFrame.Angles(PUSH_PITCH,0,0)
		local bowlLocal=bodyRest
		local overlap=OverlapParams.new()overlap.FilterType=Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances=params.FilterDescendantsInstances overlap.RespectCanCollide=true overlap.MaxParts=1
		local wheelFrom=(root.CFrame*wheelAnchor).Position
		local wheelTo=(destination*wheelAnchor).Position
		local wheelTravel=wheelTo-wheelFrom
		if (wheelTravel.Magnitude>0.001 and workspace:Spherecast(wheelFrom,wheelRadius*0.9,wheelTravel,params))
			or #workspace:GetPartBoundsInRadius(wheelTo,wheelRadius*0.9,overlap)>0 then
			model:SetAttribute("Blocked",true)return
		end
		if #workspace:GetPartBoundsInBox(destination*bowlLocal+Vector3.new(0,0.65,0),bodyBoxSize,overlap)>0 then
			model:SetAttribute("Blocked",true)return
		end
		root.CFrame=destination
		wheelAngle+=Vector3.new(delta.X,0,delta.Z):Dot(look)/wheelRadius
		model:SetAttribute("WheelAngle",wheelAngle)
	end))
	return controller
end
return Cart
