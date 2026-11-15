-- Attach to each garden only after its existing, unmodified builder finishes.
local Transit=script.Parent
local Route=require(Transit.Route)
local upgrade=require(Transit.BuildRoads)
local startCart=require(Transit.TransitController)
local template=Transit.CartTemplate
local carts=Instance.new('Folder') carts.Name='QuarryTransitVehicles' carts.Parent=workspace
local preview=workspace:FindFirstChild('QuarryParkCart')
if preview and preview:GetAttribute('TransitPreview') then preview:Destroy() end
local watched,active={},{ }
local function watchSite(garden)
 if watched[garden] or not string.match(garden.Name,'^Site_') then return end
 watched[garden]=true
 task.spawn(function()
  while garden.Parent and not garden:GetAttribute('Ready') do task.wait(.1) end
  if not garden.Parent then return end
  local owner=tonumber(string.match(garden.Name,'^Site_(%d+)$'))
  local plots=workspace:WaitForChild('SandPlots')
  local plot
  for _,candidate in plots:GetChildren() do if candidate:GetAttribute('OwnerUserId')==owner then plot=candidate break end end
  if not plot then return end
  local spawn=plot:WaitForChild('SpawnLocation',15)
  if not spawn or not garden.Parent then return end
  local offset=spawn.Position-Vector3.new(3,.5,-2)
  local ok,result=pcall(upgrade,garden,offset,false)
  if not ok then warn('QuarryTransit road build: '..tostring(result)) return end
  if not garden.Parent then return end
  local cart=template:Clone()
  cart.Name='QuarryParkCart_'..tostring(owner)
  cart:SetAttribute('TransitPreview',false)
  cart:SetAttribute('SiteOwnerUserId',owner)
  cart:PivotTo(Route.WithOffset(offset).Frame(0))
  cart.PrimaryPart.RoutePosition.Position=Route.WithOffset(offset).Frame(0).Position
  cart.PrimaryPart.RouteOrientation.CFrame=Route.WithOffset(offset).Frame(0).Rotation
  cart.Parent=carts
  local cleanup=startCart(cart,garden,offset)
  active[garden]={Cart=cart,Cleanup=cleanup}
  garden.AncestryChanged:Connect(function()
   if not garden:IsDescendantOf(workspace) and active[garden] then
    active[garden]=nil cleanup() task.delay(.2,function()cart:Destroy()end)
   end
  end)
 end)
end
local function watchRoot(root)
 if root.Name~='QuarryGarden' or root:GetAttribute('QuarryGardenPreview') then return end
 for _,garden in root:GetChildren() do watchSite(garden) end
 root.ChildAdded:Connect(watchSite)
end
for _,root in workspace:GetChildren() do watchRoot(root) end
workspace.ChildAdded:Connect(watchRoot)

