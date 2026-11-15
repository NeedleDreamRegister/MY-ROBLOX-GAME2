-- Private ManualCartNPC fixture only. No Terrain, economy or DataStore writes.
return function(qa)
 local function cart()
  for _,o in qa.folder:GetChildren()do if o:IsA('Model')and o:FindFirstChild('WheelTire')then return o end end
  error('missing fixture cart')
 end
 local function stationaryWheel(before,after)
  assert(Vector3.new(after.X-before.X,0,after.Z-before.Z).Magnitude<.001,'wheel slid during parking')
 end
 local result={slope={},wall={}}
 local ramp=Instance.new('Part')
 ramp.Name='Slope';ramp.Anchored=true;ramp.Size=Vector3.new(80,.5,80)
 ramp.CFrame=CFrame.new(5000,6,0)*CFrame.Angles(math.rad(12),0,math.rad(8));ramp.Parent=qa.folder
 for _,scale in {1,1.25}do
  qa.Build(scale)
  qa.npc:PivotTo(CFrame.new(5000,10,0));cart():PivotTo(CFrame.new(5000,10,-1.5))
  qa.Start();task.wait(.4)
  assert(not qa.Snapshot().blocked,'supported slope blocked movement')
  local before=cart().WheelTire.Position;qa.Release()
  stationaryWheel(before,cart().WheelTire.Position)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={cart(),qa.npc};params.RespectCanCollide=true
  local gaps={}
  for _,name in {'Foot-1','Foot1'}do
   local foot=cart()[name]
   local point=foot.CFrame:PointToWorldSpace(Vector3.new(0,-foot.Size.Y/2,0))
   local hit=assert(workspace:Raycast(point+Vector3.new(0,3,0),Vector3.new(0,-6,0),params))
   gaps[name]=point.Y-hit.Position.Y
   assert(gaps[name]>-.01 and gaps[name]<.04,'foot misses slope')
  end
  assert(cart().PrimaryPart.CFrame.UpVector:Dot(ramp.CFrame.UpVector)>.999)
  table.insert(result.slope,{scale=scale,gaps=gaps})
 end
 ramp:Destroy()
 for _,scale in {1,1.25}do
  qa.Build(scale);qa.Start();task.wait(.25)
  local wall=qa.Wall(-12)
  qa.Move(Vector3.new(5000,3,-18));task.wait(1.8)
  assert(qa.Snapshot().blocked,'wall did not stop movement')
  local before=cart().WheelTire.Position
  local clearance=before.Z-.85*scale-(wall.Position.Z+.5)
  assert(clearance>=-.02*scale,'wheel overlaps wall')
  qa.Release();stationaryWheel(before,cart().WheelTire.Position)
  assert(qa.Snapshot().parked and qa.Snapshot().speed==16)
  table.insert(result.wall,{scale=scale,clearance=clearance})
  wall:Destroy()
 end
 qa.Build(1)
 cart():PivotTo(CFrame.new(20000,3,0));qa.npc:PivotTo(CFrame.new(20000,3,1.5))
 local floor=Instance.new('Part');floor.Anchored=true;floor.Size=Vector3.new(40,.5,40)
 floor.Position=Vector3.new(20000,-10.25,0);floor.Parent=qa.folder
 local motion=require(game.ReplicatedStorage.GroundCartMotion).Create(cart())
 assert(motion.Park(qa.npc)==nil,'parking teleported down a drop')
 local pose,blocked=motion.Step(qa.npc,1/30);assert(not pose and blocked)
 floor:Destroy()
 assert(motion.Park(qa.npc)==nil,'parking ignored missing ground')
 local pose2,blocked2=motion.Step(qa.npc,1/30);assert(not pose2 and blocked2)
 result.deepDropRejected=true;result.unsupportedRejected=true
 return result
end
