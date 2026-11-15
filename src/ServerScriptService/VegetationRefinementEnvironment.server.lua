-- Refine each generated site's existing plants after all layout work completes.
local Refine=require(game.ReplicatedStorage:WaitForChild('VegetationRefinement'))
local watched=setmetatable({}, {__mode='k'})
local function site(garden)
 if watched[garden]or not garden.Name:match('^Site_')then return end
 watched[garden]=true
 task.spawn(function()
  while garden.Parent do
   local front=garden:FindFirstChild('FrontGardenLink')
   local polish=garden:FindFirstChild('OasisPolish')
   if garden:GetAttribute('Ready')and front and front:GetAttribute('TransitReady')and polish and polish:GetAttribute('Ready')then break end
   task.wait(.2)
  end
  if not garden.Parent then return end
  local ok,err=pcall(Refine.Site,garden)
  if not ok then warn('Vegetation refinement: '..tostring(err))end
 end)
end
local function root(folder)
 if folder.Name~='QuarryGarden'or folder:GetAttribute('QuarryGardenPreview')then return end
 for _,g in folder:GetChildren()do site(g)end
 folder.ChildAdded:Connect(site)
end
Refine.Palms(workspace)
for _,f in workspace:GetChildren()do root(f)end
workspace.ChildAdded:Connect(root)