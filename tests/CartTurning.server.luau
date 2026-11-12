-- Private Play fixture. Disable SandPrototype before starting; no DataStore IO.
-- Start this on Server, focus the cart on Client and hold Q. Call Corner(),
-- rotate the client's character toward +X, then AssertBlocked().
return function()
 assert(not workspace:FindFirstChild("SandPlots"),"disable the main game before private cart QA")
 local player=assert(game.Players:GetPlayers()[1])
 assert(not player:FindFirstChild("SandPrototypeState"),"existing economy must not be replaced")
 local folder=Instance.new("Model")folder.Name="CartTurnQA"folder.Parent=workspace
 local ground=Instance.new("Part")ground.Name="Ground"ground.Anchored=true
 ground.Size=Vector3.new(100,0.5,100)ground.Position=Vector3.new(1020,-0.25,0)ground.Parent=folder
 local station=Instance.new("Folder")station.Name="Station"station.Parent=folder
 local state=Instance.new("Folder")state.Name="SandPrototypeState"
 for k,v in {BarrowOwned=1,CarriedCells=20,CartCells=20,CapacityCells=100,CapacityLevel=0,Coins=0,XP=0}do state:SetAttribute(k,v)end
 state.Parent=player
 local controller=require(game.ServerScriptService.SandPrototypeWheelbarrow).Create({
  owner=player,station=station,bounds=CFrame.new(1000,2,0),size=Vector3.new(20,4,20),canMutate=function()return true end})
 controller.Update({BarrowOwned=1,CartCells=20})
 local cart=folder.Wheelbarrow local root=cart.GripRoot
 player.Character:PivotTo(CFrame.new(root.Position-root.CFrame.LookVector*1.5+Vector3.new(0,1,0),root.Position+Vector3.new(0,1,0)))
 local api={folder=folder,cart=cart,player=player}
 function api.Corner()
  assert(cart:GetAttribute("Pushing"),"hold Q at the cart first")
  local characterRoot=player.Character.HumanoidRootPart
  local wall=Instance.new("Part")wall.Name="WheelCornerWall"wall.Anchored=true
  wall.Size=Vector3.new(0.2,2.2,2)
  wall.Position=Vector3.new(characterRoot.Position.X+6.4,1.1,characterRoot.Position.Z)wall.Parent=folder
 end
 function api.AssertBlocked()
  local wheel=(root.CFrame*cart:GetAttribute("WheelAnchor")).Position
  local overlap=OverlapParams.new()overlap.FilterType=Enum.RaycastFilterType.Include
  overlap.FilterDescendantsInstances={folder.WheelCornerWall}
  assert(cart:GetAttribute("Pushing"),"unexpected release")
  assert(cart:GetAttribute("Blocked"),"rotation did not stop at the wall")
  assert(#workspace:GetPartBoundsInRadius(wheel,0.765,overlap)==0,"wheel entered the wall during rotation")
  assert(state:GetAttribute("CarriedCells")==20 and state:GetAttribute("Coins")==0,"movement changed resources")
  return {blocked=true,wheelOutsideWall=true,resourcesUnchanged=true}
 end
 function api.Destroy()
  controller.Destroy()folder:Destroy()state:Destroy()
 end
 return api
end
