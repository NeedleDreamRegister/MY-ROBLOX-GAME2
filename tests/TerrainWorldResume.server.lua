-- Run only in a disposable local-file Play session with the main script disabled.
-- Rebuilds an isolated full-size Terrain mountain through the actual World module.
return function()
 assert(game.GameId==0 and not game.ServerScriptService.SandPrototype.Enabled)
 local owner=assert(game.Players:GetPlayers()[1])
 local S=game.ServerScriptService
 local World=require(S.SandPrototypeWorld)
 local Progress=require(S.ProgressionData)
 local Field=require(game.ReplicatedStorage.SandPrototypeVoxelField)
 local Geometry=require(game.ReplicatedStorage.SandPrototypeGeometry)
 local Account=require(S.ProgressionAccount)
 local T=require(S.UpgradeTransactions)
 local folder=Instance.new('Folder');folder.Name='__QA_TerrainResume';folder.Parent=workspace
 local origin=Vector3.new(5002,2,5002)
 local offset=origin-require(S.SandPrototypePlotLayout).Get(36).origin
 local mountain=workspace.SandPrototype:Clone();mountain.Name='Mountain';mountain:PivotTo(mountain:GetPivot()+offset)
 mountain:SetAttribute('TerrainOrigin',origin);mountain.Parent=folder
 local station=workspace.SandPrototypeStation:Clone();station:PivotTo(station:GetPivot()+offset);station.Parent=folder
 if not game.ReplicatedStorage:FindFirstChild('DTMUpgradeRemote')then
  local remote=Instance.new('RemoteEvent');remote.Name='DTMUpgradeRemote';remote.Parent=game.ReplicatedStorage
 end
 local field=Field.Create(Geometry.Prepare(67525))
 assert(field.Set(15,0,36,false))
 local account=Account.New();assert(T.AddSand(account,1))
 local data={schemaVersion=4,ownerId=tostring(owner.UserId),revision=0,initialCells=67525,
  dugCells=1,movedCells=0,Cycles=0,LifetimeDug=1,voxelChunks=field.Export(),account=account,
  outbound={},imports={},accessMode='Closed',artifact=false,collection={},
  pendingCollapses={{x=15,y=0,z=36,budget=36}}}
 local validate=Progress.Validator(owner.UserId,false,67525)
 data=assert(validate(data))
 local active
 local function start(initial)
  active=assert(World.Start({owner=owner,mountain=mountain,station=station,initial=initial,
   validate=validate,persistent=false,terrain=true,key='never-used-local-test'}))
  assert(active.IsReady())
 end
 local function occupancy()
  local point=origin+Vector3.new(15,0,36)*4
  local _,o=workspace.Terrain:ReadVoxels(Region3.new(point-Vector3.new(2,2,2),point+Vector3.new(2,2,2)),4)
  return o[1][1][1]
 end
 local ok,result=xpcall(function()
  start(data)
  assert(occupancy()==0,'saved hole absent in initial Terrain')
  assert(active.Close());local saved=assert(validate(active.GetCommitted()));active=nil
  assert(saved.dugCells==1 and #saved.pendingCollapses==1)
  assert(saved.account.CarriedCells==1)
  local coins=saved.account.Coins
  assert(occupancy()==0,'Terrain reservation not cleaned up')
  -- Closing clears runtime chunk objects before the same mountain is reopened.
  local chunks=mountain.Cells:FindFirstChild('Chunks');if chunks then chunks:Destroy()end
  start(saved)
  assert(occupancy()==0,'reopen regenerated the removed cell before collapse')
  local deadline=os.clock()+5
  repeat task.wait(.1)until mountain:GetAttribute('PendingCollapses')==0 or os.clock()>deadline
  assert(mountain:GetAttribute('PendingCollapses')==0,'restored collapse did not drain')
  assert(mountain:GetAttribute('DugCells')==1 and mountain:GetAttribute('RemainingCells')==67524)
  assert(mountain:GetAttribute('MovedCells')>0 and occupancy()==1,'pending mass did not move into vacancy')
  assert(active.GetAccount().CarriedCells==1 and active.GetAccount().Coins==coins,'resume awarded sand twice')
  local moved=mountain:GetAttribute('MovedCells')
  assert(active.Close());active=nil
  assert(occupancy()==0,'final Terrain cleanup failed')
  return {remaining=67524,dug=1,moved=moved,pending=0,restoredTerrain=true,duplicateReward=false,productionWrites=0}
 end,debug.traceback)
 if active then active.Close()end
 folder:Destroy()
 assert(ok,result)
 return result
end
