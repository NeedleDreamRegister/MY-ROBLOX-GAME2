-- Private World.Close/Start integration, with temporary Terrain and a memory store.
return function()
 local scripts=game.ServerScriptService
 assert(not scripts.SandPrototype.Enabled and not workspace:FindFirstChild("SandPlots"))
 local p=assert(game.Players:GetPlayers()[1])
 local Finds=require(scripts.SandPrototypeFindData)
 local validate=Finds.Validator(p.UserId,false,false,562475)
 local initial=assert(validate(require(scripts.SandPrototypePlotData).Fresh(74)))
 local Field=require(game.ReplicatedStorage.SandPrototypeVoxelField)
 local field=Field.Create(initial.voxelChunks)local pending={}
 for x=-74,74 do for z=-74,74 do if #pending<10000 then
  assert(field.Set(x,0,z,false))pending[#pending+1]={x=x,y=0,z=z,budget=74}
 end end end
 initial.voxelChunks=field.Export()initial.pendingCollapses=pending initial.dugCells=10000
 initial.account.XP=10000 initial.account.Coins=10000 initial=assert(validate(initial))
 local storeModule=Instance.new("ModuleScript")storeModule.Name="QALargeQueueStore"
 storeModule.Source=[[
 local store={records={}}
 function store:UpdateAsync(key,callback)local value=callback(self.records[key])if value then self.records[key]=value end return value end
 return store
 ]]storeModule.Parent=scripts
 local clone=scripts.SandPrototypeWorld:Clone()clone.Name="QALargeQueueWorld"
 local source=clone.Source local needle='local store = game:GetService("DataStoreService"):GetDataStore("DigMountainPlots_v1")'
 local a,b=source:find(needle,1,true)assert(a,"store injection changed")
 clone.Source=source:sub(1,a-1).."local store=require(script.Parent.QALargeQueueStore)"..source:sub(b+1)clone.Parent=scripts
 local World=require(clone)local objects={}
 local function create()
  local mountain=workspace.SandPrototype:Clone()mountain.Name="LargeQueueQA"
  mountain:SetAttribute("TerrainOrigin",Vector3.new(602,2,-66))mountain:SetAttribute("OwnerUserId",p.UserId)
  for _,o in mountain.Cells:GetChildren()do o:Destroy()end mountain.Parent=workspace
  local station=workspace.SandPrototypeStation:Clone()station.Name="LargeQueueQAStation"station.Parent=workspace
  local object={mountain=mountain,station=station}table.insert(objects,object)
  object.world=assert(World.Start({owner=p,mountain=mountain,station=station,persistent=true,terrain=true,
   initial=initial,key="large-queue-world",validate=validate}))
  return object
 end
 local ok,result=xpcall(function()
  local first=create()
  assert(first.world.Close())first.world=nil first.mountain:Destroy()first.station:Destroy()
  local store=require(storeModule)local firstRaw=store.records["large-queue-world"]
  assert(firstRaw.formatVersion==4,"large queue did not use guarded envelope4")
  local before=assert(require(scripts.SandPrototypeSaveSession).Read(firstRaw,validate))
  assert(#before.pendingCollapses==10000,"World discarded waiting jobs before saving")
  local restored=create()task.wait(0.6)
  assert(restored.world.Close())restored.world=nil
  local raw=store.records["large-queue-world"]
  local final=assert(require(scripts.SandPrototypeSaveSession).Read(raw,validate))
  assert(#final.pendingCollapses>9000 and final.movedCells>0,"large queue failed to resume")
  assert(Field.Create(final.voxelChunks).Count()==552475 and final.dugCells==10000)
  assert(final.account.XP==10000 and final.account.Coins==10000 and final.account.CarriedCells==0)
  return {worldCloseStart=true,before=10000,pending=#final.pendingCollapses,moved=final.movedCells,
   remaining=552475,format=raw.formatVersion,noExtraRewards=true,productionStoreCalls=0}
 end,debug.traceback)
 for _,object in objects do if object.world then object.world.Close()end object.mountain:Destroy()object.station:Destroy()end
 clone:Destroy()storeModule:Destroy()
 assert(ok,result)return result
end
