-- Isolated server physics fixture. Never runs automatically or accesses DataStore.
return function(updateInterval)
 assert(not game.ServerScriptService.SandPrototype.Enabled)
 local player=assert(game.Players:GetPlayers()[1])
 local character=player.Character or player.CharacterAdded:Wait()
 local original=character.Archivable character.Archivable=true
 local npc=character:Clone() character.Archivable=original
 for _,o in npc:GetDescendants()do if o:IsA('LuaSourceContainer')or o:IsA('Tool')then o:Destroy()end end
 local folder=Instance.new('Folder')folder.Name='ManualCartNPCQA'folder.Parent=workspace
 local floor=Instance.new('Part')floor.Anchored=true floor.Size=Vector3.new(120,.5,120)floor.Position=Vector3.new(5000,-.25,0)floor.Parent=folder
 npc.Name='Driver'npc.Parent=folder npc:PivotTo(CFrame.new(5000,3,0))
 local humanoid=npc:FindFirstChildOfClass('Humanoid')
 npc.HumanoidRootPart:SetNetworkOwner(nil)
 local state=Instance.new('Folder')state.Name='SandPrototypeState'
 local owner={Character=npc,UserId=9002}
 function owner:FindFirstChild(name)if name==state.Name then return state end end
 local api={npc=npc,owner=owner,state=state,folder=folder}
 local model,manual,connection
 function api.Build(scale)
  if connection then connection:Disconnect()end if manual then manual.Destroy()end if model then model:Destroy()end
  npc:PivotTo(CFrame.new(5000,3,0))humanoid:Move(Vector3.zero)
  model=require(game.ReplicatedStorage.SandPrototypeCartAppearance).Build()
  model:ScaleTo(scale)
  for _,p in model:GetDescendants()do if p:IsA('BasePart')then p.Anchored=true p.CanCollide=false p.CanQuery=false end end
  model:PivotTo(CFrame.new(5000,3,-1.5))model.Parent=folder
  manual=require(game.ServerScriptService.ManualCart).Create(owner,model,function()return true end)
  local elapsed=0
  connection=game:GetService('RunService').Heartbeat:Connect(function(dt)
   elapsed+=dt;if elapsed<(updateInterval or 0)then return end
   local step=elapsed;elapsed=0;manual.Update(step,true)
  end)
 end
 function api.Start()manual.Toggle(owner)assert(model:GetAttribute('Pushing'))end
 function api.Snapshot()return {position=model.PrimaryPart.Position,actor=npc.HumanoidRootPart.Position,pushing=model:GetAttribute('Pushing'),blocked=model:GetAttribute('Blocked'),parked=model:GetAttribute('ManualParked'),speed=humanoid.WalkSpeed,ik=#humanoid:GetChildren()}end
 function api.Move(position)humanoid:MoveTo(position)end
 function api.Release()manual.Toggle(owner)end
 function api.Foreign()manual.Toggle({})return model:GetAttribute('Pushing')end
 function api.Wall(z)local p=Instance.new('Part')p.Name='Wall'p.Anchored=true p.Size=Vector3.new(20,8,1)p.Position=Vector3.new(5000,4,z)p.Parent=folder return p end
 function api.Destroy()if connection then connection:Disconnect()end if manual then manual.Destroy()end folder:Destroy()state:Destroy()end
 api.Build(1)
 return api
end
