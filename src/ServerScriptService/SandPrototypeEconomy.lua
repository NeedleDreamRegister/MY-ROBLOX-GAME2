-- One canonical wallet, saved atomically with the owner's existing mountain record.
local Players=game:GetService('Players')
local C=require(game.ReplicatedStorage.UpgradeConfig)
local A=require(script.Parent.ProgressionAccount)
local T=require(script.Parent.UpgradeTransactions)
local function create(owner)
 local E={} local accounts,states,connections={},{},{} local changed,allowed=function()end,function()return true end
 local cart,tools,onUpdated local lastStation={}
 local function publish(player,a)
  local f=player:FindFirstChild('SandPrototypeState')or Instance.new('Folder');f.Name='SandPrototypeState';f.Parent=player
  local attrs={ProgressionVersion=1,BoardStyle=a.BoardStyle or 'dune',CarriedCells=a.CarriedCells,CartCells=a.CartCells,Coins=a.Coins,XP=a.XP,TotalCoinsEarned=a.TotalCoinsEarned,
   ManualCapacity=C.Capacity(a),CapacityCells=C.Capacity(a),CartCapacity=C.CartCapacity(a),CartEnabled=a.CartEnabled,
   CapacityLevel=a.ToolLevels.shovel-1,BarrowOwned=a.CartLevel>0 and 1 or 0,ShovelLevel=a.LegacyWide and 1 or 0,
   CartLevel=a.CartLevel,SelectedTool=a.SelectedTool,ToolName=C.Tool(a.SelectedTool).Name,ToolLevel=a.ToolLevels[a.SelectedTool],MiningYield=C.Yield(a),
   ConveyorSections=a.ConveyorSections,ConveyorLevel=a.ConveyorLevel,ConveyorSand=a.ConveyorSand,ConveyorDeliveryAt=a.ConveyorDeliveryAt,InventoryCells=a.CarriedCells+a.CartCells}
  for k,v in attrs do f:SetAttribute(k,v)end
  if cart then cart.Update(a)end
 end
 function E.Notify(player)
  player=player or owner local a=states[player]if not a then return end
  changed()publish(player,a)if tools then tools.Refresh()end;if onUpdated then onUpdated()end
 end
 function E.Init(saved,onChanged,canMutate,_,transport)
  changed=onChanged or changed;allowed=canMutate or allowed;cart=transport
  for key,a in saved or{}do accounts[key]=assert(a.ProgressionVersion==1 and A.Validate(a)or A.Migrate(a))end
  local function add(p)
   if owner and p~=owner then return end
   local key=tostring(p.UserId);accounts[key]=accounts[key]or A.New();states[p]=accounts[key];
   -- Owner's requested Studio testing wallet; never applies to live servers.
   if game:GetService('RunService'):IsStudio() and p.UserId==11883917519 then
    local a=states[p]
    if a.Coins<10000000 then assert(T.Earn(a,10000000-a.Coins),'Studio wallet grant failed');changed() end
   end
   publish(p,states[p])
  end
  for _,p in Players:GetPlayers()do add(p)end
  table.insert(connections,Players.PlayerAdded:Connect(add))
 end
 function E.Attach(t,callback)tools=t;onUpdated=callback end
 function E.GetMutable(player)return states[player or owner]end
 function E.Publish(player)local a=states[player or owner]if a then publish(player or owner,a)end end
 function E.FreeCapacity(player)
  local a=states[player]if not a then return 0 end
  if a.CartEnabled and cart and not cart.CanLoad()then return 0 end
  return T.FreeCapacity(a)
 end
 function E.CanCarry(player)return allowed()and E.FreeCapacity(player)>0 end
 function E.RecordDig(player,amount)
  local a=states[player];assert(allowed()and a,'account unavailable')
  amount=amount or math.min(C.Yield(a),E.FreeCapacity(player))
  assert(amount<=E.FreeCapacity(player)and T.AddSand(a,amount),'dig exceeds capacity');E.Notify(player)
 end
 function E.Credit(player,n)
  local a=states[player]if not allowed()or not a or n>E.FreeCapacity(player)or not T.AddSand(a,n)then return false end
  E.Notify(player)return true
 end
 local function station(player,pad)
  if not allowed()or player~=owner or not states[player]then return false end
  local ch=player.Character;local r=ch and ch:FindFirstChild('HumanoidRootPart');local h=ch and ch:FindFirstChildOfClass('Humanoid')
  if not r or not h or h.Health<=0 or(r.Position-pad.Position).Magnitude>10 then return false end
  local now=os.clock()if now-(lastStation[player]or-math.huge)<.25 then return false end;lastStation[player]=now return true
 end
 function E.Sell(player,pad)
  if not station(player,pad)then return false end
  local ok=T.Sell(states[player],not cart or cart.CanSell(pad));if ok then E.Notify(player)end return ok
 end
 function E.GetSnapshot(player)
  local a=states[player]if not a then return end
  local result=assert(A.Validate(a));result.CapacityCells=C.Capacity(a)+(a.CartEnabled and C.CartCapacity(a)or 0);result.BarrowOwned=a.CartLevel>0 and 1 or 0;result.CapacityLevel=a.ToolLevels.shovel-1;result.ShovelLevel=a.LegacyWide and 1 or 0;return result
 end
 function E.ExportAccounts()local out={}for k,a in accounts do out[k]=assert(A.Validate(a))end return out end
 function E.Destroy()for _,c in connections do c:Disconnect()end;if tools then tools.Destroy()end;if cart then cart.Destroy()end end
 return E
end
local default=create(nil)default.Create=create return default

