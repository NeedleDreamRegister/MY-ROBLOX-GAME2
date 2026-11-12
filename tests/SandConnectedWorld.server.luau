-- Studio Play only with the main SandPrototype Script disabled.
-- Uses an injected in-memory store, exact World.Close/Start, and temporary Terrain.
return function()
 local p=assert(game.Players:GetPlayers()[1])
 assert(not game.ServerScriptService.SandPrototype.Enabled,"disable the main Script before this isolated test")
 local scripts=game.ServerScriptService
 local root=p.Character:WaitForChild("HumanoidRootPart")
 local oldPose,oldAnchored=root.CFrame,root.Anchored
 local origin=Vector3.new(602,2,-66)
 local storeModule=Instance.new("ModuleScript")storeModule.Name="QAConnectedStore"
 storeModule.Source=[[
 local store={records={}}
 local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
 function store:UpdateAsync(k,callback)local value=callback(copy(self.records[k]))if value then self.records[k]=copy(value)end return copy(value)end
 return store
 ]]storeModule.Parent=scripts
 local clone=scripts.SandPrototypeWorld:Clone()clone.Name="QAConnectedWorld"
 local source=clone.Source
 local needle='local store = game:GetService("DataStoreService"):GetDataStore("DigMountainPlots_v1")'
 local a,b=source:find(needle,1,true)assert(a,"store injection changed")
 clone.Source=source:sub(1,a-1).."local store=require(script.Parent.QAConnectedStore)"..source:sub(b+1)
 clone.Parent=scripts
 local World=require(clone)
 local Finds=require(scripts.SandPrototypeFindData)
 local initial=assert(Finds.Validator(p.UserId)(require(scripts.SandPrototypePlotData).Fresh()))
 initial.cells={{x=0,y=2,z=0},{x=0,y=3,z=0}}initial.dugCells=453
 initial.account.Coins=453 initial.account.XP=453 initial.artifact=false initial.collection={}
 initial.pendingCollapses={{x=0,y=0,z=0,budget=6},{x=0,y=1,z=0,budget=5}}
 initial=assert(Finds.Validator(p.UserId)(initial))
 local objects={}
 local function create()
  local mountain=workspace.SandPrototype:Clone()mountain.Name="ConnectedQA"
  mountain:SetAttribute("TerrainOrigin",origin)mountain:SetAttribute("OwnerUserId",p.UserId)
  for _,v in mountain.Cells:GetChildren()do if v:IsA("BasePart")then
   v.Position=origin+Vector3.new(v:GetAttribute("GridX"),v:GetAttribute("GridY"),v:GetAttribute("GridZ"))*4
   v.Size=Vector3.new(4,4,4)
  end end
  mountain.Parent=workspace
  local station=workspace.SandPrototypeStation:Clone()station.Name="ConnectedQAStation"station.Parent=workspace
  local object={mountain=mountain,station=station}table.insert(objects,object)
  object.world=assert(World.Start({owner=p,mountain=mountain,station=station,persistent=true,terrain=true,
   initial=initial,key="connected-holes",validate=Finds.Validator(p.UserId)}))
  return object
 end
 local ok,result=xpcall(function()
  root.Anchored=true p.Character:PivotTo(CFrame.new(origin+Vector3.new(0,1,0)))
  local first=create()task.wait(.6)
  assert(first.mountain:GetAttribute("MovedCells")==0 and first.mountain:GetAttribute("PendingCollapses")==1,"blocked upper vacancy not reproduced")
  assert(first.world.Close())first.world=nil first.mountain:Destroy()first.station:Destroy()
  local raw=require(storeModule).records["connected-holes"]
  assert(raw.formatVersion==2 and #raw.snapshot.pendingCollapses==1,"unfinished collapse not stored")
  local restored=create()task.wait(.3)
  assert(restored.mountain:GetAttribute("MovedCells")==0,"blocked player buried on restore")
  p.Character:PivotTo(CFrame.new(origin+Vector3.new(38,1,0)))
  local deadline=os.clock()+4
  repeat task.wait(.1)until restored.mountain:GetAttribute("PendingCollapses")==0 or os.clock()>deadline
  assert(restored.mountain:GetAttribute("MovedCells")==5 and restored.mountain:GetAttribute("RemainingCells")==2,"old lower holes did not wake")
  assert(restored.world.Close())restored.world=nil
  raw=require(storeModule).records["connected-holes"]
  local data=assert(require(scripts.SandPrototypeSaveSession).Read(raw,Finds.Validator(p.UserId)))
  assert(data.dugCells==453 and data.account.XP==453 and data.account.Coins==453 and data.account.CarriedCells==0)
  assert(#data.cells==2 and #data.pendingCollapses==0)
  for _,v in data.cells do assert(v.y==0,"sand still floating after restore")end
  return {worldCloseAndStart=true,oldLowerHolesWoken=true,moved=5,remaining=2,pending=0,xp=453,coins=453,noExtraRewards=true,productionStoreCalls=0}
 end,debug.traceback)
 for _,object in objects do
  if object.world then object.world.Close()end
  object.mountain:Destroy()object.station:Destroy()
 end
 root.CFrame=oldPose root.Anchored=oldAnchored
 clone:Destroy()storeModule:Destroy()
 assert(ok,result)return result
end
