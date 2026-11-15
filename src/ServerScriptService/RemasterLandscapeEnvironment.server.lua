local Landscape=require(game.ReplicatedStorage:WaitForChild('RemasterLandscape'))
local watched=setmetatable({}, {__mode='k'})
local function site(g)
 if watched[g]or not g.Name:match('^Site_')then return end;watched[g]=true
 task.spawn(function()
  while g.Parent do local p=g:FindFirstChild('OasisPolish');if g:GetAttribute('Ready')and p and p:GetAttribute('Ready')then break end;task.wait(.2)end
  if not g.Parent then return end
  local owner=tonumber(g.Name:match('^Site_(%d+)$'));local plots=workspace:FindFirstChild('SandPlots');local plot
  if plots then for _,v in plots:GetChildren()do if v:GetAttribute('OwnerUserId')==owner then plot=v;break end end end
  local spawn=plot and plot:FindFirstChild('SpawnLocation');if not spawn then return end
  local ok,err=pcall(Landscape.Site,g,spawn.Position-Vector3.new(3,.5,-2));if not ok then warn('Wayfinding: '..tostring(err))end
 end)
end
local function root(f)
 if f.Name~='QuarryGarden'or f:GetAttribute('QuarryGardenPreview')then return end
 for _,g in f:GetChildren()do site(g)end;f.ChildAdded:Connect(site)
end
for _,f in workspace:GetChildren()do root(f)end;workspace.ChildAdded:Connect(root)