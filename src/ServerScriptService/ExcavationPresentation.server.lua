local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Builder=require(game.ReplicatedStorage:WaitForChild('ExcavationLedgerAppearance'))
local entries={}
local function watch(plot)
 if not plot:IsA('Model')or not plot:GetAttribute('OwnerUserId')or entries[plot]then return end
 task.defer(function()
  local mountain=plot:WaitForChild('SandPrototype',10);local station=plot:WaitForChild('SandPrototypeStation',10);local spawn=plot:WaitForChild('SpawnLocation',10)
  if not mountain or not station or not spawn or not plot.Parent then return end
  local offset=spawn.Position-Vector3.new(3,.5,-2)
  local ledger=station:FindFirstChild('ExcavationLedger')
  if not ledger then ledger=Builder.Build(offset+Vector3.new(-45,0,-28));ledger.Parent=station end
  entries[plot]={mountain=mountain,ledger=ledger,offset=offset,station=station}
 end)
end
local function folder(f)if f.Name=='SandPlots'then for _,p in f:GetChildren()do watch(p)end;f.ChildAdded:Connect(watch)end end
for _,f in workspace:GetChildren()do folder(f)end;workspace.ChildAdded:Connect(folder)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.35 then return end;elapsed=0
 for plot,e in entries do
  if not plot.Parent then entries[plot]=nil
  else
   local player=Players:GetPlayerByUserId(plot:GetAttribute('OwnerUserId'))
   local state=player and player:FindFirstChild('SandPrototypeState')
   local m=e.mountain
   local complete=Builder.Update(e.ledger,{Owner=player and(player.DisplayName..' / УЧАСТОК')or 'ЛИЧНЫЙ УЧАСТОК',Initial=m:GetAttribute('InitialCells'),Dug=m:GetAttribute('DugCells'),Remaining=m:GetAttribute('RemainingCells'),Status=m:GetAttribute('PersistenceStatus'),Finds=state and state:GetAttribute('FindCount')or 0})
   if complete and not e.trophy then
    e.trophy=Builder.Trophy(e.offset+Vector3.new(-52,0,-28));e.trophy.Parent=e.station
   elseif not complete and e.trophy then e.trophy:Destroy();e.trophy=nil end
  end
 end
end)
