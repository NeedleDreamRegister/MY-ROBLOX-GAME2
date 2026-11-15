-- Model refinement only: no new planting sites and no terrain or gameplay writes.
local Refine={}
local V,CF=Vector3.new,CFrame.new
local assets=game.ReplicatedStorage:WaitForChild('VegetationRefinementAssets')
local function safePart(p)
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 p:SetAttribute('RefinedVegetationPart',true)
end
local function copyFit(template,cf,limit,name,parent)
 local _,bounds=template:GetBoundingBox()
 local factor=math.min(limit.X/bounds.X,limit.Y/bounds.Y,limit.Z/bounds.Z)
 local model=template:Clone();model.Name=name
 model:ScaleTo(template:GetScale()*factor);model:PivotTo(cf)
 for _,p in model:GetDescendants()do if p:IsA('BasePart')then safePart(p)end end
 model.Parent=parent;return model
end
function Refine.Tree(tree)
 if tree:GetAttribute('VegetationRefinementVersion')==1 then return false end
 local template=assets:FindFirstChild('ShadeTree');if not template then return false end
 local anchor=tree:GetPivot();local scale=tree:GetScale()
 tree:SetAttribute('VegetationOriginalPivot',anchor)
 for _,p in tree:GetDescendants()do if p:IsA('BasePart')then
  p:SetAttribute('VegetationOriginalTransparency',p.Transparency);p.Transparency=1;p.CastShadow=false
 end end
 local art=copyFit(template,anchor,V(13.4,15.5,10.8)*scale,'RefinedShadeTree',tree)
 -- Keep the original GardenCanopy identity tracked by the existing wind script.
 local canopy=tree:FindFirstChild('GardenCanopy')
 if canopy then
  local oldPivot=canopy:GetPivot()
  local crown=art:FindFirstChild('Crown')
  if crown then
   crown.Parent=canopy
   canopy:PivotTo(oldPivot)
  end
 end
 tree:SetAttribute('VegetationRefinementVersion',1)
 return true
end
function Refine.Shrub(p)
 if p:GetAttribute('VegetationRefinementVersion')==1 then return false end
 local template=assets:FindFirstChild('SageShrub');if not template then return false end
 local bottom=p.CFrame*CF(0,-p.Size.Y*.48,0)
 local art=copyFit(template,bottom,p.Size*V(.98,.98,.98),'RefinedSage',p)
 -- A subtle per-instance tint avoids identical saturated green repetitions.
 local variation=(math.sin(p.Position.X*.17+p.Position.Z*.11)+1)*.5
 for _,v in art:GetDescendants()do if v:IsA('MeshPart')then
  v.Color=Color3.fromRGB(240,242,224):Lerp(Color3.fromRGB(255,247,222),variation*.3)
  v.CastShadow=false
 end end
 p:SetAttribute('VegetationOriginalTransparency',p.Transparency);p.Transparency=1;p.CastShadow=false
 p:SetAttribute('VegetationRefinementVersion',1);return true
end
function Refine.Grass(p)
 if p:GetAttribute('VegetationRefinementVersion')==1 then return false end
 local oldSize=p.Size
 p:SetAttribute('VegetationOriginalSize',oldSize);p:SetAttribute('VegetationOriginalColor',p.Color)
 local dry=p.Name=='DryQuarryGrass'
 local variation=(math.sin(p.Position.X*.71+p.Position.Z*.23)+1)*.5
 p.Size=oldSize*V(.65,.76,.8)
 p.Color=dry and Color3.fromRGB(177,160,107):Lerp(Color3.fromRGB(205,188,137),variation)or Color3.fromRGB(112,143,86):Lerp(Color3.fromRGB(166,171,111),variation*.7)
 p.CastShadow=false
 if not dry and variation>.65 then
  local tip=Instance.new('WedgePart');tip.Name='TaperedGrassTip'
  tip.Size=oldSize*V(.4,.34,.36)
  tip.CFrame=p.CFrame*CF(0,oldSize.Y*.43,0)*CFrame.Angles(.12,0,.16*(variation-.5))
  tip.Color=p.Color:Lerp(Color3.fromRGB(196,190,129),.25);tip.Material=Enum.Material.SmoothPlastic
  safePart(tip);tip.CastShadow=false;tip.Parent=p
 end
 p:SetAttribute('VegetationRefinementVersion',1);return true
end
function Refine.Palm(model)
 if model:GetAttribute('VegetationRefinementVersion')==1 then return false end
 for _,p in model:GetDescendants()do if p:IsA('MeshPart')then
  p:SetAttribute('VegetationOriginalColor',p.Color)
  if p.Name=='fronds_geom'then p.Color=Color3.fromRGB(225,240,192)
  elseif p.Name=='trunk_geom'then p.Color=Color3.fromRGB(224,196,159)
  elseif p.Name=='dates_geom'then p.Color=Color3.fromRGB(184,153,117)end
  local surface=p:FindFirstChildOfClass('SurfaceAppearance')
  if surface then
   surface:SetAttribute('VegetationOriginalTint',surface.Color)
   surface.Color=p.Name=='fronds_geom'and Color3.fromRGB(218,238,183)or Color3.fromRGB(243,222,191)
  end
  safePart(p);p.CastShadow=true
 end end
 model:SetAttribute('VegetationRefinementVersion',1);return true
end
function Refine.Palms(root)
 local count=0
 for _,v in root:GetDescendants()do
  if v:IsA('Model')and(v.Name=='Palm'or v.Name=='Palm2'or v.Name=='DatePalm')then
   if Refine.Palm(v)then count+=1 end
  end
 end
 return count
end
function Refine.Site(garden)
 local stats={trees=0,shrubs=0,grass=0,flowers=0,agave=0}
 -- Snapshot original anchors before clones are attached; generated foliage cannot re-enter the pass.
 local items=garden:GetDescendants()
 for i,v in items do
  if v:IsA('Model')and v:GetAttribute('GardenTree')then
   if Refine.Tree(v)then stats.trees+=1 end
  elseif v:IsA('BasePart')then
   if v.Name=='GardenFoliage'or v.Name=='SageCushion'then
    if Refine.Shrub(v)then stats.shrubs+=1 end
   elseif v.Name=='GrassBlade'or v.Name=='DryQuarryGrass'then
    if Refine.Grass(v)then stats.grass+=1 end
   elseif v.Name=='AgaveLeaf'and not v:GetAttribute('VegetationRefinementVersion')then
    v:SetAttribute('VegetationOriginalColor',v.Color)
    v.Color=v.Color:Lerp(Color3.fromRGB(131,164,142),.55);v.CastShadow=false
    v:SetAttribute('VegetationRefinementVersion',1);stats.agave+=1
   elseif (v.Name=='FlowerLeaf'or v.Name=='FlowerStem'or v.Name=='WildflowerStem')and not v:GetAttribute('VegetationRefinementVersion')then
    v:SetAttribute('VegetationOriginalColor',v.Color)
    v.Color=Color3.fromRGB(101,134,87);v.CastShadow=false
    v:SetAttribute('VegetationRefinementVersion',1);stats.flowers+=1
   end
  end
  if i%75==0 then task.wait()end
 end
 garden:SetAttribute('VegetationRefinementVersion',1)
 return stats
end
return Refine