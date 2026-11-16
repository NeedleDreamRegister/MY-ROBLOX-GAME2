-- Reproduce a stale native RightGrip preceding the current equipped joint.
-- A name-only lookup selected this empty weld and corrupted the shovel pose.
return function()
 assert(game.GameId==0 and game:GetService('RunService'):IsStudio())
 local player=game.Players.LocalPlayer;local ch=player.Character
 local tool=assert(ch:FindFirstChildOfClass('Tool'));local hand=ch.RightHand
 local active
 for _,joint in hand:GetChildren()do if joint.Name=='RightGrip'and joint.Part1==tool.Handle then active=joint end end
 assert(active,'equipped grip missing')
 active.Parent=nil
 local orphan=Instance.new('Weld');orphan.Name='RightGrip';orphan.Part0=hand
 orphan.C1=CFrame.new(0,4,0)*CFrame.Angles(1,1,1);orphan.Parent=hand
 active.Parent=hand
 local ok,result=xpcall(function()
  task.wait(.2)
  local right=((hand.CFrame*active.C0).Position-(tool.Handle.CFrame*active.C1).Position).Magnitude
  local left=(ch.LeftHand.LeftGripAttachment.WorldPosition-tool.Handle.LeftGrip.WorldPosition).Magnitude
  assert(math.max(right,left)<.02,'stale weld corrupted the equipped pose')
  return {right=right,left=left,ignoredOrphan=true}
 end,debug.traceback)
 orphan:Destroy()
 assert(ok,result)
 return result
end
