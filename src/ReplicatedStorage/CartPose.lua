local Pose={Offset=Vector3.new(3.7,0,4.2)}
function Pose.Get(root,humanoid,cart,character)
 local flat=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
 if flat.Magnitude<.01 then flat=Vector3.new(0,0,-1)end
 local yaw=CFrame.lookAt(root.Position,root.Position+flat.Unit)
 local point=yaw:PointToWorldSpace(Pose.Offset)
 local feet=root.Position.Y-root.Size.Y/2-humanoid.HipHeight
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
 local excluded={cart,character};for _,p in game.Players:GetPlayers()do if p.Character and p.Character~=character then table.insert(excluded,p.Character)end end
 params.FilterDescendantsInstances=excluded
 local hit=workspace:Raycast(Vector3.new(point.X,feet+3,point.Z),Vector3.new(0,-45,0),params)
 local ground=feet
 if hit and hit.Normal.Y>.55 and hit.Position.Y<=feet+2.2 then ground=hit.Position.Y end
 local scale=cart:GetScale();local y=ground+(cart:GetAttribute('GripHeight')or 2.65)*scale
 local position=Vector3.new(point.X,y,point.Z)
 return CFrame.lookAt(position,position+flat.Unit)
end
return Pose

