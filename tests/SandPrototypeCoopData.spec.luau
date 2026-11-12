local Coop=require(game.ServerScriptService.SandPrototypeCoopData)
local Plot=require(game.ServerScriptService.SandPrototypePlotData)
local Rules=require(game.ServerScriptService.SandPrototypeAccessRules)
local passed=0
local function check(value,reason)assert(value,reason)passed+=1 end
local function fresh(id)return assert(Coop.Validator(id)(Plot.Fresh()))end
local source=fresh(1)
check(source.schemaVersion==2 and source.account.XP==0,"migration")
source.dugCells=2 table.remove(source.cells)table.remove(source.cells)source.outbound["2"]=2
check(Coop.Validator(1)(source)~=nil,"helper removes source mass")
local receiver=fresh(2)receiver.imports["1"]=0
check(Coop.Validator(2)(receiver)~=nil,"durable subscription")
local delta=Coop.CreditDelta(receiver.account,receiver.imports["1"],source.outbound["2"])
receiver.imports["1"]+=delta receiver.account.CarriedCells+=delta receiver.account.XP+=delta
check(delta==2 and Coop.Validator(2)(receiver)~=nil,"credit own wallet without digging own mountain")
check(Coop.CreditDelta(receiver.account,2,2)==0,"replay gives zero")
check(Coop.CreditDelta(receiver.account,2,1)==0,"older source gives zero")
check(Coop.CreditDelta({CapacityCells=20,CarriedCells=19},0,4)==1,"partial delivery")
check(Coop.CreditDelta({CapacityCells=20,CarriedCells=20},0,4)==0,"full bag")
check(Coop.CreditDelta(receiver.account,0,0/0)==0,"invalid confirmed counter")
local normalized=assert(Coop.Validator(2)(receiver))
normalized.imports["1"]=0 normalized.account.XP=0 normalized.account.CarriedCells=0
check(not Coop.Advances(receiver,normalized),"watermark rollback rejected")
normalized=assert(Coop.Validator(2)(receiver))normalized.account.Coins+=1
check(Coop.Validator(2)(normalized)==nil,"extra coin refused")
normalized=assert(Coop.Validator(1)(source))normalized.outbound["2"]=3
check(Coop.Validator(1)(normalized)==nil,"export exceeds removed cells")
normalized=assert(Coop.Validator(1)(source))normalized.outbound["01"]=0
check(Coop.Validator(1)(normalized)==nil,"noncanonical counter id")
normalized=fresh(2)normalized.accessMode="Unknown"
check(Coop.Validator(2)(normalized)==nil,"bad mode")
check(Coop.Validator(3)(receiver)==nil,"foreign owner refused")
normalized=fresh(2)normalized.imports["2"]=0
check(Coop.Validator(2)(normalized)==nil,"self import refused")
normalized=fresh(2)for i=10,138 do normalized.imports[tostring(i)]=0 end
check(Coop.Validator(2)(normalized)==nil,"history bound")
local original=Plot.Fresh()
local migrated=assert(Coop.Validator(1)(original))table.remove(migrated.cells)
check(#original.cells==165,"migration copy isolation")
check(Coop.Validator(-1)(Plot.Fresh())==nil,"fake id never accepted in persistent schema")
check(Coop.Validator(-1,true)(Plot.Fresh())~=nil,"isolated Studio id allowed explicitly")
check(Rules.Allows(1,1,"Closed",false),"owner allowed")
check(not Rules.Allows(1,2,"Closed",true),"closed blocks friend")
check(Rules.Allows(1,2,"Open",false),"open allows visitor")
check(Rules.Allows(1,2,"Friends",true),"confirmed friend allowed")
check(not Rules.Allows(1,2,"Friends",nil),"unknown friend denied")
return {passed=passed}
