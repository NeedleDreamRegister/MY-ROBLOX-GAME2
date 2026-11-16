-- Actual small Terrain + actual World queue. Disposable local-file Play only.
return function()
 assert(game.GameId==0 and not game.ServerScriptService.SandPrototype.Enabled)
 local owner=assert(game.Players:GetPlayers()[1]);local ch=owner.Character
 local root=ch.HumanoidRootPart;local oldPose=ch:GetPivot();local oldAnchored=root.Anchored
 ch.Humanoid:UnequipTools()
 local S=game.ServerScriptService
 local Field=require(game.ReplicatedStorage.SandPrototypeVoxelField)
 local Geometry=require(game.ReplicatedStorage.SandPrototypeGeometry)
 local World=require(S.SandPrototypeWorld)
 local origin=Vector3.new(5002,2,5002)
 local field=Field.Create(Geometry.Prepare(455));assert(field.Set(0,0,6,false))
 local folder=Instance.new('Folder');folder.Name='__QA_TerrainBody';folder.Parent=workspace
 local floor=Instance.new('Part');floor.Anchored=true;floor.Size=Vector3.new(80,.5,80)
 floor.Position=Vector3.new(5002,-.25,5002);floor.Parent=folder
 local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={workspace.Terrain}
 local function feet()
  local points={}
  for _,name in {'LeftFoot','RightFoot'}do
   local f=ch[name];points[#points+1]=f.CFrame:PointToWorldSpace(Vector3.new(0,-f.Size.Y/2,0))
  end
  return points
 end
 local function intrusion(points)
  local worst=-math.huge
  for _,point in points do
   local hit=workspace:Raycast(Vector3.new(point.X,30,point.Z),Vector3.new(0,-40,0),rays)
   worst=math.max(worst,(hit and hit.Position.Y or 0)-point.Y)
  end
  return worst
 end
 local renderer,world
 local ok,result=xpcall(function()
  renderer=require(S.SandPrototypeTerrain).Create(origin,function(x,y,z)return field.Has(x,y,z)end)
  -- Terrain collision meshes lag behind voxel writes. Wait before measuring.
  task.wait(.25)
  root.Anchored=true;ch:PivotTo(CFrame.new(4998.5,7.54,5027));task.wait(.1)
  local lift=intrusion(feet())+.15
  if lift>0 then ch:PivotTo(ch:GetPivot()+Vector3.new(0,lift,0));task.wait(.05)end
  local before=intrusion(feet())
  assert(before<-.1,'fixture did not start outside the sand')
  local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include
  overlap.FilterDescendantsInstances={ch};overlap.MaxParts=1
  local oldCount=#workspace:GetPartBoundsInBox(CFrame.new(origin+Vector3.new(0,0,24)),Vector3.new(3.8,3.8,3.8),overlap)
  assert(oldCount==0,'fixture does not reproduce the old guard gap')
  renderer.Destroy();renderer=nil;task.wait(.15)
  local offset=origin-require(S.SandPrototypePlotLayout).Get(36).origin
  local mountain=workspace.SandPrototype:Clone();mountain.Name='Mountain'
  mountain:PivotTo(mountain:GetPivot()+offset);mountain:SetAttribute('TerrainOrigin',origin);mountain.Parent=folder
  local station=workspace.SandPrototypeStation:Clone();station:PivotTo(station:GetPivot()+offset);station.Parent=folder
  if not game.ReplicatedStorage:FindFirstChild('DTMUpgradeRemote')then
   local remote=Instance.new('RemoteEvent');remote.Name='DTMUpgradeRemote';remote.Parent=game.ReplicatedStorage
  end
  local account=require(S.ProgressionAccount).New();assert(require(S.UpgradeTransactions).AddSand(account,1))
  local initial={schemaVersion=4,ownerId=tostring(owner.UserId),revision=0,initialCells=455,
   dugCells=1,movedCells=0,Cycles=0,LifetimeDug=1,voxelChunks=field.Export(),account=account,
   outbound={},imports={},accessMode='Closed',artifact=false,collection={},pendingCollapses={{x=0,y=0,z=6,budget=6}}}
  local validate=require(S.ProgressionData).Validator(owner.UserId,false,455)
  world=assert(World.Start({owner=owner,mountain=mountain,station=station,initial=assert(validate(initial)),
   validate=validate,persistent=false,terrain=true,key='never-used-body-test'}))
  assert(world.IsReady());task.wait(.35)
  local after=intrusion(feet())
  local moved=mountain:GetAttribute('MovedCells');local pending=mountain:GetAttribute('PendingCollapses')
  assert(after<=.03 and moved==0 and pending>0,game.HttpService:JSONEncode({intrusion=after,moved=moved,pending=pending}))
  local carried=world.GetAccount().CarriedCells;local coins=world.GetAccount().Coins
  ch:PivotTo(oldPose)
  local deadline=os.clock()+3
  repeat task.wait(.1)until mountain:GetAttribute('PendingCollapses')==0 or os.clock()>deadline
  assert(mountain:GetAttribute('PendingCollapses')==0,'queue failed to resume after player left')
  assert(mountain:GetAttribute('MovedCells')>0 and mountain:GetAttribute('RemainingCells')==454)
  assert(world.GetAccount().CarriedCells==carried and world.GetAccount().Coins==coins,'collapse paid a reward')
  return {beforeIntrusion=before,protectedIntrusion=after,oldOverlaps=oldCount,
   blockedJobs=pending,movedAfterExit=mountain:GetAttribute('MovedCells'),remaining=454,dug=1,productionWrites=0}
 end,debug.traceback)
 if world then world.Close()end
 if renderer then renderer.Destroy()end
 ch:PivotTo(oldPose);root.Anchored=oldAnchored;folder:Destroy()
 assert(ok,result)
 return result
end
