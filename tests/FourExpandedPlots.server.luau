-- Private Play at the selected TerrainHeight, PersistenceEnabled=false.
-- Three synthetic owners exercise world/terrain layout, not four real clients.
return function(height)
 height=height or 12
 local p=game.Players:GetPlayers()[1]
 local own=workspace.SandPlots["Plot_"..p.UserId]
 local layout=require(game.ServerScriptService.SandPrototypePlotLayout).Get(height)
 assert(own.SandPrototype:GetAttribute("InitialCells")==layout.cells and own.SandPrototype:GetAttribute("PersistenceStatus")=="SessionOnly")
 local worldModule=game.ServerScriptService.SandPrototypeWorld:Clone()worldModule.Name="QAFourWorld"
 -- Synthetic owners have no Players membership; only the shop's read uses their
 -- initialized account row. No purchases, grants or dig permissions are mocked.
 local needle='local Economy = require(script.Parent:WaitForChild("SandPrototypeEconomy")).Create(config.owner)'
 local a,b=worldModule.Source:find(needle,1,true)assert(a)
 local shim=needle..[[
 local nativeSnapshot=Economy.GetSnapshot
 Economy.GetSnapshot=function(actor)
  return nativeSnapshot(actor)or Economy.ExportAccounts()[tostring(actor.UserId)]
 end
 ]]
 worldModule.Source=worldModule.Source:sub(1,a-1)..shim..worldModule.Source:sub(b+1)
 worldModule.Parent=game.ServerScriptService
 local World=require(worldModule)
 local Finds=require(game.ServerScriptService.SandPrototypeFindData)
 local Plot=require(game.ServerScriptService.SandPrototypePlotData)
 local peers={}
 for slot=2,4 do
  local offset=Vector3.new(((slot-1)%2)*layout.spacing,0,math.floor((slot-1)/2)*layout.spacing)
  local clone=own:Clone()clone.Name="Plot_"..(9000+slot)clone:SetAttribute("OwnerUserId",9000+slot)
  for _,v in clone:GetDescendants()do if v:IsA("BaseScript")then v.Enabled=false end end
  clone.SandPrototype.Cells:ClearAllChildren()
  for _,v in clone.SandPrototypeStation:GetChildren()do if v.Name=="ShovelUpgradePad"then v:Destroy()end end
  clone:PivotTo(clone:GetPivot()+offset)
  clone.SandPrototype:SetAttribute("OwnerUserId",9000+slot)clone.SandPrototype:SetAttribute("TerrainOrigin",layout.origin+offset)
  clone.Parent=workspace.SandPlots
  local owner={UserId=9000+slot,Character=nil}
  function owner:FindFirstChild()return nil end
  local initial=Plot.Fresh(height)
  local world=assert(World.Start({owner=owner,mountain=clone.SandPrototype,station=clone.SandPrototypeStation,
   terrain=true,persistent=false,initial=initial,validate=Finds.Validator(owner.UserId,false,false,layout.cells),canHelp=function()return false end}))
  peers[#peers+1]={world=world,plot=clone,owner=owner}
 end
 local api={peers=peers}
 function api.Check()
  local total=own.SandPrototype:GetAttribute("RemainingCells")
  for _,entry in peers do
   local m=entry.plot.SandPrototype
   assert(m:GetAttribute("RemainingCells")==layout.cells and m:GetAttribute("DugCells")==0,"foreign plot changed")
   local top=height*4+20
   local hit=workspace:Raycast(m:GetAttribute("TerrainOrigin")+Vector3.new(0,top,0),Vector3.new(0,-top-10,0))
   assert(hit and hit.Material==Enum.Material.Sand,"peer Terrain missing")
   total+=layout.cells
  end
  return {regions=4,syntheticOwners=3,spacing=layout.spacing,sandRemaining=total,foreignPlotsIntact=true,productionCalls=0}
 end
 function api.Destroy()
  for _,entry in peers do assert(entry.world.Close())entry.plot:Destroy()end
  worldModule:Destroy()
 end
 return api
end
