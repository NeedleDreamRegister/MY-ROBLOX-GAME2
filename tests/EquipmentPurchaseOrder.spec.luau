-- Actual economy module with fake players/time, isolated Instances and no DataStore.
return function(source)
	local realGame=game
	local function scenario(first,second)
		local backpack=Instance.new("Folder")
		local state=Instance.new("Folder")
		local added,removed=Instance.new("BindableEvent"),Instance.new("BindableEvent")
		local spawned=Instance.new("BindableEvent")
		local player={UserId=42,Backpack=backpack,CharacterAdded=spawned.Event}
		local root={Position=Vector3.zero}
		local humanoid={Health=100}
		player.Character={FindFirstChild=function(_,name)if name=="HumanoidRootPart"then return root end end,
			GetChildren=function()return{}end,
			FindFirstChildOfClass=function(_,name)if name=="Humanoid"then return humanoid end end}
		function player:FindFirstChild(name)if name=="SandPrototypeState"then return state end end
		function player:FindFirstChildOfClass(name)if name=="Backpack"then return backpack end end
		local players={PlayerAdded=added.Event,PlayerRemoving=removed.Event,GetPlayers=function()return{player}end}
		local clock=1
		local fakeOs=table.clone(os)fakeOs.clock=function()return clock end
		local env={os=fakeOs,game={GetService=function(_,name)
			if name=="Players"then return players end
			return realGame:GetService(name)
		end}}
		setmetatable(env,{__index=getfenv(0)})
		local chunk=assert(loadstring(source))setfenv(chunk,env)
		local economy=chunk().Create(player)
		economy.Init({["42"]={CarriedCells=0,CapacityCells=20,CapacityLevel=0,BarrowOwned=0,Coins=100,XP=100}})
		local pad={Position=Vector3.zero}
		assert(economy[first](player,pad),"first purchase failed")
		local dug=first=="BuyWheelbarrow"and 60 or 0
		for _=1,dug do economy.RecordDig(player) end
		clock+=1
		assert(economy[second](player,pad),"second purchase failed")
		clock+=1
		assert(economy.BuyShovel(player,pad),"shovel purchase failed")
		local result=economy.GetSnapshot(player)
		clock+=1
		assert(not economy[second](player,pad),"duplicate purchase accepted")
		clock+=1
		assert(not economy.BuyShovel(player,pad),"duplicate shovel accepted")
		local after=economy.GetSnapshot(player)
		backpack:ClearAllChildren()spawned:Fire()task.wait()
		assert(backpack:FindFirstChild("WheelbarrowTool"),"owned cart lost after respawn")
		spawned:Fire()task.wait()
		assert(#backpack:GetChildren()==1,"respawn duplicated owned cart")
		economy.Destroy()backpack:Destroy()state:Destroy()added:Destroy()removed:Destroy()spawned:Destroy()
		assert(result.CapacityCells==120,"equipment order lost wheelbarrow capacity: "..result.CapacityCells)
		assert(result.Coins==45 and after.Coins==45 and result.XP==100+dug,"purchase duplicated or changed XP")
		assert(result.ShovelLevel==1,"shovel upgrade missing")
		assert(result.CarriedCells==dug and result.CarriedCells<=result.CapacityCells,"carried sand lost or exceeds capacity")
		assert(result.CapacityLevel==1 and result.BarrowOwned==1,"equipment flags changed")
		return result.CapacityCells
	end
	return {cartThenBag=scenario("BuyWheelbarrow","BuyCapacity"),bagThenCart=scenario("BuyCapacity","BuyWheelbarrow"),realDataStoreCalls=0}
end
