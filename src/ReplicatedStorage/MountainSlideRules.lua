local R={}
local Geometry=require(script.Parent.SandPrototypeGeometry)
function R.Sample(player,root,minHeight)
 local ch=player.Character;if not ch then return end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={ch};params.RespectCanCollide=true
 local hit=workspace:Raycast(root.Position+Vector3.new(0,1,0),Vector3.new(0,-13,0),params)
 if not hit or hit.Instance~=workspace.Terrain or hit.Material~=Enum.Material.Sand or hit.Normal.Y<.2 then return end
 local plots=workspace:FindFirstChild('SandPlots');if not plots then return end
 for _,plot in plots:GetChildren()do
  local m=plot:FindFirstChild('SandPrototype');local origin=m and m:GetAttribute('TerrainOrigin')
  if typeof(origin)=='Vector3' then
   local height=Geometry.Height(m:GetAttribute('InitialCells')or 0)
   if height and math.abs(hit.Position.X-origin.X)<=height*4+5 and math.abs(hit.Position.Z-origin.Z)<=height*4+5 and hit.Position.Y>=origin.Y+(minHeight or 0) then
    local owner=m:GetAttribute('OwnerUserId');local permissions=player:FindFirstChild('SandPrototypePermissions');local allowed=permissions and permissions:FindFirstChild(tostring(owner));local status=m:GetAttribute('PersistenceStatus')
    if owner~=player.UserId and not(allowed and allowed.Value)then return end
    if status~='SessionOnly'and status~='Saved'and status~='Dirty'and status~='Saving'then return end
    local down=Vector3.new(hit.Normal.X,0,hit.Normal.Z)
    if hit.Normal.Y>.98 or down.Magnitude<.1 then down=Vector3.new(root.Position.X-origin.X,0,root.Position.Z-origin.Z)end
    if down.Magnitude<.1 then down=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)end
    if down.Magnitude<.1 then down=Vector3.new(0,0,1)end
    return {Mountain=m,Origin=origin,Hit=hit,Direction=down.Unit}
   end
  end
 end
end
return R
