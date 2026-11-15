-- Shipped save/collapse modules, JSON-backed in-memory store; no DataStore calls.
return function()
 local S=game.ServerScriptService
 local Sessions=require(S.SandPrototypeSaveSession)
 local Progress=require(S.ProgressionData)
 local Account=require(S.ProgressionAccount)
 local Transactions=require(S.UpgradeTransactions)
 local Collapse=require(S.SandPrototypeCollapse)
 local Geometry=require(game.ReplicatedStorage.SandPrototypeGeometry)
 local Field=require(game.ReplicatedStorage.SandPrototypeVoxelField)
 local json=game:GetService('HttpService')
 local function copy(value)return value and json:JSONDecode(json:JSONEncode(value))end
 local stored,failNext=nil,false
 local store={}
 function store:UpdateAsync(key,callback)
  assert(key=='isolated-collapse-test')
  if failNext then failNext=false;error('injected write failure')end
  local nextValue=callback(copy(stored))
  if not nextValue then return nil end
  stored=copy(nextValue)
  return copy(stored)
 end
 local now=1000
 local validate=Progress.Validator(-1,true,67525)
 local initial={schemaVersion=4,ownerId='-1',revision=0,initialCells=67525,
  dugCells=0,movedCells=0,Cycles=0,LifetimeDug=0,voxelChunks=Geometry.Prepare(67525),
  account=Account.New(),outbound={},imports={},accessMode='Closed',artifact=false,collection={},pendingCollapses={}}
 assert(Transactions.Earn(initial.account,5000))
 assert(Transactions.Apply(initial.account,'upgradeTool','shovel'))
 assert(Transactions.Apply(initial.account,'buyCart'))
 initial=assert(validate(initial))
 local function open(owner)
  return Sessions.Open(store,'isolated-collapse-test',initial,{owner=owner,validate=validate,
   transition=Progress.Advances,compact=true,now=function()return now end,ttl=30})
 end
 local a=assert(open('A'))
 local state=copy(a.snapshot)
 local field=Field.Create(state.voxelChunks)
 assert(field.Set(0,0,36,false))
 state.voxelChunks=field.Export();state.dugCells=1;state.LifetimeDug=1
 assert(Transactions.AddSand(state.account,1))
 local queue=Collapse.Queue(67525,function()return now end)
 queue.Push({x=0,y=0,z=36,budget=36},now+.2)
 queue.Step(function()error('new hole collapsed before exposure delay')end,8)
 state.pendingCollapses=queue.Export()
 assert(state.pendingCollapses[1].notBefore==nil,'runtime clock leaked into save')
 failNext=true
 local ok,reason=a:Save(state)
 assert(not ok and reason:find('datastore error:',1,true))
 assert(a.revision==0 and stored.snapshot.dugCells==0,'failed write changed progress')
 assert(a:Save(state));state=copy(a.snapshot)
 local denied,why=open('B');assert(not denied and why=='locked')
 assert(a:Save(state,true))
 local b=assert(open('B'))
 local restored=b.snapshot
 assert(restored.dugCells==1 and restored.account.CartCells==1)
 assert(restored.account.Coins==state.account.Coins and restored.account.SpentCoins==state.account.SpentCoins)
 for key,bits in field.Export()do assert(restored.voxelChunks[key]==bits,'changed mountain after reopen')end
 assert(Field.Create(restored.voxelChunks).Count()==67524)
 local resumed=Collapse.Queue(67525)
 for _,entry in restored.pendingCollapses do resumed.Push(entry)end
 assert(resumed.Count()==1)
 field=Field.Create(restored.voxelChunks)
 local moved=0
 local function get(x,y,z)return field.Has(x,y,z)and true or nil end
 local function contains(x,y,z)return y>=0 and y<=36 and math.abs(x)<=36-y and math.abs(z)<=36-y end
 local function process(entry)
  local _,retry=Collapse.Process(resumed,entry,get,function(_,sx,sy,sz,x,y,z)
   assert(field.Set(sx,sy,sz,false));assert(field.Set(x,y,z,true));moved+=1
  end,function()return true end,8,36,contains,restored.dugCells)
  return retry
 end
 local steps=0
 while resumed.Count()>0 do resumed.Step(process,8);steps+=1;assert(steps<1000)end
 assert(moved>0 and field.Count()==67524)
 local nextState=copy(restored);nextState.voxelChunks=field.Export();nextState.movedCells+=moved;nextState.pendingCollapses={}
 assert(b:Save(nextState))
 -- An expired writer cannot overwrite a session acquired by another server.
 now+=31
 local c=assert(open('C'))
 local staleOK,staleReason=b:Save(copy(b.snapshot))
 assert(not staleOK and staleReason=='lease lost')
 local current=copy(c.snapshot)
 assert(Transactions.Sell(current.account,true))
 assert(c:Save(current));current=copy(c.snapshot)
 local coins=current.account.Coins
 local sold=Transactions.Sell(current.account,true)
 assert(not sold and current.account.Coins==coins)
 assert(c:Save(current,true))
 local final=assert(open('D')).snapshot
 assert(final.account.CartCells==0 and final.account.Coins==coins and final.dugCells==1)
 return {remaining=field.Count(),dug=1,moved=moved,queue=resumed.Count(),revision=final.revision,
  restoredPending=true,writeRetry=true,leaseIsolation=true,repeatedSaleRejected=true,productionWrites=0}
end
