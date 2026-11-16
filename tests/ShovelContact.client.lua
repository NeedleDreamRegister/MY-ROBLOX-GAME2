-- Local-file Play only. Start while holding a physical shovel, perform native
-- strokes against fresh sand, then call the returned function to check results.
return function(tool)
 assert(game.GameId==0 and game:GetService('RunService'):IsStudio())
 local player=game.Players.LocalPlayer
 assert(tool.Parent==player.Character and tool:FindFirstChild('CuttingEdge'))
 local strokes,frames={},{}
 local maxHandGap=0
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={player.Character}
 local axes={Vector3.xAxis,-Vector3.xAxis,Vector3.yAxis,-Vector3.yAxis,Vector3.zAxis,-Vector3.zAxis}
 local connection=game:GetService('RunService').RenderStepped:Connect(function(dt)
  if tool.Parent~=player.Character or(tool:GetAttribute('DigActiveUntil')or 0)<=os.clock()then return end
  local aim=tool:GetAttribute('DigAimPosition');if typeof(aim)~='Vector3'then return end
  local key=tostring(tool:GetAttribute('DigStrokeIndex'))
  local sample=strokes[key]
  if not sample then
   sample={closest=math.huge,surface=math.huge};strokes[key]=sample
   -- Independently verify that the proposed contact is on actual Terrain,
   -- before the delayed server action can remove it.
   for _,axis in axes do
    local hit=workspace:Raycast(aim+axis*.3,-axis*.6,params)
    if hit and hit.Instance==workspace.Terrain and hit.Material==Enum.Material.Sand then
     sample.surface=math.min(sample.surface,(hit.Position-aim).Magnitude)
    end
   end
  end
  sample.closest=math.min(sample.closest,(tool.CuttingEdge.Position-aim).Magnitude)
  local ch=player.Character
  for _,joint in ch.RightHand:GetChildren()do
   if joint.Name=='RightGrip'and joint.Part1==tool.Handle then
    maxHandGap=math.max(maxHandGap,((ch.RightHand.CFrame*joint.C0).Position-(tool.Handle.CFrame*joint.C1).Position).Magnitude)
   end
  end
  maxHandGap=math.max(maxHandGap,(ch.LeftHand.LeftGripAttachment.WorldPosition-tool.Handle.LeftGrip.WorldPosition).Magnitude)
  frames[#frames+1]=dt*1000
 end)
 return function()
  connection:Disconnect()
  local verified=0
  for _,sample in strokes do
   if sample.surface<.1 then
    verified+=1
    assert(sample.closest<.35,'blade missed verified sand contact: '..sample.closest)
   end
  end
  assert(verified>0,'no fresh Terrain contact was observed')
  assert(maxHandGap<.02,'hands lost the actual equipped grip')
  table.sort(frames)
  return {strokes=strokes,verified=verified,maxHandGap=maxHandGap,frames=#frames,
   frameP95=frames[math.ceil(#frames*.95)],frameMax=frames[#frames]}
 end
end
