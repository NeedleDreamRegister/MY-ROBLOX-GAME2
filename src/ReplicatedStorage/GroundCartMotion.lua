-- Shared geometric step. Server owns the real cart; owner predicts only its render.
local Players=game:GetService('Players')
local Motion={}
function Motion.Create(model)
 local root=model.PrimaryPart
 local wheel=root.CFrame:ToObjectSpace(model.WheelTire.CFrame)
 local bowl=root.CFrame:ToObjectSpace(model.TrayBottom.CFrame)
 local scale=model:GetScale()
 local radius=.85*scale
 local box=model:GetAttribute('BodyBoxSize')*scale
 local api={}
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
  local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude params.RespectCanCollide=true
  local excluded={model,ch}for _,p in Players:GetPlayers()do if p.Character then table.insert(excluded,p.Character)end end
  params.FilterDescendantsInstances=excluded
  local rotation=CFrame.lookAt(Vector3.zero,look)*CFrame.Angles(math.rad(-4),0,0)
  local wheelOffset=rotation:VectorToWorldSpace(wheel.Position)
  local horizontal=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
  if horizontal.Magnitude>18*dt then horizontal=horizontal.Unit*18*dt end
  local position=root.Position+horizontal
  local hit=workspace:Raycast(position+wheelOffset+Vector3.new(0,8,0),Vector3.new(0,-30,0),params)
  if not hit or hit.Normal.Y<.82 then return nil,true end
  position=Vector3.new(position.X,hit.Position.Y+radius-wheelOffset.Y,position.Z)
  local delta=position-root.Position
  if math.abs(delta.Y)>2 then return nil,true end
  local destination=CFrame.new(position)*rotation
  local overlap=OverlapParams.new()overlap.FilterType=Enum.RaycastFilterType.Exclude overlap.FilterDescendantsInstances=excluded overlap.RespectCanCollide=true overlap.MaxParts=1
  local from=(root.CFrame*wheel).Position local to=(destination*wheel).Position local travel=to-from
  if (delta.Magnitude>.001 and workspace:Blockcast(root.CFrame*bowl+Vector3.new(0,.65*scale,0),box,delta,params))
   or (travel.Magnitude>.001 and workspace:Spherecast(from,radius*.9,travel,params))
   or #workspace:GetPartBoundsInRadius(to,radius*.9,overlap)>0
   or #workspace:GetPartBoundsInBox(destination*bowl+Vector3.new(0,.65*scale,0),box,overlap)>0 then return nil,true end
  return destination,false
 end
 return api
end
return Motion
