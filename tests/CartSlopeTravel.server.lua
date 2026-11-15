-- Drive both sizes in both directions on a real sloped Part.
return function(qa)
 assert(not qa.folder:FindFirstChild('Slope'),'fixture must start on flat ground')
 local ramp=Instance.new('Part');ramp.Name='Slope';ramp.Anchored=true;ramp.Size=Vector3.new(80,.5,80)
 ramp.CFrame=CFrame.new(5000,6,0)*CFrame.Angles(math.rad(12),0,math.rad(8));ramp.Parent=qa.folder
 local results={}
 for _,scale in {1,1.25}do for _,direction in {-1,1}do
  qa.Build(scale)
  local cart
  for _,o in qa.folder:GetChildren()do if o:IsA('Model')and o:FindFirstChild('WheelTire')then cart=o end end
  local cf=CFrame.lookAt(Vector3.new(5000,9.3,0),Vector3.new(5000,9.3,direction))
  qa.npc:PivotTo(cf);cart:PivotTo(CFrame.new(5000,9.3,direction*1.5)*cf.Rotation)
  qa.Start();task.wait(.25)
  local before=cart.PrimaryPart.Position
  qa.Move(Vector3.new(5000,direction<0 and 12 or 7,direction*12));task.wait(1)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={cart,qa.npc};params.RespectCanCollide=true
  local gaps={}
  for _,name in {'Foot-1','Foot1'}do
   local foot=cart[name]
   local point=foot.CFrame:PointToWorldSpace(Vector3.new(0,-foot.Size.Y/2,0))
   local hit=assert(workspace:Raycast(point+Vector3.new(0,3,0),Vector3.new(0,-10,0),params))
   gaps[name]=point.Y-hit.Position.Y
   assert(gaps[name]>=-.02,'support leg clips slope: '..gaps[name])
  end
  local travel=(cart.PrimaryPart.Position-before).Magnitude
  assert(travel>7 and qa.Snapshot().pushing and not qa.Snapshot().blocked)
  table.insert(results,{scale=scale,direction=direction,travel=travel,gaps=gaps})
  qa.Release()
 end end
 ramp:Destroy()
 return results
end
