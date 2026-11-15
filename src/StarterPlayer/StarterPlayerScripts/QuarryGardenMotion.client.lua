-- Client-only scenery motion. Original objects, physics and gameplay state are untouched.
local Run=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local trees,ripples,activeTrees={},{},{}
local refresh,elapsed=0,0
local function owned(v)
 local root=workspace:FindFirstChild('QuarryGarden')
 return root and v:IsDescendantOf(root)
end
local function track(v)
 if not owned(v)then return end
 if v:IsA('Model')and v:GetAttribute('GardenTree')and not trees[v]then
  local canopy=v:FindFirstChild('GardenCanopy')
  if canopy then local pos=v:GetPivot().Position;trees[v]={model=canopy,base=canopy:GetPivot(),position=pos,phase=pos.X*.017+pos.Z*.011}end
 elseif v:IsA('BasePart')and v.Name=='GardenWaterRipple'then
  ripples[v]={base=v.CFrame,phase=v:GetAttribute('RipplePhase')or 0}
 end
end
workspace.DescendantAdded:Connect(track)
local root=workspace:FindFirstChild('QuarryGarden')
if root then for _,v in root:GetDescendants()do track(v)end end
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;refresh+=dt
 if elapsed<.1 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local cameraPos=camera.CFrame.Position
 if refresh>=.5 then
  refresh=0;local candidates={}
  for tree,e in trees do
   if not tree.Parent or not e.model.Parent then trees[tree]=nil
   else
    local distance=(e.position-cameraPos).Magnitude
    if distance<130 then table.insert(candidates,{entry=e,distance=distance})end
   end
  end
  table.sort(candidates,function(a,b)return a.distance<b.distance end)
  local selected={};local nextActive={}
  for i=1,math.min(#candidates,Input.TouchEnabled and 8 or 12)do local e=candidates[i].entry;selected[e]=true;table.insert(nextActive,e)end
  for _,e in activeTrees do if not selected[e]and e.model.Parent then e.model:PivotTo(e.base)end end
  activeTrees=nextActive
 end
 local t=os.clock()
 for _,e in activeTrees do if e.model.Parent then
  local x=math.sin(t*.73+e.phase)*.012
  local z=math.sin(t*.59+e.phase*1.2)*.018
  e.model:PivotTo(e.base*CFrame.Angles(x,0,z))
 end end
 for part,e in ripples do
  if not part.Parent then ripples[part]=nil
  elseif(part.Position-cameraPos).Magnitude<90 then
   local age=(t*.16+e.phase)%1;local size=.6+age*2.6
   part.Size=Vector3.new(.025,size,size);part.Transparency=.58+age*.41
  else part.Transparency=1 end
 end
end)