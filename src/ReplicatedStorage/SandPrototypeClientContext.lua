local Context={}
local Grid=require(script.Parent:WaitForChild("SandPrototypeTerrainGrid"))
local Field=require(script.Parent:WaitForChild("SandPrototypeVoxelField"))
local Geometry=require(script.Parent:WaitForChild("SandPrototypeGeometry"))
local UpgradeConfig=require(script.Parent:WaitForChild("UpgradeConfig"))
function Context.DigReach(state)return UpgradeConfig.Reach(state and state:GetAttribute('SelectedTool'))end
function Context.CenterAim()
	local input=game:GetService("UserInputService").PreferredInput
	local p=game.Players.LocalPlayer;local head=p and p.Character and p.Character:FindFirstChild('Head')
	local camera=workspace.CurrentCamera
	return input==Enum.PreferredInput.Touch or input==Enum.PreferredInput.Gamepad
		or(camera~=nil and head~=nil and(camera.CFrame.Position-head.Position).Magnitude<1.05)
end
function Context.AimRay(mouse,position)
	local camera=workspace.CurrentCamera
	if not camera then return nil end
	if position then return camera:ViewportPointToRay(position.X,position.Y)end
	if Context.CenterAim()then
		local size=camera.ViewportSize
		return camera:ViewportPointToRay(size.X/2,size.Y/2)
	end
	return mouse.UnitRay
end
function Context.TouchBlocked(playerGui,position)
	-- TouchTapInWorld can report processed=false over non-interactive HUD frames.
	-- Its viewport point includes the core inset; PlayerGui hit tests use GUI space.
	local point=position-game:GetService("GuiService"):GetGuiInset()
	for _,object in playerGui:GetGuiObjectsAtPosition(point.X,point.Y)do
		local screen=object:FindFirstAncestorWhichIsA("ScreenGui")
		if screen and(screen.Name=="SandPrototypeHUD"or screen.Name=="SandPrototypeVisits"or screen.Name=="DTM_MobileDig")then
			return true
		end
	end
	return false
end
-- Client guidance only; Economy repeats authoritative capacity checks on the server.
function Context.FreeCapacity(state)
	if not state then return 0 end
	if state:GetAttribute('ProgressionVersion')==1 then
		if state:GetAttribute('CartEnabled')then
			if state:GetAttribute('CartNearby')==false then return 0 end
			return math.max(0,(state:GetAttribute('CartCapacity')or 0)-(state:GetAttribute('CartCells')or 0))
		end
		return math.max(0,(state:GetAttribute('ManualCapacity')or 20)-(state:GetAttribute('CarriedCells')or 0))
	end
	local carried=state:GetAttribute("CarriedCells")or 0
	local capacity=state:GetAttribute("CapacityCells")or 20
	local nearby=state:GetAttribute("CartNearby")
	if nearby==nil then return math.max(0,capacity-carried)end -- legacy tool transport
	local cart=state:GetAttribute("CartCells")or 0
	local manualCapacity=state:GetAttribute("CapacityLevel")==1 and 40 or 20
	local free=math.max(0,manualCapacity-(carried-cart))
	if state:GetAttribute("BarrowOwned")==1 and nearby then free+=math.max(0,80-cart)end
	return free
end
function Context.CanTarget(player,target,ownCells)
	if not target then return false end
	local cells,mountain
	if type(target)=="table"then
		mountain=target.mountain
		if typeof(mountain)~="Instance"then return false end
		cells=mountain:FindFirstChild("Cells")
	else
		if typeof(target)~="Instance"or not target:IsA("BasePart")then return false end
		cells=target.Parent mountain=cells and cells.Parent
	end
	if cells==ownCells then return true end
	local plots=workspace:FindFirstChild("SandPlots")
	if not plots or not mountain or not cells or cells.Name~="Cells"or not mountain:IsDescendantOf(plots)then return false end
	local owner=mountain:GetAttribute("OwnerUserId")
	local permissions=player:FindFirstChild("SandPrototypePermissions")
	local flag=permissions and permissions:FindFirstChild(tostring(owner))
	return flag~=nil and flag.Value==true
end
function Context.Request(target)
	if type(target)=="table"then return {ownerId=target.mountain:GetAttribute("OwnerUserId"),x=target.x,y=target.y,z=target.z}end
	return target
end
function Context.ResolveHit(player,hit,ownCells)
	if not hit then return nil end
	if hit.Instance~=workspace.Terrain then
		return Context.CanTarget(player,hit.Instance,ownCells)and hit.Instance or nil
	end
	if hit.Material~=Enum.Material.Sand then return nil end
	local plots=workspace:FindFirstChild("SandPlots")
	if not plots then return nil end
	for _,plot in plots:GetChildren()do
		local mountain=plot:FindFirstChild("SandPrototype")
		local origin=mountain and mountain:GetAttribute("TerrainOrigin")
		if origin then
			local minimum,maximum=mountain:GetAttribute("TerrainBoundsMin"),mountain:GetAttribute("TerrainBoundsMax")
			local bounds=typeof(minimum)=="Vector3"and typeof(maximum)=="Vector3"and {min=minimum,max=maximum}or nil
			local folder=mountain:FindFirstChild("Cells")
			local chunks=folder and folder:FindFirstChild("Chunks")
			local target=folder and Grid.Resolve(origin,hit.Position,hit.Normal,function(x,y,z)
				if not chunks then return folder:FindFirstChild(string.format("Cell_%d_%d_%d",x,y,z))end
				local key=Field.Address(x,y,z)
				local chunk=chunks:FindFirstChild(key)
				local present=chunk and Field.Contains(chunk.Value,x,y,z)
				if not chunk and chunks:GetAttribute("GeometryEncoding")=="pyramid-v1-delta"then
					present=Geometry.Contains(chunks:GetAttribute("TemplateCells"),x,y,z)
				end
				if present then
					return {mountain=mountain,x=x,y=y,z=z,Position=Grid.Position(origin,x,y,z)}
				end
				return nil
			end,bounds)
			if target and Context.CanTarget(player,target,ownCells)then return target end
		end
	end
	return nil
end
function Context.ResolveAim(player,hit,ownCells)
	local state=player:FindFirstChild('SandPrototypeState')
	local ch=player.Character;local head=ch and ch:FindFirstChild('Head')
	if Context.DigReach(state)<24 and head and hit and hit.Instance==workspace.Terrain then
		-- The third-person camera can see past the roof/edge of a pit while the
		-- shovel cannot. Select the first surface the character can actually hit.
		local delta=hit.Position-head.Position
		if delta.Magnitude>.01 then
			local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances={ch}
			local first=workspace:Raycast(head.Position,delta.Unit*(delta.Magnitude+.15),params)
			if first then hit=first end
		end
	end
	return Context.ResolveHit(player,hit,ownCells),hit
end
function Context.GetMountain(player)
	if workspace:GetAttribute("PersonalPlotsEnabled")==true then
		local reference=player:WaitForChild("SandPrototypeMountain")
		while not reference.Value do task.wait(0.1)end
		return reference.Value
	end
	return workspace:WaitForChild("SandPrototype")
end
return Context

