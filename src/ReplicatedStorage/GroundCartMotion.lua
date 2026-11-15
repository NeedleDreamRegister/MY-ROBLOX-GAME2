-- Shared geometric step. Server owns the real cart; owner predicts only its render.
local Players=game:GetService('Players')
local Motion={}
function Motion.Create(model)
 local root=model.PrimaryPart
 local wheel=root.CFrame:ToObjectSpace(model.WheelTire.CFrame)
 local bowl=root.CFrame:ToObjectSpace(model.TrayBottom.CFrame)
 local scale=model:GetScale()
 local radius=.85*scale
 local collisionRadius=radius-.015*scale
 local box=model:GetAttribute('BodyBoxSize')*scale
 local contacts={wheel.Position-Vector3.new(0,radius,0)}
 for _,name in {'Foot-1','Foot1'}do
  local foot=model:FindFirstChild(name)
  if foot then table.insert(contacts,root.CFrame:PointToObjectSpace(foot.CFrame:PointToWorldSpace(Vector3.new(0,-foot.Size.Y/2,0))))end
 end
 local function queries(ch)
  local excluded={model}
  if ch then table.insert(excluded,ch)end
  for _,p in Players:GetPlayers()do if p.Character then table.insert(excluded,p.Character)end end
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.RespectCanCollide=true;ray.FilterDescendantsInstances=excluded
  local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude;overlap.FilterDescendantsInstances=excluded;overlap.RespectCanCollide=true;overlap.MaxParts=1
  return ray,overlap
 end
 local api={}
 function api.Park(ch)
  if #contacts~=3 then return nil end
  local params,overlap=queries(ch)
  local flat=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
  if flat.Magnitude<.1 then return nil end;flat=flat.Unit
  local rotation=CFrame.lookAt(Vector3.zero,flat)
  local wheelAnchor=(root.CFrame*wheel).Position
  local function pivot()
   local offset=rotation:VectorToWorldSpace(wheel.Position)
   return Vector3.new(wheelAnchor.X-offset.X,root.Position.Y,wheelAnchor.Z-offset.Z)
  end
  local function sample()
   local hits={}local height=-math.huge
   for _,contact in contacts do
    local offset=rotation:VectorToWorldSpace(contact)
    local hit=workspace:Raycast(pivot()+offset+Vector3.new(0,8,0),Vector3.new(0,-30,0),params)
    if not hit or hit.Normal.Y<.82 then return nil end
    table.insert(hits,hit.Position)
    height=math.max(height,hit.Position.Y-offset.Y)
   end
   return hits,height
  end
  -- Resample after tilting, since the three contact points move horizontally.
  for _=1,2 do
   local hits=sample();if not hits then return nil end
   local normal=(hits[2]-hits[1]):Cross(hits[3]-hits[1])
   if normal.Magnitude<.001 then return nil end
   normal=normal.Unit;if normal.Y<0 then normal=-normal end
   if normal.Y<.82 then return nil end
   local forward=flat-normal*flat:Dot(normal)
   rotation=CFrame.lookAt(Vector3.zero,forward.Unit,normal)
  end
  local hits,height=sample();if not hits or math.abs(height-root.Position.Y)>2 then return nil end
  -- Lower the handles around the wheel, rather than nudging it into a wall.
  local point=pivot()
  if (point-root.Position).Magnitude>2*scale then return nil end
  local destination=CFrame.new(point.X,height,point.Z)*rotation
  local wheelPosition=(destination*wheel).Position
  if #workspace:GetPartBoundsInRadius(wheelPosition,collisionRadius,overlap)>0
   or #workspace:GetPartBoundsInBox(destination*bowl+Vector3.new(0,.65*scale,0),box,overlap)>0 then return nil end
  return destination
 end
 function api.Step(ch,dt)
  local r=ch and ch:FindFirstChild('HumanoidRootPart')
  if not r then return nil,false end
  local look=Vector3.new(r.CFrame.LookVector.X,0,r.CFrame.LookVector.Z)
  if look.Magnitude<.1 then return end look=look.Unit
  local target=r.Position+look*1.5
  local current=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z).Unit
  local angle=math.atan2(current:Cross(look).Y,current:Dot(look))
  dt=math.min(dt,.1)
  look=CFrame.Angles(0,math.clamp(angle,-math.rad(120)*dt,math.rad(120)*dt),0):VectorToWorldSpace(current)
  local params,overlap=queries(ch)
  local rotation=CFrame.lookAt(Vector3.zero,look)*CFrame.Angles(math.rad(-4),0,0)
  local wheelOffset=rotation:VectorToWorldSpace(wheel.Position)
  local horizontal=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
  if horizontal.Magnitude>18*dt then horizontal=horizontal.Unit*18*dt end
  local position=root.Position+horizontal
  local hit=workspace:Raycast(position+wheelOffset+Vector3.new(0,8,0),Vector3.new(0,-30,0),params)
  if not hit or hit.Normal.Y<.82 then return nil,true end
  position=Vector3.new(position.X,hit.Position.Y+radius/hit.Normal.Y-wheelOffset.Y,position.Z)
  local delta=position-root.Position
  if math.abs(delta.Y)>2 then return nil,true end
  local destination=CFrame.new(position)*rotation
  local from=(root.CFrame*wheel).Position local to=(destination*wheel).Position local travel=to-from
  if (delta.Magnitude>.001 and workspace:Blockcast(root.CFrame*bowl+Vector3.new(0,.65*scale,0),box,delta,params))
   or (travel.Magnitude>.001 and workspace:Spherecast(from,collisionRadius,travel,params))
   or #workspace:GetPartBoundsInRadius(to,collisionRadius,overlap)>0
   or #workspace:GetPartBoundsInBox(destination*bowl+Vector3.new(0,.65*scale,0),box,overlap)>0 then return nil,true end
  return destination,false
 end
 return api
end
return Motion
