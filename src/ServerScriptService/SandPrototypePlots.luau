-- Four test plots. Runtime clones only; Edit templates and legacy save stay intact.
local Players=game:GetService("Players")
local World=require(script.Parent.SandPrototypeWorld)
local PlotData=require(script.Parent.SandPrototypePlotData)
local Coop=require(script.Parent.SandPrototypeCoopData)
local Finds=require(script.Parent.SandPrototypeFindData)
local SaveSession=require(script.Parent.SandPrototypeSaveSession)
local Rules=require(script.Parent.SandPrototypeAccessRules)
local Layout=require(script.Parent.SandPrototypePlotLayout)
local Plots={}

function Plots.Start(main)
	local persistent=main:GetAttribute("PersistenceEnabled")~=false
	local useTerrain=main:GetAttribute("TerrainEnabled")~=false
	local height=useTerrain and(main:GetAttribute("TerrainHeight")or Layout.DefaultHeight)or 6
	local layout=useTerrain and Layout.Get(height)
	local targetCells=layout and layout.cells or 455
	local templates={}
	for _,name in {"SandPrototype","SandPrototypeStation","SandPrototypePath","SandPrototypePlot","SpawnLocation"} do
		local original=workspace:FindFirstChild(name)
		assert(original,"Missing plot template: "..name)
		templates[name]=original:Clone()
		original:Destroy()
	end
	local folder=Instance.new("Folder")
	folder.Name="SandPlots"
	folder.Parent=workspace
	workspace:SetAttribute("PersonalPlotsEnabled",true)
	local slots,entries={},{}
	local shuttingDown=false
	local confirmed,friendCache={},{}
	local confirmedFinds={}
	local refreshPermissions,relay
	local function friend(owner,actor)
		if owner.UserId<=0 or actor.UserId<=0 then return false end
		local key=owner.UserId..":"..actor.UserId
		local cached=friendCache[key]
		if not cached then
			cached={value=false}friendCache[key]=cached
			task.spawn(function()
				local ok,value=pcall(function()return actor:IsFriendsWithAsync(owner.UserId)end)
				cached.value=ok and value==true
				if refreshPermissions then refreshPermissions()end
			end)
		end
		return cached.value
	end
	local function allowed(owner,actor)
		local entry=entries[owner]
		if not entry or entry.loading or entry.closing or not entry.world or not entry.world.IsReady()then return false end
		local mode=entry.world.GetAccess()
		return Rules.Allows(owner.UserId,actor.UserId,mode,mode=="Friends"and friend(owner,actor))
	end
	refreshPermissions=function()
		for _,actor in Players:GetPlayers()do
			local permissions=actor:FindFirstChild("SandPrototypePermissions")
			if not permissions then permissions=Instance.new("Folder")permissions.Name="SandPrototypePermissions"permissions.Parent=actor end
			for owner,entry in entries do
				local name=tostring(owner.UserId)
				local flag=permissions:FindFirstChild(name)
				if not flag then flag=Instance.new("BoolValue")flag.Name=name flag.Parent=permissions end
				flag.Value=allowed(owner,actor)
			end
		end
	end
	local function pending(player)
		local entry=entries[player]
		if not entry or not entry.world then return 0 end
		local imported=entry.world.GetImports()
		local counts={}
		for sourceId,counters in confirmed do counts[sourceId]=counters[tostring(player.UserId)]or 0 end
		for owner,source in entries do
			if source.world then
				local id=tostring(owner.UserId)
				counts[id]=math.max(counts[id]or 0,source.world.GetOutbound(player.UserId))
			end
		end
		local total=0
		for sourceId,value in counts do
			if imported[sourceId]~=nil then total+=math.max(0,value-imported[sourceId])end
		end
		return total
	end
	local function publishPending()
		for player,entry in entries do
			local state=player:FindFirstChild("SandPrototypeState")
			if state and entry.world then
				local findCount=0 for _ in entry.world.GetCollection()do findCount+=1 end
				state:SetAttribute("FindCount",findCount)
				local museum=entry.plot:FindFirstChild("Museum")
				if museum and museum:GetAttribute("FindCount")~=findCount then
					museum:SetAttribute("FindCount",findCount)
					museum.Shard.Transparency=findCount>0 and 0 or 1
					museum.Sign.SurfaceGui.TextLabel.Text="МУЗЕЙ\nГлиняных осколков: "..findCount
				end
				state:SetAttribute("PendingCells",pending(player))
				local recoveryCount=0
				for sourceId in entry.recoveryPending or{}do
					if confirmed[sourceId]then entry.recoveryPending[sourceId]=nil else recoveryCount+=1 end
				end
				state:SetAttribute("RewardSyncPending",recoveryCount)
				local waiting=false
				for sourceId in entry.world.GetImports()do
					if entry.world.GetCommitted().imports[sourceId]==nil then waiting=true break end
				end
				if not waiting then state:SetAttribute("HelpStatus","")end
			end
		end
	end
	relay=function()
		for owner,entry in entries do
			if entry.world then
				confirmed[tostring(owner.UserId)]=table.clone(entry.world.GetCommitted().outbound)
				confirmedFinds[tostring(owner.UserId)]=entry.world.GetCommitted().artifact
			end
		end
		for player,entry in entries do
			if not entry.closing and entry.world and entry.world.IsReady()then
				for sourceId,counters in confirmed do
					local amount=counters[tostring(player.UserId)]
					if amount then entry.world.ApplyCredit(sourceId,amount,confirmedFinds[sourceId])end
				end
			end
		end
		publishPending()
		refreshPermissions()
	end
	local function recover(entry)
		if not persistent or not entry.world then return end
		local unresolved={}
		entry.recoveryPending={}
		for sourceId in entry.world.GetImports()do table.insert(unresolved,sourceId)entry.recoveryPending[sourceId]=true end
		publishPending()
		for attempt=1,3 do
			local failed={}
			for _,sourceId in unresolved do
				if entry.closing then return end
				local sourcePlayer=Players:GetPlayerByUserId(tonumber(sourceId))
				local active=sourcePlayer and entries[sourcePlayer]
				if not(active and active.world)then
					local ok,data=pcall(function()
						local options=Instance.new("DataStoreGetOptions")options.UseCache=false
						local record=game:GetService("DataStoreService"):GetDataStore("DigMountainPlots_v1"):GetAsync("player_"..sourceId,options)
						assert(record,"Reward source record missing")
						local size=type(record.snapshot)=="table"and record.snapshot.initialCells or 455
						local normalized,reason=SaveSession.Read(record,Finds.Validator(tonumber(sourceId),false,true,size))
						assert(normalized,reason)return normalized
					end)
					if ok then confirmed[sourceId]=data.outbound confirmedFinds[sourceId]=data.artifact
					else table.insert(failed,sourceId)warn("Helper reward recovery deferred: "..tostring(data))end
				end
				relay()task.wait(0.5)
			end
			unresolved=failed
			if #unresolved==0 then break end
			if attempt<3 then task.wait(10)end
		end
	end
	local access=Instance.new("RemoteEvent")access.Name="SandPrototypeAccess"access.Parent=game.ReplicatedStorage
	local lastAccessAt={}
	access.OnServerEvent:Connect(function(player,mode)
		local entry=entries[player]
		if not entry or not entry.world or entry.closing then return end
		if os.clock()-(lastAccessAt[player]or-math.huge)<0.5 then return end
		lastAccessAt[player]=os.clock()
		if not entry.world.SetAccess(mode)then access:FireClient(player,false,"Нельзя изменить режим доступа")return end
		entry.plot:SetAttribute("AccessMode",mode)
		refreshPermissions()
		access:FireClient(player,true,"Доступ к раскопкам обновлён")
	end)
	local lastVisitAt={}
	local visit=game.ReplicatedStorage:FindFirstChild("SandPrototypeVisit")
	if not visit then
		visit=Instance.new("RemoteEvent")
		visit.Name="SandPrototypeVisit"
		visit.Parent=game.ReplicatedStorage
	end
	assert(visit:IsA("RemoteEvent"),"Unexpected visit remote class")
	local function available(entry)
		if not entry or entry.loading or entry.closing then return false end
		local status=entry.plot.SandPrototype:GetAttribute("PersistenceStatus")
		return status=="Saved" or status=="Saving" or status=="Dirty" or status=="SessionOnly"
	end
	visit.OnServerEvent:Connect(function(player,userId)
		local function reply(ok,message)visit:FireClient(player,ok,message)end
		if shuttingDown or not available(entries[player]) then reply(false,"Твой участок пока недоступен")return end
		local now=os.clock()
		if now-(lastVisitAt[player] or -math.huge)<1 then reply(false,"Подожди секунду перед переходом")return end
		lastVisitAt[player]=now
		if type(userId)~="number" or userId~=userId or math.abs(userId)>9007199254740991 or userId%1~=0 then reply(false,"Некорректный участок")return end
		local owner=Players:GetPlayerByUserId(userId)
		local destination=owner and entries[owner]
		if not available(destination) then reply(false,"Хозяин вышел или участок недоступен")return end
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health<=0 then reply(false,"Дождись появления персонажа")return end
		local home=owner==player
		character:PivotTo(destination.plot.SpawnLocation.CFrame+Vector3.new(0,4,home and 0 or -5))
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
		reply(true,home and "Ты на своём участке" or(allowed(owner,player)and "В гостях · копать разрешено"or "Гостевой просмотр · копать нельзя"))
	end)
	local function close(entry)
		if entry.closing then return end
		entry.closing=true
		lastVisitAt[entry.player]=nil
		lastAccessAt[entry.player]=nil
		if entry.spawnConnection then entry.spawnConnection:Disconnect() end
		entry.player.RespawnLocation=nil
		-- A load is allowed to finish so any acquired lease can be released.
		while entry.loading do task.wait(0.1) end
		if entry.world then
			entry.world.Close()
			confirmed[tostring(entry.player.UserId)]=table.clone(entry.world.GetCommitted().outbound)
			confirmedFinds[tostring(entry.player.UserId)]=entry.world.GetCommitted().artifact
		end
		entry.plot:Destroy()
		slots[entry.slot]=nil
		entries[entry.player]=nil
		for key in friendCache do
			local a,b=string.match(key,"^([^:]+):([^:]+)$")
			if a==tostring(entry.player.UserId)or b==tostring(entry.player.UserId)then friendCache[key]=nil end
		end
		for _,p in Players:GetPlayers()do local flags=p:FindFirstChild("SandPrototypePermissions")local flag=flags and flags:FindFirstChild(tostring(entry.player.UserId))if flag then flag:Destroy()end end
		relay()
	end
	local function add(player)
		if shuttingDown or entries[player] then return end
		if persistent and player.UserId<=0 then
			player:Kick("Локальный тест: отключите PersistenceEnabled.") return
		end
		local slot
		for i=1,4 do if not slots[i] then slot=i break end end
		if not slot then player:Kick("Все четыре тестовых участка заняты.") return end
		slots[slot]=true
		local plot=Instance.new("Model")
		plot.Name="Plot_"..player.UserId
		plot:SetAttribute("OwnerUserId",player.UserId)
		plot:SetAttribute("AccessMode","Closed")
		for _,template in templates do template:Clone().Parent=plot end
		local spacing=layout and layout.spacing or 85
		local offset=Vector3.new(((slot-1)%2)*spacing,0,math.floor((slot-1)/2)*spacing)
		plot:PivotTo(plot:GetPivot()+offset)
		if useTerrain then
			local origin=layout.origin+offset
			local mountain=plot.SandPrototype
			mountain:SetAttribute("TerrainOrigin",origin)
			mountain:SetAttribute("TerrainEnabled",true)
			for _,cell in mountain.Cells:GetChildren()do
				if cell:IsA("BasePart")then
					if mountain:GetAttribute("SandColor")==nil then mountain:SetAttribute("SandColor",cell.Color)end
					cell:Destroy() -- the validated logical profile supplies Terrain; no proxy cells enter Workspace
				end
			end
			local border=plot.SandPrototypePlot
			border.Ground.Size=Vector3.new(layout.groundSize.X,border.Ground.Size.Y,layout.groundSize.Z)
			border.Ground.Position=Vector3.new(layout.groundCenter.X,border.Ground.Position.Y,layout.groundCenter.Z)+offset
			local function edge(name,x,z,width,depth)
				local part=border:FindFirstChild(name)
				if part then part.Position=Vector3.new(x,part.Position.Y,z)+offset part.Size=Vector3.new(width,part.Size.Y,depth)end
			end
			edge("NorthBorder",layout.groundCenter.X,layout.minimum.Z,layout.groundSize.X,0.4)
			edge("WestBorder",layout.minimum.X,layout.groundCenter.Z,0.4,layout.groundSize.Z)
			edge("EastBorder",layout.maximum.X,layout.groundCenter.Z,0.4,layout.groundSize.Z)
			edge("SouthBorderLeft",(layout.minimum.X-4)/2,14,-4-layout.minimum.X,0.4)
			edge("SouthBorderRight",(layout.maximum.X+4)/2,14,layout.maximum.X-4,0.4)
			for _,part in border:GetChildren()do
				if part:IsA("BasePart")and(part.Name=="EquipmentBay"or part.Name=="EquipmentSign"or part.Name=="BayEdge")then
					part.Position+=layout.equipmentShift
				end
			end
		end
		local sign=Instance.new("Part")
		sign.Name="OwnerSign"
		sign.Size=Vector3.new(9,2,0.2)
		sign.CFrame=plot.SpawnLocation.CFrame+Vector3.new(0,2,7)
		sign.Anchored=true
		sign.CanCollide,sign.CanTouch,sign.CanQuery=false,false,false
		sign.Color=Color3.fromRGB(36,45,42)
		sign.Parent=plot
		local surface=Instance.new("SurfaceGui")
		surface.Face=Enum.NormalId.Front
		surface.CanvasSize=Vector2.new(630,140)
		surface.Parent=sign
		local title=Instance.new("TextLabel")
		title.Size=UDim2.fromScale(1,1)
		title.BackgroundTransparency=1
		title.Text=player.DisplayName.."\nЛИЧНЫЙ УЧАСТОК"
		title.TextColor3=Color3.fromRGB(242,235,201)
		title.Font=Enum.Font.GothamBold
		title.TextSize=26
		title.TextScaled=true
		title.Parent=surface
		local museum=Instance.new("Model")museum.Name="Museum"museum.Parent=plot
		local base=plot.SpawnLocation.Position+Vector3.new(16,0,-46)+(layout and layout.equipmentShift or Vector3.zero)
		local function museumPart(class,name,size,position,color)
			local part=Instance.new(class)part.Name=name part.Size=size part.Position=position
			part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
			part.Color=color part.Parent=museum return part
		end
		museumPart("Part","Pedestal",Vector3.new(8,0.8,4),Vector3.new(base.X,0.4,base.Z),Color3.fromRGB(133,125,105))
		local shard=museumPart("WedgePart","Shard",Vector3.new(1.2,0.8,1.7),Vector3.new(base.X,1.4,base.Z),Color3.fromRGB(176,101,63))
		shard.Material=Enum.Material.Slate shard.Transparency=1
		local sign=museumPart("Part","Sign",Vector3.new(9,2,0.2),Vector3.new(base.X,3,base.Z-2.5),Color3.fromRGB(36,45,42))
		local face=Instance.new("SurfaceGui")face.Face=Enum.NormalId.Back face.CanvasSize=Vector2.new(630,140)face.LightInfluence=0 face.Parent=sign
		local text=Instance.new("TextLabel")text.Size=UDim2.fromScale(1,1)text.BackgroundTransparency=1
		text.Font=Enum.Font.GothamBold text.TextSize=28 text.TextColor3=Color3.fromRGB(242,235,201)text.Text="МУЗЕЙ\nГлиняных осколков: 0"text.Parent=face
		-- Вторая витрина: витринный образец SeaRelic (скоро)
		museumPart("Part","Pedestal2",Vector3.new(4,0.8,4),Vector3.new(base.X+7,0.4,base.Z),Color3.fromRGB(120,113,98))
		local relicShaft=museumPart("Part","RelicShaft",Vector3.new(0.28,1.5,0.28),Vector3.new(base.X+7,1.6,base.Z),Color3.fromRGB(128,96,68))
		relicShaft.Shape=Enum.PartType.Cylinder relicShaft.Material=Enum.Material.Metal relicShaft.Transparency=0.55
		local relicBar=museumPart("Part","RelicBar",Vector3.new(1.25,0.22,0.22),Vector3.new(base.X+7,2.0,base.Z),Color3.fromRGB(161,122,80))
		relicBar.Shape=Enum.PartType.Cylinder relicBar.CFrame=relicBar.CFrame*CFrame.Angles(0,0,math.rad(90)) relicBar.Material=Enum.Material.Metal relicBar.Transparency=0.55
		local relicTooth=museumPart("WedgePart","RelicTooth",Vector3.new(0.55,0.65,0.35),Vector3.new(base.X+7,1.0,base.Z),Color3.fromRGB(96,123,115))
		relicTooth.Material=Enum.Material.Slate relicTooth.Transparency=0.55
		local futureSign=museumPart("Part","FutureSign",Vector3.new(4,1.4,0.2),Vector3.new(base.X+7,2.2,base.Z-2.5),Color3.fromRGB(36,45,42))
		local futureFace=Instance.new("SurfaceGui")futureFace.Face=Enum.NormalId.Back futureFace.CanvasSize=Vector2.new(280,98)futureFace.LightInfluence=0 futureFace.Parent=futureSign
		local futureText=Instance.new("TextLabel")futureText.Size=UDim2.fromScale(1,1)futureText.BackgroundTransparency=1
		futureText.Font=Enum.Font.GothamBold futureText.TextSize=22 futureText.TextColor3=Color3.fromRGB(186,188,192)futureText.Text="НОВАЯ НАХОДКА\nСкоро"futureText.Parent=futureFace
		local mountain=plot.SandPrototype
		mountain:SetAttribute("OwnerUserId",player.UserId)
		mountain:SetAttribute("PersistenceStatus","Loading")
		plot.Parent=folder
		local reference=Instance.new("ObjectValue")
		reference.Name="SandPrototypeMountain"
		reference.Value=mountain
		reference.Parent=player
		-- Готовим HUD-состояние до загрузки мира: иначе HUD ждёт папку и показывает «Прогресс недоступен».
		local hudState=player:FindFirstChild("SandPrototypeState")
		if not hudState then
			hudState=Instance.new("Folder")
			hudState.Name="SandPrototypeState"
			hudState.Parent=player
		end
		local entry={player=player,plot=plot,slot=slot,loading=true}
		entries[player]=entry
		local function spawn(character)
			local root=character:WaitForChild("HumanoidRootPart",10)
			if root and not entry.closing and player.Character==character then
				character:PivotTo(plot.SpawnLocation.CFrame+Vector3.new(0,4,0))
			end
		end
		player.RespawnLocation=plot.SpawnLocation
		entry.spawnConnection=player.CharacterAdded:Connect(function(c)task.spawn(spawn,c)end)
		if player.Character then task.spawn(spawn,player.Character) end
		local ok,reason=pcall(function()
			local initial=PlotData.Fresh(height)
			if persistent then
				assert(game.GameId~=0,"Publish the place before persistent play")
				local service=game:GetService("DataStoreService")
				local existing=service:GetDataStore("DigMountainPlots_v1"):GetAsync("player_"..player.UserId)
				if not existing then
					local legacy=service:GetDataStore("DigMountainPrototype_v1"):GetAsync("shared_world_v1")
					local source
					initial,source=PlotData.Initial(player.UserId,legacy,os.time())
					assert(initial,source)
					if source=="fresh"then initial=PlotData.Fresh(height)
					elseif initial.initialCells<targetCells then initial=assert(PlotData.Grow(player.UserId,initial,targetCells))end
					mountain:SetAttribute("InitialProgressSource",source)
				end
			end
			entry.world=World.Start({owner=player,mountain=mountain,station=plot.SandPrototypeStation,
				terrain=useTerrain,
				persistent=persistent,key="player_"..player.UserId,initial=initial,
				validate=Finds.Validator(player.UserId,not persistent,false,targetCells),
				migrate=function(raw)
					if targetCells==455 then return PlotData.Expand(player.UserId,raw)end
					return PlotData.Grow(player.UserId,raw,targetCells)
				end,
				onSaved=relay,onChanged=publishPending,
				ownCanCarry=function()
					local account=entry.world and entry.world.GetAccount()
					return account and pending(player)<entry.world.GetFreeCapacity()
				end,
				canHelp=function(helper)
					local recipient=entries[helper]
					if not allowed(player,helper)or not recipient or recipient.closing or not recipient.world or not recipient.world.IsReady()then return false end
					local prepared,message=recipient.world.EnsureSource(player.UserId)
					if not prepared then local state=helper:FindFirstChild("SandPrototypeState")if state then state:SetAttribute("HelpStatus",message or "Подключаем сохранение помощника…")end return false end
					local account=recipient.world.GetAccount()
					return account and pending(helper)<recipient.world.GetFreeCapacity()
				end})
		end)
		entry.loading=false
		if entry.world then plot:SetAttribute("AccessMode",entry.world.GetAccess())relay()task.spawn(recover,entry)end
		if not ok then mountain:SetAttribute("PersistenceStatus","LoadFailed")warn("Personal plot load failed: "..tostring(reason)) end
		if not player.Parent and not entry.closing then task.spawn(close,entry) end
	end
	Players.PlayerAdded:Connect(function(p)task.spawn(add,p)end)
	Players.PlayerRemoving:Connect(function(p)if entries[p] then task.spawn(close,entries[p]) end end)
	game:BindToClose(function()
		shuttingDown=true
		for _,entry in entries do task.spawn(close,entry) end
		local deadline=os.clock()+28
		while next(entries) and os.clock()<deadline do task.wait(0.1) end
	end)
	for _,player in Players:GetPlayers() do task.spawn(add,player) end
end
return Plots
