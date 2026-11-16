-- Server-owned sprint speed. Cart, seats and sandboarding retain movement control.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local remote=Instance.new('RemoteEvent');remote.Name='DTMSprint';remote.Parent=game.ReplicatedStorage
local held,active={},{},{}
remote.OnServerEvent:Connect(function(p,value)
 if type(value)~='boolean'then return end
 held[p]=value
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.05 then return end;elapsed=0
 for _,p in Players:GetPlayers()do
  local ch=p.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local state=p:FindFirstChild('SandPrototypeState')
  local eligible=h and h.Health>0 and not h.SeatPart and not ch:GetAttribute('MountainSliding')and not(state and state:GetAttribute('PushingCart'))
  local old=active[p]
  if old and(old.h~=h or not eligible or not held[p])then
   if old.h.Parent then
    if old.h.WalkSpeed==24 then old.h.WalkSpeed=old.base end
    old.h:SetAttribute('DTMSprinting',nil);old.h:SetAttribute('DTMWalkBase',nil)
   end
   active[p]=nil
  end
  if eligible and held[p]and not active[p]and h.WalkSpeed>0 and h.WalkSpeed<=16 then
   active[p]={h=h,base=h.WalkSpeed};h:SetAttribute('DTMWalkBase',h.WalkSpeed);h:SetAttribute('DTMSprinting',true);h.WalkSpeed=24
  end
 end
end)
local function watch(p)p.CharacterAdded:Connect(function()held[p]=nil end)end
Players.PlayerAdded:Connect(watch);for _,p in Players:GetPlayers()do watch(p)end
Players.PlayerRemoving:Connect(function(p)held[p]=nil;active[p]=nil end)
