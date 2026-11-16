return function()
 assert(game.GameId==0 and not game.ServerScriptService.SandPrototype.Enabled)
 local S=game.ServerScriptService;local owner=game.Players:GetPlayers()[1]
 local pose=owner.Character:GetPivot();local root=owner.Character.HumanoidRootPart;local anchored=root.Anchored;root.Anchored=true;owner.Character:PivotTo(CFrame.new(5200,5,5002))
 local folder=Instance.new('Folder');folder.Name='__QA_BulkSand';folder.Parent=workspace
 local origin=Vector3.new(5002,2,5002);local offset=origin-require(S.SandPrototypePlotLayout).Get(36).origin
 local mountain=workspace.SandPrototype:Clone();mountain:PivotTo(mountain:GetPivot()+offset);mountain:SetAttribute('TerrainOrigin',origin);mountain.Parent=folder
 local station=workspace.SandPrototypeStation:Clone();station:PivotTo(station:GetPivot()+offset);station.Parent=folder
 if not game.ReplicatedStorage:FindFirstChild('DTMUpgradeRemote')then local r=Instance.new('RemoteEvent');r.Name='DTMUpgradeRemote';r.Parent=game.ReplicatedStorage end
 local field=require(game.ReplicatedStorage.SandPrototypeVoxelField).Create(require(game.ReplicatedStorage.SandPrototypeGeometry).Prepare(67525))
 local jobs={};for x=-5,5 do for z=-5,5 do assert(field.Set(x,0,z,false));jobs[#jobs+1]={x=x,y=0,z=z,budget=36}end end
 local a=require(S.ProgressionAccount).New();a.CartLevel=2;a.CartEnabled=true;assert(require(S.UpgradeTransactions).AddSand(a,#jobs))
 local validate=require(S.ProgressionData).Validator(owner.UserId,false,67525)
 local data=assert(validate({schemaVersion=4,ownerId=tostring(owner.UserId),revision=0,initialCells=67525,dugCells=#jobs,movedCells=0,Cycles=0,LifetimeDug=#jobs,voxelChunks=field.Export(),account=a,outbound={},imports={},accessMode='Closed',artifact=false,collection={},pendingCollapses=jobs}))
 local world=assert(require(S.SandPrototypeWorld).Start({owner=owner,mountain=mountain,station=station,initial=data,validate=validate,persistent=false,terrain=true,key='never-used-bulk-sand'}))
 local api={world=world,mountain=mountain,frames={},started=os.clock(),coins=world.GetAccount().Coins}
 api.connection=game:GetService('RunService').Heartbeat:Connect(function(dt)if mountain:GetAttribute('PendingCollapses')>0 then api.frames[#api.frames+1]=dt*1000 elseif not api.drainedAt then api.drainedAt=os.clock();workspace:SetAttribute('__QA_CollapseActive',false)end end)
 workspace:SetAttribute('__QA_CollapseActive',true)
 function api.Poll()
  assert(mountain:GetAttribute('RemainingCells')+mountain:GetAttribute('DugCells')==67525,'mass changed')
  assert(world.GetAccount().CartCells==121 and world.GetAccount().Coins==api.coins,'collapse rewarded sand')
  return {pending=mountain:GetAttribute('PendingCollapses'),moved=mountain:GetAttribute('MovedCells'),elapsed=os.clock()-api.started}
 end
 function api.Finish()
  local state=api.Poll();assert(state.pending==0,'collapse still pending')
  api.connection:Disconnect();workspace:SetAttribute('__QA_CollapseActive',false)
  table.sort(api.frames);state.activeSeconds=(api.drainedAt or os.clock())-api.started;state.frames=#api.frames;state.p95=api.frames[math.ceil(#api.frames*.95)];state.max=api.frames[#api.frames]
  local samples={}
  for _,y in {0,5,10,20,30,36}do
   local p=origin+Vector3.new(0,y*4,0);local _,o=workspace.Terrain:ReadVoxels(Region3.new(p-Vector3.new(2,2,2),p+Vector3.new(2,2,2)),4)
   samples[#samples+1]={y=y,present=o[1][1][1]>.5}
  end
  assert(world.Close());local saved=assert(validate(world.GetCommitted()))
  assert(saved.dugCells==121 and #saved.pendingCollapses==0 and saved.account.CartCells==121)
  local restored=require(game.ReplicatedStorage.SandPrototypeVoxelField).Create(saved.voxelChunks)
  assert(restored.Count()==67404,'snapshot mass changed');for _,sample in samples do assert(restored.Has(0,sample.y,0)==sample.present,'Terrain differs from saved occupancy')end
  folder:Destroy();owner.Character:PivotTo(pose);root.Anchored=anchored;api.world=nil
  state.remaining=67404;state.dug=121;state.cargo=121;state.productionWrites=0;return state
 end
 return api
end
