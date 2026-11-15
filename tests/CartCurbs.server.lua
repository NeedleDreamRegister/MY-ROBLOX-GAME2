-- ManualCartNPC fixture; checks small-curb rolling without weakening walls.
return function(qa)
 local function cart()
  for _,m in qa.folder:GetChildren()do if m:IsA('Model')and m:FindFirstChild('WheelTire')then return m end end
  error('missing cart')
 end
 local result={crossings={},blocked={}}
 for _,height in {.2,.3}do
  local curb=Instance.new('Part');curb.Name='Curb';curb.Anchored=true
  curb.Size=Vector3.new(40,height,60);curb.Position=Vector3.new(5000,height/2,-40);curb.Parent=qa.folder
  for _,scale in {1,1.25}do for _,direction in {-1,1}do
   qa.Build(scale)
   local z=direction==-1 and 0 or -18
   local rotation=CFrame.lookAt(Vector3.zero,Vector3.new(0,0,direction))
   qa.npc:PivotTo(CFrame.new(5000,3+(direction==1 and height or 0),z)*rotation)
   cart():PivotTo(CFrame.new(5000,3*scale+(direction==1 and height or 0),z+direction*1.5)*rotation)
   qa.Start();task.wait(.2)
   local start=cart().PrimaryPart.Position
   qa.Move(Vector3.new(5000,3,direction==-1 and -18 or 0));task.wait(1.6)
   local state=qa.Snapshot()
   local crossed=direction==-1 and state.position.Z< -12 or direction==1 and state.position.Z> -6
   assert(crossed and state.pushing and not state.blocked,'small curb blocked the cart')
   table.insert(result.crossings,{height=height,scale=scale,direction=direction,travel=(state.position-start).Magnitude})
   qa.Release()
  end end
  curb:Destroy()
 end
 for _,scale in {1,1.25}do
  qa.Build(scale)
  local high=Instance.new('Part');high.Name='HighCurb';high.Anchored=true
  high.Size=Vector3.new(40,1,60);high.Position=Vector3.new(5000,.5,-40);high.Parent=qa.folder
  qa.Start();task.wait(.2);qa.Move(Vector3.new(5000,3,-18));task.wait(.9)
  local state=qa.Snapshot();assert(state.pushing and state.blocked and state.position.Z> -10,'large step bypassed')
  table.insert(result.blocked,{scale=scale,height=1,position=tostring(state.position)})
  qa.Release();high:Destroy()
 end
 return result
end
