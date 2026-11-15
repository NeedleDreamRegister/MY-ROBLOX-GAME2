-- Apply decorative accents after the existing garden and transit roads finish.
local Oasis=require(game.ReplicatedStorage:WaitForChild('OasisPolish'))
local watched=setmetatable({}, {__mode='k'})
local function site(garden)
 if watched[garden]or not garden.Name:match('^Site_')then return end
 watched[garden]=true
 task.spawn(function()
  while garden.Parent do
   local front=garden:FindFirstChild('FrontGardenLink')
   if garden:GetAttribute('Ready')and front and front:GetAttribute('TransitReady')then break end
   task.wait(.2)
  end
  if not garden.Parent then return end
  local owner=tonumber(garden.Name:match('^Site_(%d+)$'))
  local plots=workspace:FindFirstChild('SandPlots');local plot
  if plots then for _,p in plots:GetChildren()do if p:GetAttribute('OwnerUserId')==owner then plot=p;break end end end
  local spawn=plot and plot:FindFirstChild('SpawnLocation');if not spawn then return end
  local ok,err=pcall(Oasis.Build,garden,spawn.Position-Vector3.new(3,.5,-2))
  if not ok then warn('Oasis decoration: '..tostring(err))end
 end)
end
local function root(folder)
 if folder.Name~='QuarryGarden'or folder:GetAttribute('QuarryGardenPreview')then return end
 for _,g in folder:GetChildren()do site(g)end
 folder.ChildAdded:Connect(site)
end
for _,f in workspace:GetChildren()do root(f)end
workspace.ChildAdded:Connect(root)