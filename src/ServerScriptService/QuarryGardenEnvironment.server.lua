-- Visual decoration only. No economy, remotes, inventory or saved data are changed.
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local Garden=require(ReplicatedStorage:WaitForChild('QuarryGardenBuilder'))
local Geometry=require(ReplicatedStorage:WaitForChild('SandPrototypeGeometry'))
local preview=workspace:FindFirstChild('QuarryGarden')
if preview and preview:GetAttribute('QuarryGardenPreview')then preview:Destroy()end
local root=Instance.new('Folder');root.Name='QuarryGarden';root:SetAttribute('VisualOnly',true);root.Parent=workspace
local sites={}
local function watch(plot)
 if not plot:IsA('Model')or sites[plot]then return end
 local token={};sites[plot]=token
 task.spawn(function()
  local mountain=plot:WaitForChild('SandPrototype',15);local spawn=plot:WaitForChild('SpawnLocation',15)
  if not mountain or not spawn then sites[plot]=nil;return end
  for _=1,150 do
   if not plot.Parent then sites[plot]=nil;return end
   local initial=mountain:GetAttribute('InitialCells')
   if type(initial)=='number'and initial>455 and typeof(mountain:GetAttribute('TerrainOrigin'))=='Vector3'then break end
   task.wait(.1)
  end
  if not plot.Parent then sites[plot]=nil;return end
  local offset=spawn.Position-Vector3.new(3,.5,-2)
  local initial=mountain:GetAttribute('InitialCells')or 67525
  local h=initial>455 and Geometry.Height(initial)or 36;local origin=mountain:GetAttribute('TerrainOrigin')or(offset+Vector3.new(-34,2,-214))
  local localOrigin=origin-offset;local r=(h+4)*4+6
  local ok,model=pcall(Garden.Build,root,offset,{Protected={localOrigin.X-r,localOrigin.X+r,localOrigin.Z-r,localOrigin.Z+r},OnRoot=function(m)token.model=m;m.Name='Site_'..tostring(plot:GetAttribute('OwnerUserId')or plot.Name)end,OnChunk=function()if not plot.Parent then error('Garden build cancelled',0)end end})
  if not ok then if token.model then token.model:Destroy()end;sites[plot]=nil;if plot.Parent then warn('Garden decoration: '..tostring(model))end;return end
  if not plot.Parent then model:Destroy();sites[plot]=nil;return end
  model.Name='Site_'..tostring(plot:GetAttribute('OwnerUserId')or plot.Name);token.model=model
 end)
end
local function folder(v)
 if v.Name~='SandPlots'then return end
 for _,p in v:GetChildren()do watch(p)end
 v.ChildAdded:Connect(watch)
 v.ChildRemoved:Connect(function(p)local e=sites[p];if e then if e.model then e.model:Destroy()end;sites[p]=nil end end)
end
for _,v in workspace:GetChildren()do folder(v)end
workspace.ChildAdded:Connect(folder)
