-- Actual conveyor heartbeat, both formerly automatic levels; local-file Play.
return function()
 assert(game.GameId==0 and not game.ServerScriptService.SandPrototype.Enabled)
 local C=require(game.ReplicatedStorage.UpgradeConfig);local A=require(game.ServerScriptService.ProgressionAccount)
 local T=require(game.ServerScriptService.UpgradeTransactions);local owner=game.Players:GetPlayers()[1]
 local root=Instance.new('Folder');root.Name='__QA_ManualConveyor';root.Parent=workspace
 local active={};local calls=0;local reports={}
 local ok,result=xpcall(function()
  for _,level in {4,5}do
   local folder=Instance.new('Folder');folder.Parent=root
   local station=workspace.SandPrototypeStation:Clone();station:PivotTo(CFrame.new(5000,0,level*200));station.Parent=folder
   local a=A.New();a.ConveyorSections=4;a.ConveyorLevel=level
   local economy={GetMutable=function()return a end,Notify=function()end}
   local api=require(game.ServerScriptService.ConveyorService).Create({owner=owner,economy=economy,station=station,
    origin=Vector3.new(5000,2,level*200-50),height=6,cart={CanSell=function()return false end},canMutate=function()return true end,
    save=function()end,extract=function()calls+=1;return true end})
   active[#active+1]=api;reports[#reports+1]={level=level,account=a}
  end
  task.wait(3.5)
  for _,r in reports do assert(r.account.XP==0 and r.account.Coins==0 and r.account.ConveyorSand==0,'idle conveyor mined sand')end
  assert(calls==0,'conveyor still called terrain extraction')
  local a=reports[1].account;assert(T.AddSand(a,7));assert(T.LoadConveyor(a,100,2,false))
  assert(not T.Deliver(a,101));local before=a.Coins;assert(T.Deliver(a,102));assert(a.Coins-before==7*C.SellPrice)
  assert(not T.Deliver(a,103),'same cargo paid twice')
  return {levels={4,5},idleSeconds=3.5,extractionCalls=calls,sold=7,duplicatePayment=false,productionWrites=0}
 end,debug.traceback)
 for _,api in active do api.Destroy()end;root:Destroy();assert(ok,result);return result
end
