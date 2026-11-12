local Session=require(game.ServerScriptService.SandPrototypeSaveSession)
local Coop=require(game.ServerScriptService.SandPrototypeCoopData)
local Plot=require(game.ServerScriptService.SandPrototypePlotData)
local function copy(v)if type(v)~="table"then return v end local t={}for k,c in v do t[k]=copy(c)end return t end
local function store()
	local result={value=nil,failBefore=false,failAfter=false}
	function result:UpdateAsync(_,callback)
		if self.failBefore then error("network before commit")end
		callback(copy(self.value))
		local nextValue=callback(copy(self.value))
		if nextValue then self.value=copy(nextValue)end
		if self.failAfter then self.failAfter=false error("response lost after commit")end
		return copy(nextValue)
	end
	return result
end
local clock=100
local function options(id,token)return{owner=token,now=function()return clock end,ttl=30,validate=Coop.Validator(id),transition=Coop.Advances}end
local a,b=store(),store()
local source=assert(Session.Open(a,"source",Plot.Fresh(),options(1,"source")))
local helper=assert(Session.Open(b,"helper",Plot.Fresh(),options(2,"helper")))
local helperData=copy(helper.snapshot)helperData.imports["1"]=0
assert(helper:Save(helperData,false),"subscription not saved")
local sourceData=copy(source.snapshot)
table.remove(sourceData.cells)sourceData.dugCells=1 sourceData.outbound["2"]=1
a.failBefore=true
assert(not source:Save(sourceData,false),"injected failure ignored")
assert((a.value.snapshot.outbound["2"]or 0)==0,"uncommitted mass was exported")
a.failBefore=false
assert(source:Save(sourceData,false),"source retry failed")
-- Crash before recipient write: subscription survives, source is recoverable.
helper=assert(Session.Open(b,"helper",Plot.Fresh(),options(2,"helper")))
helperData=copy(helper.snapshot)
local delta=Coop.CreditDelta(helperData.account,helperData.imports["1"],a.value.snapshot.outbound["2"])
assert(delta==1,"durable source not recoverable")
helperData.account.CarriedCells+=delta helperData.account.XP+=delta helperData.imports["1"]+=delta
b.failAfter=true
assert(not helper:Save(helperData,false),"ambiguous response not injected")
assert(not helper:Save(helperData,false),"stale session overwrote ambiguous commit")
assert(Session.Open(b,"helper",Plot.Fresh(),options(2,"new-helper"))==nil,"active lease was ignored")
clock=131
helper=assert(Session.Open(b,"helper",Plot.Fresh(),options(2,"new-helper")))
assert(helper.snapshot.account.CarriedCells==1 and helper.snapshot.imports["1"]==1,"committed wallet lost")
assert(Coop.CreditDelta(helper.snapshot.account,helper.snapshot.imports["1"],1)==0,"duplicate reward after crash")
local rollback=copy(helper.snapshot)rollback.imports["1"]=0 rollback.account.CarriedCells=0 rollback.account.XP=0
assert(not helper:Save(rollback,false),"rollback watermark accepted")
assert(helper:Save(helper.snapshot,true),"release helper")
assert(source:Save(source.snapshot,true),"release source")
return {passed=12}
