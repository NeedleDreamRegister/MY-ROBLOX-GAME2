-- Private cart-only Play. Main SandPrototype disabled; no DataStore IO.
return function()
 assert(not game.ServerScriptService.SandPrototype.Enabled)
 local p=assert(game.Players:GetPlayers()[1])local ch=p.Character or p.CharacterAdded:Wait()
 local root=ch:WaitForChild('HumanoidRootPart')
 assert(not p:FindFirstChild('SandPrototypeState'),'do not replace a live economy')
 local folder=Instance.new('Folder')folder.Name='ManualCartQA'folder.Parent=workspace
 local floor=Instance.new('Part')floor.Name='Ground'floor.Anchored=true floor.Size=Vector3.new(120,.5,120)floor.Position=Vector3.new(5000,-.25,0)floor.Parent=folder
 local station=Instance.new('Folder')station.Name='Station'station.Parent=folder
 local pad=Instance.new('Part')pad.Name='WheelbarrowPad'pad.Anchored=true pad.CanCollide=false pad.Transparency=1 pad.Position=Vector3.new(5000,.5,0)pad.Parent=station
 ch:PivotTo(CFrame.new(5000,3,0))
 local state=Instance.new('Folder')state.Name='SandPrototypeState'state.Parent=p
 local account=require(game.ServerScriptService.ProgressionAccount).New()
 account.CartLevel=1 account.CartEnabled=true account.Unlocks.cart=true
 local controller=require(game.ServerScriptService.FollowCart).Create({owner=p,station=station,canMutate=function()return true end})
 controller.Update(account)
 local api={folder=folder,account=account,controller=controller,player=p}
 function api.Cart()return folder.FollowWheelbarrow end
 function api.Load(n)
  assert(controller.CanLoad(),'cart not within loading reach')
  assert(require(game.ServerScriptService.UpgradeTransactions).AddSand(account,n))controller.Update(account)
 end
 function api.Level(n)
  account.CartLevel=n controller.Update(account)
 end
 function api.Snapshot()
  local cart=api.Cart()
  return {pushing=cart:GetAttribute('Pushing'),parked=cart:GetAttribute('ManualParked'),blocked=cart:GetAttribute('Blocked'),
   position=cart.PrimaryPart.Position,capacity=cart:GetAttribute('CartCapacity'),sand=account.CartCells,
   coins=account.Coins,xp=account.XP,speed=p.Character.Humanoid.WalkSpeed,canLoad=controller.CanLoad()}
 end
 function api.Destroy()controller.Destroy()folder:Destroy()state:Destroy()end
 return api
end
