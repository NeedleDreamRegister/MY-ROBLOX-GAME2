-- Actual World/carts/Terrain; isolated local-file Play, no DataStore writes.
return function(level)
 assert(game.GameId==0 and not game.ServerScriptService.SandPrototype.Enabled)
 level=level or 1
 local S=game.ServerScriptService;local owner=game.Players:GetPlayers()[1]
 local ch=owner.Character;local root=ch.HumanoidRootPart
 local pose=ch:GetPivot();local anchored=root.Anchored
 local folder=Instance.new('Folder');folder.Name='__QA_CartClearance';folder.Parent=workspace
 local origin=Vector3.new(5002,2,5002)
 local floor=Instance.new('Part');floor.Anchored=true;floor.Size=Vector3.new(80,.5,80)
 floor.Position=Vector3.new(5002,-.25,5002);floor.Parent=folder
 local world
 local ok,result=xpcall(function()
  root.Anchored=true;ch:PivotTo(CFrame.new(5002,3,5026))
  local offset=origin-require(S.SandPrototypePlotLayout).Get(36).origin
  local mountain=workspace.SandPrototype:Clone();mountain:PivotTo(mountain:GetPivot()+offset)
  mountain:SetAttribute('TerrainOrigin',origin);mountain.Parent=folder
  local station=workspace.SandPrototypeStation:Clone();station:PivotTo(station:GetPivot()+offset);station.Parent=folder
  if not game.ReplicatedStorage:FindFirstChild('DTMUpgradeRemote')then
   local r=Instance.new('RemoteEvent');r.Name='DTMUpgradeRemote';r.Parent=game.ReplicatedStorage
  end
  local field=require(game.ReplicatedStorage.SandPrototypeVoxelField).Create(require(game.ReplicatedStorage.SandPrototypeGeometry).Prepare(455))
  assert(field.Set(0,0,6,false))
  local a=require(S.ProgressionAccount).New();a.CartLevel=level;a.CartEnabled=true;a.CartCells=1;a.XP=1
  local validate=require(S.ProgressionData).Validator(owner.UserId,false,455)
  local initial=assert(validate({schemaVersion=4,ownerId=tostring(owner.UserId),revision=0,initialCells=455,
   dugCells=1,movedCells=0,Cycles=0,LifetimeDug=1,voxelChunks=field.Export(),account=a,
   outbound={},imports={},accessMode='Closed',artifact=false,collection={},pendingCollapses={{x=0,y=0,z=6,budget=6}}}))
  world=assert(require(S.SandPrototypeWorld).Start({owner=owner,mountain=mountain,station=station,
   initial=initial,validate=validate,persistent=false,terrain=true,key='never-used-cart-clearance'}))
  local coins=world.GetAccount().Coins
  local cart=assert(folder:FindFirstChild('FollowWheelbarrow'));task.wait(.25)
  local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={workspace.Terrain}
  local function height()
   local hit=workspace:Raycast(Vector3.new(5002,30,5026),Vector3.new(0,-40,0),rays)
   return hit and hit.Position.Y or 0
  end
  local before=height();local bottom=before+.15
  cart:PivotTo(cart:GetPivot()+Vector3.new(5002,bottom+cart.TrayBottom.Size.Y/2,5026)-cart.TrayBottom.Position)
  for _,part in cart:GetDescendants()do if part:IsA('BasePart')then assert(not part.CanQuery)end end
  ch:PivotTo(pose);task.wait(.5)
  local after=height();local moved=mountain:GetAttribute('MovedCells');local pending=mountain:GetAttribute('PendingCollapses')
  assert(after<bottom and moved==0 and pending>0,game.HttpService:JSONEncode({before=before,after=after,trayBottom=bottom,moved=moved,pending=pending}))
  cart:PivotTo(cart:GetPivot()+Vector3.new(30,0,0))
  local deadline=os.clock()+3
  repeat task.wait(.1)until mountain:GetAttribute('PendingCollapses')==0 or os.clock()>deadline
  assert(mountain:GetAttribute('PendingCollapses')==0 and mountain:GetAttribute('MovedCells')>0,'collapse did not resume')
  assert(mountain:GetAttribute('RemainingCells')==454 and mountain:GetAttribute('DugCells')==1,'mass changed')
  assert(world.GetAccount().CartCells==1 and world.GetAccount().Coins==coins,'cargo/reward changed')
  return {level=level,before=before,after=after,trayBottom=bottom,pending=pending,movedAfterExit=mountain:GetAttribute('MovedCells'),cargo=1,remaining=454,dug=1}
 end,debug.traceback)
 if world then world.Close()end
 folder:Destroy();ch:PivotTo(pose);root.Anchored=anchored
 assert(ok,result);return result
end
