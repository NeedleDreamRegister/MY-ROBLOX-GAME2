-- Play-only integration of the existing World at height12/74, with a QA memory store.
-- Main SandPrototype must be disabled. Call returned Finish after one client shovel hit.
return function(height)
 height=height or 12
 local size=assert(require(game.ReplicatedStorage.SandPrototypeGeometry).Size(height))
 local edge=math.ceil((height+1)/4)*4
 local p=assert(game.Players:GetPlayers()[1])
 assert(not game.ServerScriptService.SandPrototype.Enabled)
 local scripts=game.ServerScriptService
 local origin=Vector3.new(602,2,-66)
 local storeModule=Instance.new("ModuleScript")storeModule.Name="QANativeWorldStore"
 storeModule.Source=[[
 local store={records={}}
 local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
 function store:UpdateAsync(k,callback)local value=callback(copy(self.records[k]))if value then self.records[k]=copy(value)end return copy(value)end
 return store
 ]]storeModule.Parent=scripts
 local cloned=scripts.SandPrototypeWorld:Clone()cloned.Name="QANativeWorld"
 local source=cloned.Source local needle='local store = game:GetService("DataStoreService"):GetDataStore("DigMountainPlots_v1")'
 local a,b=source:find(needle,1,true)assert(a)
 cloned.Source=source:sub(1,a-1).."local store=require(script.Parent.QANativeWorldStore)"..source:sub(b+1)cloned.Parent=scripts
 local World=require(cloned)
 local Finds=require(scripts.SandPrototypeFindData)
 local validate=Finds.Validator(p.UserId,false,false,size)
 local initial=assert(validate(require(scripts.SandPrototypePlotData).Fresh(height)))
 local folder=Instance.new("Folder")folder.Name="SandPlots"folder.Parent=workspace
 local plot=Instance.new("Folder")plot.Name="Plot_"..p.UserId plot.Parent=folder
 local ground=Instance.new("Part")ground.Name="QANativeGround"ground.Anchored=true ground.Size=Vector3.new(height*8+48,1,height*8+48)
 ground.Position=Vector3.new(origin.X,-.5,origin.Z)ground.Parent=plot
 local reference=Instance.new("ObjectValue")reference.Name="SandPrototypeMountain"reference.Parent=p
 local function create()
  local mountain=workspace.SandPrototype:Clone()mountain.Name="SandPrototype"
  mountain:SetAttribute("TerrainOrigin",origin)mountain:SetAttribute("OwnerUserId",p.UserId)mountain.Parent=plot
  local station=workspace.SandPrototypeStation:Clone()station.Name="SandPrototypeStation"station.Parent=plot
  local world=assert(World.Start({owner=p,mountain=mountain,station=station,persistent=true,terrain=true,initial=initial,
   key="native-world",validate=validate}))
  reference.Value=mountain
  return {world=world,mountain=mountain,station=station}
 end
 local object=create()
 p.Character:PivotTo(CFrame.lookAt(origin+Vector3.new(height*4+8,1,0),origin+Vector3.new(height*4,1,0)))
 p.Character.Humanoid:EquipTool(p.Backpack:FindFirstChildOfClass("Tool"))
 local result={mountain=object.mountain,origin=origin,height=height,size=size}
 function result.Finish()
  local mountain=object.mountain
  assert(mountain:GetAttribute("DugCells")==1 and mountain:GetAttribute("RemainingCells")==size-1,"large-edge shovel action not accepted exactly once")
  local deadline=os.clock()+3
  while mountain:GetAttribute("PendingCollapses")>0 and os.clock()<deadline do task.wait(.1)end
  assert(mountain:GetAttribute("MovedCells")==height and mountain:GetAttribute("PendingCollapses")==0)
  local F=require(game.ReplicatedStorage.SandPrototypeVoxelField)local map={}
  if mountain.Cells.Chunks:GetAttribute("GeometryEncoding")=="pyramid-v1-delta"then
   map=table.clone(require(game.ReplicatedStorage.SandPrototypeGeometry).Prepare(size))
  end
  local replicatedChunks=#mountain.Cells.Chunks:GetChildren()
  for _,v in mountain.Cells.Chunks:GetChildren()do map[v.Name]=v.Value end local field=F.Create(map)
  assert(field.Count()==size-1 and #mountain.Cells:GetChildren()==1,"per-cell Parts returned")
  local checked=0
  for x=-edge,edge-1,16 do for y=0,edge-1,16 do for z=-edge,edge-1,16 do
   local sx,sy,sz=math.min(16,edge-x),math.min(16,edge-y),math.min(16,edge-z)
   local minimum=origin+Vector3.new(x*4-2,y*4-2,z*4-2)
   local _,occupancy=workspace.Terrain:ReadVoxels(Region3.new(minimum,minimum+Vector3.new(sx,sy,sz)*4),4)
   for a=1,sx do for b=1,sy do for c=1,sz do
    assert((occupancy[a][b][c]>0)==field.Has(x+a-1,y+b-1,z+c-1),"World Terrain/bitset mismatch")checked+=1
   end end end task.wait()
  end end end
  assert(object.world.Close())object.mountain:Destroy()object.station:Destroy()
  local raw=require(storeModule).records["native-world"]
  assert(raw.formatVersion==3 and raw.snapshot.cells==nil,"large World capture expanded to cell tables")
  object=create()
  assert(object.mountain:GetAttribute("DugCells")==1 and object.mountain:GetAttribute("MovedCells")==height)
  local a=object.world.GetAccount()assert(a.XP==1 and a.CarriedCells==1 and a.Coins==0)
  assert(object.world.Close())
  reference:Destroy()folder:Destroy()cloned:Destroy()storeModule:Destroy()
  return {initial=size,remaining=size-1,dug=1,moved=height,pending=0,checkedVoxels=checked,worldReopened=true,
   savedFormat=3,chunkNative=true,replicatedChunks=replicatedChunks,proxyParts=0,xp=1,carried=1,coins=0,productionStoreCalls=0}
 end
 return result
end
