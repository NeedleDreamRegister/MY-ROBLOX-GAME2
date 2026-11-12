-- Resource accounting with an injected cart; no scene or DataStore mutation.
return function(source)
	local backpack,state=Instance.new("Folder"),Instance.new("Folder")
	local added,removed,spawned=Instance.new("BindableEvent"),Instance.new("BindableEvent"),Instance.new("BindableEvent")
	local player={UserId=42,Backpack=backpack,CharacterAdded=spawned.Event}
	local root={Position=Vector3.zero}
	player.Character={GetChildren=function()return{}end,FindFirstChild=function(_,n)if n=="HumanoidRootPart"then return root end end,
		FindFirstChildOfClass=function(_,n)if n=="Humanoid"then return{Health=100}end end}
	function player:FindFirstChild(n)if n=="SandPrototypeState"then return state end end
	function player:FindFirstChildOfClass(n)if n=="Backpack"then return backpack end end
	local clock=1
	local fakeOs=table.clone(os)fakeOs.clock=function()return clock end
	local players={PlayerAdded=added.Event,PlayerRemoving=removed.Event,GetPlayers=function()return{player}end}
	local realGame=game
	local env={os=fakeOs,game={GetService=function(_,n)if n=="Players"then return players end return realGame:GetService(n)end}}
	setmetatable(env,{__index=getfenv(0)})
	local chunk=assert(loadstring(source))setfenv(chunk,env)
	local economy=chunk().Create(player)
	local near,delivered=true,false
	local shown=0
	local cart={CanLoad=function()return near end,CanSell=function()return delivered end,
		Update=function(s)shown=s.CartCells end,Destroy=function()end}
	economy.Init({["42"]={CarriedCells=0,CartCells=0,CapacityCells=100,CapacityLevel=0,BarrowOwned=1,ShovelLevel=0,Coins=0,XP=25}},nil,nil,false,cart)
	for _=1,100 do economy.RecordDig(player)end
	assert(shown==80 and economy.GetSnapshot(player).CarriedCells==100)
	assert(not economy.CanCarry(player),"overfilled total capacity")
	near=false
	local pad={Position=Vector3.zero}
	assert(economy.Sell(player,pad),"manual sale denied")
	local a=economy.GetSnapshot(player)
	assert(a.CarriedCells==80 and a.CartCells==80 and a.Coins==20,"sold undelivered cart")
	clock+=1
	assert(not economy.Sell(player,pad),"duplicate sale accepted")
	assert(economy.FreeCapacity(player)==20)
	assert(economy.Credit(player,20),"manual helper credit denied")
	assert(not economy.CanCarry(player),"distant cart enabled extra capacity")
	assert(not economy.Credit(player,1),"overfilled manual carry")
	delivered=true clock+=1
	assert(economy.Sell(player,pad),"delivered cart sale denied")
	local final=economy.GetSnapshot(player)
	assert(final.CartCells==0 and final.CarriedCells==0 and shown==0,"cart load not cleared")
	assert(final.Coins==120 and final.XP==145,"mass or rewards changed")
	clock+=1 assert(not economy.Sell(player,pad),"sold empty cart twice")
	economy.Destroy()backpack:Destroy()state:Destroy()added:Destroy()removed:Destroy()spawned:Destroy()
	return {cartCapacity=80,manualCapacity=20,coins=final.Coins,xp=final.XP,remoteCartSaleDenied=true,realDataStoreCalls=0}
end
