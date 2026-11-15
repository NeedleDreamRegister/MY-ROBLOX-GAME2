local C=require(game:GetService('ReplicatedStorage').UpgradeConfig)
local Account=require(script.Parent.ProgressionAccount)
local T=require(script.Parent.UpgradeTransactions)
local Service={}
function Service.Create(config)
 local owner=config.owner
 local machine=config.machine
 local remote=config.remote
 local connections={}
 local lastAction=-math.huge
 local closed=false
 local function near()
  if closed or not config.canMutate() or not machine.Parent then return false end
  local ch=owner.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart');local h=ch and ch:FindFirstChildOfClass('Humanoid')
  return root and h and h.Health>0 and (root.Position-machine.PrimaryPart.Position).Magnitude<=C.ShopDistance
 end
 local function send(open,message)
  if closed or not owner.Parent then return end
  local a=assert(Account.Validate(config.getAccount()))
  remote:FireClient(owner,{Kind='state',Open=open==true,Message=message,Account=a})
 end
 local function changed(message)
  config.changed() config.publish()
  if config.tools then config.tools.Refresh() end
  if config.onUpdated then config.onUpdated()end
  send(false,message)
 end
 local prompt=assert(machine.PrimaryPart:FindFirstChild('UpgradePrompt'))
 table.insert(connections,prompt.Triggered:Connect(function(player)if player==owner and near()then send(true)end end))
 table.insert(connections,remote.OnServerEvent:Connect(function(player,request)
  if player~=owner or type(request)~='table' or request.OwnerUserId~=owner.UserId then return end
  if request.Action=='boardStyle'then
   local ch=owner.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid')
   if closed or not config.canMutate()or not h or h.Health<=0 then return end
  elseif not near()then return end
  local now=os.clock();if now-lastAction<C.ActionInterval then return end;lastAction=now
  if request.Action=='refresh' then send(false)return end
  if type(request.Action)~='string' or #request.Action>30 or(request.Item~=nil and(type(request.Item)~='string' or #request.Item>24))then return end
  local a=config.getAccount()
  local ok,message=T.Apply(a,request.Action,request.Item)
  if ok then changed(message)else send(false,message)end
 end))
 return {Publish=function()send(false)end,Open=function()if near()then send(true)end end,Destroy=function()closed=true;for _,c in connections do c:Disconnect()end end}
end
return Service

