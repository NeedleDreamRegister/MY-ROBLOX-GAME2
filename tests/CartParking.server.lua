-- Use with the private ManualCartNPC fixture on its flat Ground.
return function(qa)
 local results={}
 for _,scale in {1,1.25}do
  qa.Build(scale)qa.Start()task.wait(.25)
  local model
  for _,o in qa.folder:GetChildren()do if o:IsA('Model')and o:FindFirstChild('WheelTire')then model=o end end
  local wheelBefore=model.WheelTire.Position
  qa.Release()
  local wheelAfter=model.WheelTire.Position
  assert(Vector3.new(wheelAfter.X-wheelBefore.X,0,wheelAfter.Z-wheelBefore.Z).Magnitude<.001,'parking slid the wheel')
  local gaps={}
  for _,name in {'Foot-1','Foot1'}do
   local p=model[name]
   local half=(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2
   local gap=p.Position.Y-half
   gaps[name]=gap
   assert(gap>=-.005 and gap<.03,'parked foot floats: '..tostring(gap))
  end
  assert(qa.Snapshot().parked and qa.Snapshot().speed==16)
  table.insert(results,{scale=scale,gaps=gaps})
 end
 return results
end
