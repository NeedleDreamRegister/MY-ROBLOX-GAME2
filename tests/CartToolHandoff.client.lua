-- Observe actual Q/prompt -> push -> park. Touch may be supplied by a disposable
-- forced-touch controller; that is a branch test, not device/touch-input coverage.
return function(expectTouchReturn)
 assert(game.GameId==0)
 local p=game.Players.LocalPlayer;local state=p.SandPrototypeState
 local sawPush=false;local pushAt;local toolDuringPush=false
 local connection=game:GetService('RunService').RenderStepped:Connect(function()
  if state:GetAttribute('PushingCart')then
   if not pushAt then pushAt=os.clock()end
   sawPush=true
   if os.clock()-pushAt>.2 and p.Character:FindFirstChildOfClass('Tool')then toolDuringPush=true end
  else pushAt=nil end
 end)
 return function()
  connection:Disconnect()
  assert(sawPush,'no actual cart interaction observed')
  assert(not state:GetAttribute('PushingCart'),'cart still held')
  assert(not toolDuringPush,'tool returned while hands held the cart')
  local tool=p.Character:FindFirstChildOfClass('Tool')
  local buttons=0
  for _,g in p.PlayerGui:GetChildren()do if g.Name=='DTM_MobileDig'and g.Enabled then buttons+=1 end end
  if expectTouchReturn then
   assert(tool and tool:GetAttribute('UpgradeToolId')==state:GetAttribute('SelectedTool'),'selected tool did not return')
   assert(buttons==1,'dig button did not return exactly once')
  else assert(not tool and buttons==0,'desktop unexpectedly auto-equipped a tool')end
  assert(p.Character.Humanoid.WalkSpeed==16,'cart speed not restored')
  return {touchBranch=expectTouchReturn,toolReturned=tool~=nil,digButtons=buttons,toolDuringPush=toolDuringPush,speed=16}
 end
end
