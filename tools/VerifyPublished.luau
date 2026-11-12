-- Read-only CLI verification; never starts Play or touches DataStores.
local sss=game:GetService("ServerScriptService")
local function source(parent,name)
	local item=parent:FindFirstChild(name)
	return item and item:IsA("LuaSourceContainer") and item.Source or ""
end
local probe=game:GetService("StarterPack"):FindFirstChild("Лопата") or game.StarterPack:FindFirstChild("SandProbe")
local report={placeId=game.PlaceId,gameId=game.GameId,version=game.PlaceVersion,
	cells=workspace:FindFirstChild("SandPrototype") and #workspace.SandPrototype.Cells:GetChildren() or -1,
	persistent=sss:FindFirstChild("SandPrototype") and sss.SandPrototype:GetAttribute("PersistenceEnabled"),
	sources={server=source(sss,"SandPrototype"),economy=source(sss,"SandPrototypeEconomy"),
		snapshot=source(sss,"SandPrototypeSnapshot"),session=source(sss,"SandPrototypeSaveSession"),
		hud=source(game.StarterPlayer.StarterPlayerScripts,"SandPrototypeHUD"),
		feedback=source(game.StarterPlayer.StarterPlayerScripts,"SandPrototypeFeedback"),
		visits=source(game.StarterPlayer.StarterPlayerScripts,"SandPrototypeVisits"),
		world=source(sss,"SandPrototypeWorld"),plots=source(sss,"SandPrototypePlots"),
		coop=source(sss,"SandPrototypeCoopData"),access=source(sss,"SandPrototypeAccessRules"),
		finds=source(sss,"SandPrototypeFindData"),
		plotData=source(sss,"SandPrototypePlotData"),context=source(game.ReplicatedStorage,"SandPrototypeClientContext"),
		probe=probe and source(probe,"SandProbeClient") or ""}}
print("DIG_MOUNTAIN_VERIFY:"..game:GetService("HttpService"):JSONEncode(report))
return report
