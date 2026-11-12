-- Full Plots/World startup against a private copy of a supplied save envelope.
-- The main Script must be disabled; all DataStoreService accesses in both clones
-- are replaced with this memory service. The supplied envelope is never mutated.
return function(seed)
 local p=assert(game.Players:GetPlayers()[1])
 local scripts=game.ServerScriptService
 local main=scripts.SandPrototype
 assert(not main.Enabled and main:GetAttribute("TerrainHeight")==12)
 assert(tostring(p.UserId)==seed.snapshot.ownerId,"profile owner differs")
 local key="player_"..p.UserId
 local function replace(source,needle,value)
  local result={}local start=1 local count=0
  while true do local a,b=source:find(needle,start,true)if not a then break end
   result[#result+1]=source:sub(start,a-1)result[#result+1]=value start=b+1 count+=1
  end
  result[#result+1]=source:sub(start)assert(count>0,"QA injection point changed")return table.concat(result)
 end
 local service=Instance.new("ModuleScript")service.Name="QAGrowthDataService"
 local blob=game.HttpService:JSONEncode({[key]=seed})
 service.Source=[[
 local records=game:GetService("HttpService"):JSONDecode(]]..string.format("%q",blob)..[[)
 local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
 local store={records=records}
 function store:GetAsync(k)return copy(records[k])end
 function store:UpdateAsync(k,callback)local v=callback(copy(records[k]))if v then records[k]=copy(v)end return copy(v)end
 return {GetDataStore=function()return store end,store=store}
 ]]service.Parent=scripts
 local world=scripts.SandPrototypeWorld:Clone()world.Name="QAGrowthWorld"
 world.Source=replace(world.Source,'game:GetService("DataStoreService")',"require(script.Parent.QAGrowthDataService)")world.Parent=scripts
 local plots=scripts.SandPrototypePlots:Clone()plots.Name="QAGrowthPlots"
 plots.Source=replace(plots.Source,'game:GetService("DataStoreService")',"require(script.Parent.QAGrowthDataService)")
 plots.Source=replace(plots.Source,'local World=require(script.Parent.SandPrototypeWorld)',[[
 local NativeWorld=require(script.Parent.QAGrowthWorld)
 local World={Start=function(config)local result=NativeWorld.Start(config)shared.QAGrowthController=result return result end}
 ]])plots.Parent=scripts
 require(plots).Start(main)
 local deadline=os.clock()+8
 while not shared.QAGrowthController and os.clock()<deadline do task.wait(.05)end
 assert(shared.QAGrowthController,"growth world did not start")
 local mountain=p.SandPrototypeMountain.Value
 local api={mountain=mountain}
 function api.WaitSettled()
  local deadline=os.clock()+30
  while mountain:GetAttribute("PendingCollapses")>0 and os.clock()<deadline do task.wait(.1)end
  assert(mountain:GetAttribute("PendingCollapses")==0,"migrated holes did not settle")
  local a=shared.QAGrowthController.GetAccount()
  assert(mountain:GetAttribute("DugCells")==seed.snapshot.dugCells)
  assert(a.Coins==seed.snapshot.account.Coins and a.XP==seed.snapshot.account.XP and a.CarriedCells==seed.snapshot.account.CarriedCells and a.CartCells==seed.snapshot.account.CartCells,"migration granted/lost resources")
  return {initial=mountain:GetAttribute("InitialCells"),dug=mountain:GetAttribute("DugCells"),remaining=mountain:GetAttribute("RemainingCells"),
   moved=mountain:GetAttribute("MovedCells"),pending=0,coins=a.Coins,xp=a.XP,carried=a.CarriedCells,cart=a.CartCells}
 end
 function api.Finish(expectedNewDigs)
  local a=shared.QAGrowthController.GetAccount()
  assert(mountain:GetAttribute("DugCells")==seed.snapshot.dugCells+expectedNewDigs)
  assert(a.XP==seed.snapshot.account.XP+expectedNewDigs and a.CarriedCells==seed.snapshot.account.CarriedCells+expectedNewDigs and a.Coins==seed.snapshot.account.Coins)
  assert(shared.QAGrowthController.Close())
  local raw=require(service).store.records[key]
  local validate=require(scripts.SandPrototypeFindData).Validator(p.UserId,false,false,2925)
  local final=assert(require(scripts.SandPrototypeSaveSession).Read(raw,validate))
  assert(raw.formatVersion==3 and raw.migrationBackups["455"].snapshot.initialCells==455)
  assert(final.account.XP==a.XP and final.account.Coins==a.Coins and final.account.CartCells==a.CartCells)
  return {fullPlotsStartup=true,privateProfileCopy=true,format=3,originalBackup=true,initial=2925,dug=final.dugCells,
   moved=final.movedCells,pending=#final.pendingCollapses,coins=a.Coins,xp=a.XP,carried=a.CarriedCells,cart=a.CartCells,productionStoreCalls=0}
 end
 return api
end
