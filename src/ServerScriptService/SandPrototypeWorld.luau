-- Existing mining rules, scoped to one owner and one mountain.
local World = {}
function World.Start(config)
local connections = {}
local function connect(signal, callback)
 local connection = signal:Connect(callback)
 table.insert(connections, connection)
 return connection
end
-- Small, disposable sand experiment. The Edit-mode parts in Workspace.SandPrototype
-- are the initial state; this script owns all changes during Play.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Economy = require(script.Parent:WaitForChild("SandPrototypeEconomy")).Create(config.owner)
assert(type(Economy.Credit)=="function","Update the economy module before cooperative play")
local SaveSession = require(script.Parent:WaitForChild("SandPrototypeSaveSession"))
local Coop = require(script.Parent:WaitForChild("SandPrototypeCoopData"))
local Finds=require(script.Parent:WaitForChild("SandPrototypeFindData"))
local Collapse=require(script.Parent:WaitForChild("SandPrototypeCollapse"))
local Geometry=require(ReplicatedStorage:WaitForChild("SandPrototypeGeometry"))
local Field=require(ReplicatedStorage:WaitForChild("SandPrototypeVoxelField"))

local mountain = config.mountain
local originalBounds,originalSize
if not config.terrain then originalBounds,originalSize=mountain:GetBoundingBox()end
local cellFolder = mountain:WaitForChild("Cells")
local digEvent = ReplicatedStorage:WaitForChild("SandPrototypeDig")

local CELL_SIZE = config.terrain and 4 or 2
local MAX_DIG_DISTANCE = 24
local MAX_MOVES_PER_STEP = 8
local MIN_DIG_INTERVAL = 0.12

local cells = {}
local field=config.terrain and Field.Create()or nil
local terrainOrigin=mountain:GetAttribute("TerrainOrigin")
local terrainBounds
local replicationTemplate
local chunks
if field then
 chunks=Instance.new("Folder")chunks.Name="Chunks"chunks.Parent=cellFolder
end
local sandColor=mountain:GetAttribute("SandColor")or Color3.fromRGB(219,188,120)
local function record(x,y,z)
 local position=terrainOrigin+Vector3.new(x,y,z)*4
 return {x=x,y=y,z=z,Position=position,Size=Vector3.new(4,4,4),CFrame=CFrame.new(position),Color=sandColor}
end
local lastDigAt = {}
local initialCells = 0
local mountainHeight = 0
local dugCells = 0
local movedCells = 0
local persistent = config.persistent
local ready, closing, saving = false, false, false
local session
local changeSequence, savedSequence = 0, 0
local outbound,imports={},{}
local committed
local accessMode="Closed"
local artifact=false
local collection={}
local requestSave
local renderer
-- One job per vacancy; do not silently discard the 4097th unfinished hole.
local retryQueue=Collapse.Queue(config.initial.initialCells)
local terrainFault=false
local lastSaveAt=os.clock()

local function status(value)
	mountain:SetAttribute("PersistenceStatus", value)
end
status("Loading")

local function changed()
	changeSequence += 1
	status(persistent and "Dirty" or "SessionOnly")
end

local function canMutate()
	if not ready or closing then return false end
	if session and os.time() >= session.expiresAt then
		status("LockLost")
		return false
	end
	return true
end

local function key(x, y, z)
	return string.format("%d,%d,%d", x, y, z)
end

local function getCell(x, y, z)
	if field then return field.Has(x,y,z)and record(x,y,z)or nil end
	return cells[key(x, y, z)]
end

local function coordinates(part)
	if type(part)=="table"then return part.x,part.y,part.z end
	local x, y, z = part:GetAttribute("GridX"), part:GetAttribute("GridY"), part:GetAttribute("GridZ")
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return nil
	end
	if x % 1 ~= 0 or y % 1 ~= 0 or z % 1 ~= 0 then
		return nil
	end
	return x, y, z
end

for _, part in cellFolder:GetChildren() do
	if part:IsA("BasePart") then
		local x, y, z = coordinates(part)
		assert(x and not getCell(x, y, z), "Invalid or duplicate sand cell: " .. part.Name)
		if field then
			field.Set(x,y,z,true) sandColor=part.Color part:Destroy()
		else cells[key(x, y, z)] = part end
		initialCells += 1
		mountainHeight=math.max(mountainHeight,y)
	end
end

local function countCells()
	if field then return field.Count()end
	local count = 0
	for _ in cells do
		count += 1
	end
	return count
end

local initialPublish=true
local function publishCounts()
	local remaining = countCells()
	if field then field.Publish(chunks,initialPublish and 256 or nil,replicationTemplate)end
	initialPublish=false
	assert(initialCells == remaining + dugCells, "Sand mass invariant failed")
	mountain:SetAttribute("InitialCells", initialCells)
	mountain:SetAttribute("RemainingCells", remaining)
	mountain:SetAttribute("DugCells", dugCells)
	mountain:SetAttribute("MovedCells", movedCells)
	mountain:SetAttribute("PendingCollapses",retryQueue.Count())
end

local function capture()
	local data = { schemaVersion = 3,ownerId=tostring(config.owner.UserId), revision = session and session.revision or 0,
		initialCells = initialCells, dugCells = dugCells, movedCells = movedCells,
		cells = {}, account = Economy.ExportAccounts()[tostring(config.owner.UserId)],
		outbound=table.clone(outbound),imports=table.clone(imports),accessMode=accessMode,
		artifact=artifact and table.clone(artifact)or false,collection=table.clone(collection),pendingCollapses=retryQueue.Export() }
	if field and initialCells>455 then
		data.cells=nil data.voxelChunks=field.Export()
	elseif field then
		field.Each(function(x,y,z)table.insert(data.cells,{x=x,y=y,z=z})end)
	else
		for _, part in cells do
			local x, y, z = coordinates(part)
			table.insert(data.cells, { x = x, y = y, z = z })
		end
	end
	return data
end

local loaded,initialError = config.validate(config.initial)
if not loaded then status("LoadFailed")warn(initialError)return end
if persistent then
	if game.GameId == 0 then status("LoadFailed") warn("Publish the test project before persistent play") return end
	local normalized, reason = config.validate(loaded)
	if not normalized then status("LoadFailed") warn(reason) return end
	local store = game:GetService("DataStoreService"):GetDataStore("DigMountainPlots_v1")
	local owner = game:GetService("HttpService"):GenerateGUID(false)
	for attempt = 1, 3 do
		session, reason = SaveSession.Open(store, config.key, normalized, { owner = owner, validate = config.validate, transition = Finds.Advances, migrate = config.migrate, compact=config.terrain==true })
		if session or reason == "locked" then break end
		if not string.find(reason, "datastore error:", 1, true) then break end
		if attempt < 3 then task.wait(attempt) end
	end
	if not session then
		status(reason == "locked" and "Locked" or "LoadFailed")
		warn("Sand world load failed: " .. tostring(reason))
		return
	end
	loaded = session.snapshot
	if not field then
		local keep = {}
		for _, cell in loaded.cells do keep[key(cell.x, cell.y, cell.z)] = true end
		for cellKey, part in cells do
			if not keep[cellKey] then part:Destroy() cells[cellKey] = nil end
		end
	end
end
-- Large worlds import bitsets directly; no temporary per-cell records or Parts.
if field then
	initialCells=loaded.initialCells mountainHeight=assert(Geometry.Height(initialCells))
	field=Field.Create(loaded.voxelChunks)
	for _,v in loaded.cells or {}do field.Set(v.x,v.y,v.z,true)end
	if initialCells>455 and require(script.Parent.SandPrototypeSaveCodec).Pack(loaded).geometryEncoding=="pyramid-v1-delta"then
		replicationTemplate=Geometry.Prepare(initialCells)
		chunks:SetAttribute("GeometryEncoding","pyramid-v1-delta")chunks:SetAttribute("TemplateCells",initialCells)
	end
	local edge=math.ceil((mountainHeight+1)/4)*4
	terrainBounds={min=Vector3.new(-edge,0,-edge),max=Vector3.new(edge,edge,edge)}
	mountain:SetAttribute("TerrainBoundsMin",terrainBounds.min)mountain:SetAttribute("TerrainBoundsMax",terrainBounds.max)
	originalBounds=CFrame.new(terrainOrigin+Vector3.new(0,mountainHeight*2,0))
	originalSize=Vector3.new((mountainHeight*2+1)*4,(mountainHeight+1)*4,(mountainHeight*2+1)*4)
end
dugCells, movedCells = loaded.dugCells, loaded.movedCells
outbound,imports=table.clone(loaded.outbound),table.clone(loaded.imports)
artifact=loaded.artifact and table.clone(loaded.artifact)or false
collection=table.clone(loaded.collection)
accessMode=loaded.accessMode
for _,entry in loaded.pendingCollapses or {}do retryQueue.Push(table.clone(entry))end
mountain:SetAttribute("AccessMode",accessMode)

if config.terrain then
	local ok,result=pcall(function()
		return require(script.Parent.SandPrototypeTerrain).Create(mountain:GetAttribute("TerrainOrigin"),getCell,terrainBounds)
	end)
	if not ok then
		if session then session:Save(loaded,true)end
		status("LoadFailed")warn("Terrain setup failed: "..tostring(result))return nil
	end
	renderer=result
end

local cart=require(script.Parent.SandPrototypeWheelbarrow).Create({owner=config.owner,mountain=mountain,
	station=config.station,canMutate=canMutate,bounds=originalBounds,size=originalSize})
Economy.Init({[tostring(config.owner.UserId)]=loaded.account}, changed, canMutate, persistent,cart)
committed=loaded
mountain:SetAttribute("SavedRevision", session and session.revision or 0)

local function saveWorld(release)
	if session and session.closed then return true end
	if saving then return false end
	if renderer and terrainFault then
		local repaired=pcall(renderer.Flush)
		if repaired then terrainFault=false end
	end
	saving = true
	lastSaveAt=os.clock()
	local sequence = changeSequence
	local data = capture()
	status("Saving")
	local ok, reason
	if not persistent then
		ok=true
	else for attempt = 1, 3 do
		ok, reason = session:Save(data, release)
		if ok or not string.find(tostring(reason), "datastore error:", 1, true) then break end
		if attempt < 3 then task.wait(attempt) end
	end end
	if ok then
		if not closing then ready = not terrainFault end
		savedSequence = sequence
		mountain:SetAttribute("SavedRevision", session and session.revision or 0)
		mountain:SetAttribute("LastSaveTime", os.time())
		status(terrainFault and "SaveFailed"or(persistent and (changeSequence > savedSequence and "Dirty" or "Saved") or "SessionOnly"))
		committed=session and session.snapshot or data
		if config.onSaved then task.defer(config.onSaved) end
	else
		local lost = reason == "lease lost" or reason == "revision conflict"
		ready = false
		status(lost and "LockLost" or "SaveFailed")
		warn("Sand world save failed: " .. tostring(reason))
	end
	saving = false
	if ok and changeSequence>savedSequence and not closing then requestSave() end
	return ok
end

local queued=false
requestSave=function()
	if queued or closing then return end
	queued=true
	task.delay(persistent and math.max(0.1,5-(os.clock()-lastSaveAt))or 0,function()
		queued=false
		if not closing then
			if saving then requestSave() else saveWorld(false) end
		end
	end)
end

if persistent then
	task.spawn(function()
		while not closing do
			task.wait(30)
			if not closing then requestSave()end
		end
	end)

end

local function isExposed(x, y, z)
	return not getCell(x + 1, y, z)
		or not getCell(x - 1, y, z)
		or not getCell(x, y + 1, z)
		or not getCell(x, y, z + 1)
		or not getCell(x, y, z - 1)
end

local function canSeeCell(character, root, target)
	local head = character:FindFirstChild("Head")
	local origin = head and head.Position or root.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local function hitsTarget(point)
		local hit = workspace:Raycast(origin, point - origin, params)
		if renderer then
			-- Cast slightly beyond the centre so the smooth surface is included.
			if not hit then hit=workspace:Raycast(origin,(point-origin).Unit*((point-origin).Magnitude+CELL_SIZE),params)end
			return hit~=nil and hit.Instance==workspace.Terrain and hit.Material==Enum.Material.Sand
				and((hit.Position-target.Position).Magnitude<=CELL_SIZE*1.25)
		end
		return hit ~= nil and hit.Instance == target
	end
	if hitsTarget(target.Position) then
		return true
	end
	-- An occluded centre must not prevent digging a visible edge. Points are
	-- inset from the corners to avoid grazing neighbouring cells numerically.
	local half = target.Size * 0.45
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				local point = target.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
				if hitsTarget(point) then
					return true
				end
			end
		end
	end
	return false
end

-- A vacancy can be filled by sand one level above, either straight down
-- or diagonally from its immediate neighbours. Each step transfers existing mass.
local function settleAround(x, y, z,budget)
	budget=budget or math.max(0,mountainHeight-y)
	local motions={}
	local characters = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			table.insert(characters, character)
		end
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = characters
	overlap.MaxParts = 1
	local function destination(source,sx,sy,sz,dx,dy,dz)
		return source.Position+Vector3.new((dx-sx)*CELL_SIZE,(dy-sy)*CELL_SIZE,(dz-sz)*CELL_SIZE)
	end
	local moves,retry=Collapse.Process(retryQueue,{x=x,y=y,z=z,budget=budget},getCell,function(source,sx,sy,sz,dx,dy,dz)
		local position=destination(source,sx,sy,sz,dx,dy,dz)
		table.insert(motions,{part=not field and source or nil,from=source.Position,to=position,size=source.Size,color=source.Color})
		if field then field.Set(sx,sy,sz,false)field.Set(dx,dy,dz,true)
		else cells[key(sx,sy,sz)]=nil cells[key(dx,dy,dz)]=source end
		if renderer then renderer.Mark(sx,sy,sz)renderer.Mark(dx,dy,dz)end
		artifact=Finds.Move(artifact,sx,sy,sz,dx,dy,dz)
		if not field then
			source:SetAttribute("GridX",dx)source:SetAttribute("GridY",dy)source:SetAttribute("GridZ",dz)
			source.Name=string.format("Cell_%d_%d_%d",dx,dy,dz)
			source.Position=position
		end
	end,function(source,dx,dy,dz)
		local sx,sy,sz=coordinates(source)
		local box=CFrame.new(destination(source,sx,sy,sz,dx,dy,dz))*source.CFrame.Rotation
		return #workspace:GetPartBoundsInBox(box,source.Size*0.95,overlap)==0
	end,MAX_MOVES_PER_STEP,mountainHeight,function(cx,cy,cz)
		return cy>=0 and cy<=mountainHeight and math.abs(cx)<=mountainHeight-cy and math.abs(cz)<=mountainHeight-cy
	end,dugCells)
	movedCells += moves
	return motions,retry
end

local function flushTerrain()
	if not renderer then return end
	local ok,reason=pcall(renderer.Flush)
	if not ok then terrainFault=true ready=false status("SaveFailed")warn("Terrain update failed: "..tostring(reason))end
end

task.spawn(function()
	while not closing do
		task.wait(0.05)
		if canMutate()and not terrainFault then
			local started=os.clock()
			local motions={}
			local moved=0
			local before=retryQueue.Count()
			retryQueue.Step(function(entry)
				if not canMutate()then return entry end
				if getCell(entry.x,entry.y,entry.z)then return nil end
				local transfers,retry=settleAround(entry.x,entry.y,entry.z,entry.budget)
				moved+=#transfers
				for _,motion in transfers do if #motions<8 then table.insert(motions,motion)end end
				return retry
			end,8,function()return os.clock()-started<0.002 end)
			-- Publish/flush once per batch, with bounded cosmetic motion traffic.
			if moved>0 then
				changed()flushTerrain()publishCounts()
				digEvent:FireAllClients(motions[1].from,sandColor,0,false,motions,true)
				requestSave()
			elseif retryQueue.Count()~=before then changed()requestSave()end
			mountain:SetAttribute("PendingCollapses",retryQueue.Count())
		end
	end
end)

local function digOne(player, target, followup)
	if not player:IsA("Player")or not target then return false end
	if not field and(typeof(target)~="Instance"or not target:IsA("BasePart")or target.Parent~=cellFolder)then return false end
	local x, y, z = coordinates(target)
	if not x or not getCell(x,y,z)or(not field and getCell(x,y,z)~=target)or not isExposed(x,y,z)then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local equippedTool
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("SandPrototypeTool") == true then
			equippedTool = child
			break
		end
	end
	if not equippedTool then
		return false
	end
	local playerState=player:FindFirstChild("SandPrototypeState")
	if playerState and playerState:GetAttribute("PushingCart")==true then return false end
	if (root.Position - target.Position).Magnitude > MAX_DIG_DISTANCE then
		return false
	end
	local now = os.clock()
	if not followup and now - (lastDigAt[player] or -math.huge) < MIN_DIG_INTERVAL then
		return false
	end
	if not followup then lastDigAt[player] = now end

	if not canSeeCell(character, root, target) then
		return false
	end
	if not canMutate() then return false end
	local own=player==config.owner
	if own and not Economy.CanCarry(player) then
		return false
	end
	if own and config.ownCanCarry and not config.ownCanCarry()then return false end
	if not own and outbound[tostring(player.UserId)]==nil then
		local count=0 for _ in outbound do count+=1 end if count>=128 then return false end
	end
	if not own and (not config.canHelp or not config.canHelp(player)) then return false end

	debug.profilebegin("DigMountain.Mutate")
	local effectPosition, effectColor = target.Position, target.Color
	local found=Finds.Matches(artifact,x,y,z)
	if field then field.Set(x,y,z,false)
	else cells[key(x,y,z)]=nil target:Destroy()end
	if renderer then renderer.Mark(x,y,z)end
	dugCells += 1
	if own then Economy.RecordDig(player)
	else
		local id=tostring(player.UserId)
		outbound[id]=(outbound[id]or 0)+1
		changed()
	end
	if found then
		artifact={kind=Finds.Kind,finderId=tostring(player.UserId),counter=own and 0 or outbound[tostring(player.UserId)]}
		if own then collection[tostring(config.owner.UserId)]={kind=Finds.Kind,counter=0}end
	end
	local motions,retry=settleAround(x, y, z)
	retryQueue.Push(retry)
	flushTerrain()
	publishCounts()
	digEvent:FireAllClients(effectPosition, effectColor, player.UserId,found,motions)
	if not own or found then requestSave() end
	if config.onChanged then config.onChanged() end
	debug.profileend()
	return true
end

local function tryDig(player,target)
	if field then
		-- Resolve only bounded coordinates in this world. All other request fields are ignored.
		if type(target)~="table"or target.ownerId~=config.owner.UserId then return end
		for _,v in {target.x,target.y,target.z}do
			if type(v)~="number"or v%1~=0 or math.abs(v)>mountainHeight then return end
		end
		if type(target.x)~="number"or type(target.y)~="number"or type(target.z)~="number"then return end
		if not Geometry.Contains(initialCells,target.x,target.y,target.z)then return end
		target=getCell(target.x,target.y,target.z)
		if not target then return end
	elseif typeof(target)~="Instance"or not target:IsA("BasePart")then return end
	local x,y,z=coordinates(target)
	if not x or not digOne(player,target,false)then return end
	local state=player:FindFirstChild("SandPrototypeState")
	if not state or (state:GetAttribute("ShovelLevel")or 0)<1 then return end
	-- Only the server chooses the second cell. Each cell retains all original
	-- distance, visibility, ownership, inventory and mass checks.
	for _,offset in {{1,0,0},{-1,0,0},{0,0,1},{0,0,-1},{0,1,0},{0,-1,0}}do
		local candidate=getCell(x+offset[1],y+offset[2],z+offset[3])
		if candidate and digOne(player,candidate,true)then break end
	end
end

connect(digEvent.OnServerEvent, tryDig)
connect(Players.PlayerRemoving, function(player)
	lastDigAt[player] = nil
end)
publishCounts()

local station = config.station
local sellPad = station:WaitForChild("SellPad")
local upgradePad = station:WaitForChild("UpgradePad")
connect(sellPad:WaitForChild("SellPrompt").Triggered, function(player)
	if player == config.owner and Economy.Sell(player, sellPad) and config.onSaved then task.defer(config.onSaved) end
end)
connect(upgradePad:WaitForChild("UpgradePrompt").Triggered, function(player)
	if player == config.owner then Economy.BuyCapacity(player, upgradePad) end
end)

local shovelPad=Instance.new("Part")
shovelPad.Name="ShovelUpgradePad"
shovelPad.Size=Vector3.new(6,0.5,6)
shovelPad.Position=upgradePad.Position+Vector3.new(8,0,0)
shovelPad.Anchored=true
shovelPad.Material=Enum.Material.Metal
shovelPad.Color=Color3.fromRGB(174,125,58)
shovelPad.Parent=station
local sign=Instance.new("BillboardGui")
sign.Name="ShovelSign"
sign.Size=UDim2.fromOffset(180,48)
sign.StudsOffset=Vector3.new(0,3.5,0)
sign.AlwaysOnTop=true
sign.Parent=shovelPad
local label=Instance.new("TextLabel")
label.Size=UDim2.fromScale(1,1)
label.BackgroundColor3=Color3.fromRGB(24,31,39)
label.BackgroundTransparency=0.15
label.TextColor3=Color3.fromRGB(255,233,163)
label.Font=Enum.Font.GothamBold
label.TextScaled=true
label.Text="ЛОПАТА II\nДо 2 ячеек · 20 монет"
label.Parent=sign
local shovelPrompt=Instance.new("ProximityPrompt")
shovelPrompt.Name="ShovelPrompt"
shovelPrompt.KeyboardKeyCode=Enum.KeyCode.H
shovelPrompt.ObjectText="ЛОПАТА II · 20 монет"
shovelPrompt.ActionText="Расширить захват"
shovelPrompt.HoldDuration=0.3
shovelPrompt.MaxActivationDistance=10
shovelPrompt.Parent=shovelPad
local function refreshShovelShop()
	local bought=(Economy.GetSnapshot(config.owner).ShovelLevel or 0)>=1
	label.Text=bought and "ЛОПАТА II\nШирокий захват установлен"or "ЛОПАТА II\nДо 2 ячеек · 20 монет"
	shovelPrompt.Enabled=not bought
end
refreshShovelShop()
connect(shovelPrompt.Triggered,function(player)
	if player==config.owner and Economy.BuyShovel(player,shovelPad)then refreshShovelShop()end
end)

local barrowPad = station:FindFirstChild("WheelbarrowPad")
if barrowPad then
	connect(barrowPad:WaitForChild("WheelbarrowPrompt").Triggered, function(player)
		if player ~= config.owner then return end
		Economy.BuyWheelbarrow(player, barrowPad)
	end)
end

local closed = false
ready=true
status(persistent and (changeSequence>savedSequence and "Dirty"or"Saved")or"SessionOnly")
return {
 IsReady=canMutate,
 GetAccess=function()return accessMode end,
 SetAccess=function(mode)
  if not canMutate()or(mode~="Closed"and mode~="Friends"and mode~="Open")then return false end
  accessMode=mode mountain:SetAttribute("AccessMode",mode)changed()requestSave()return true
 end,
 GetAccount=function()return Economy.GetSnapshot(config.owner)end,
 GetFreeCapacity=function()return Economy.FreeCapacity(config.owner)end,
 GetImports=function()return table.clone(imports)end,
 GetOutbound=function(userId)return outbound[tostring(userId)]or 0 end,
 GetCommitted=function()return committed end,
 EnsureSource=function(sourceId)
  if not canMutate() then return false end
  local id=tostring(sourceId)
  if id==tostring(config.owner.UserId)then return false end
  if imports[id]==nil then
   local count=0 for _ in imports do count+=1 end if count>=128 then return false,"Лимит истории совместных раскопок" end
   imports[id]=0 changed()requestSave()
  end
  return committed.imports[id]~=nil,"Подключаем сохранение помощника…"
 end,
 GetCollection=function()return table.clone(collection)end,
 ApplyCredit=function(sourceId,confirmed,proof)
  if not canMutate()then return 0 end
  local id=tostring(sourceId)
  if imports[id]==nil or committed.imports[id]==nil then return 0 end
  local account=Economy.GetSnapshot(config.owner)if not account then return 0 end
  local delta=math.min(Coop.CreditDelta(account,imports[id],confirmed),Economy.FreeCapacity(config.owner))
  local credited=0
  if delta>0 and Economy.Credit(config.owner,delta)then imports[id]+=delta requestSave()credited=delta end
  if collection[id]==nil and Finds.CanClaim(proof,config.owner.UserId,imports[id])then
   collection[id]={kind=Finds.Kind,counter=proof.counter}changed()requestSave()
  end
  return credited
 end,
 RequestSave=function()requestSave()end,
 Close = function()
  if closed then return end
  closed = true
  closing, ready = true, false
  local deadline = os.clock() + 25
  while saving and os.clock() < deadline do task.wait(0.1) end
  local ok = not saving and saveWorld(true)
  for _, connection in connections do connection:Disconnect() end
  Economy.Destroy()
  if renderer then renderer.Destroy()end
  if not ok then warn("Personal plot final save incomplete") end
  return ok
 end,
}
end
return World
