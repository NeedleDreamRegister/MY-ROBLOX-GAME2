local Session=require(game.ServerScriptService.SandPrototypeSaveSession)
local Finds=require(game.ServerScriptService.SandPrototypeFindData)
local Coop=require(game.ServerScriptService.SandPrototypeCoopData)
local Plot=require(game.ServerScriptService.SandPrototypePlotData)
local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
local function makeStore()
	local s={value=nil,failAfter=false}
	function s:UpdateAsync(_,cb)
		cb(copy(self.value))local nextValue=cb(copy(self.value))if nextValue then self.value=copy(nextValue)end
		if self.failAfter then self.failAfter=false error("response lost")end
		return copy(nextValue)
	end
	return s
end
local function options(id,token)return{owner=token,now=function()return 100 end,ttl=30,validate=Finds.Validator(id),transition=Finds.Advances}end
local a,b=makeStore(),makeStore()
local source=assert(Session.Open(a,"source",Plot.Fresh(),options(1,"source")))
local helper=assert(Session.Open(b,"helper",Plot.Fresh(),options(2,"helper")))
local d=copy(helper.snapshot)d.imports["1"]=0 assert(helper:Save(d,false))
d=copy(source.snapshot)
for i,c in d.cells do if Finds.Matches(d.artifact,c.x,c.y,c.z)then table.remove(d.cells,i)break end end
d.dugCells=1 d.outbound["2"]=1 d.artifact={kind=Finds.Kind,finderId="2",counter=1}
assert(source:Save(d,false))
-- Import already paid, but collectible receipt has not been written yet.
d=copy(helper.snapshot)d.imports["1"]=1 d.account.CarriedCells=1 d.account.XP=1 assert(helper:Save(d,false))
helper=assert(Session.Open(b,"helper",Plot.Fresh(),options(2,"helper")))
assert(Coop.CreditDelta(helper.snapshot.account,1,1)==0)
assert(Finds.CanClaim(source.snapshot.artifact,2,helper.snapshot.imports["1"]))
d=copy(helper.snapshot)d.collection["1"]={kind=Finds.Kind,counter=1}
b.failAfter=true assert(not helper:Save(d,false))
helper=assert(Session.Open(b,"helper",Plot.Fresh(),options(2,"helper")))
assert(helper.snapshot.collection["1"]and helper.snapshot.account.XP==1)
local sold=copy(helper.snapshot)sold.account.CarriedCells=0 sold.account.Coins=1 assert(helper:Save(sold,true))
helper=assert(Session.Open(b,"helper",Plot.Fresh(),options(2,"after-sale")))
assert(helper.snapshot.collection["1"]and helper.snapshot.account.Coins==1 and helper.snapshot.account.CarriedCells==0)
assert(helper:Save(helper.snapshot,true))assert(source:Save(source.snapshot,true))
return {passed=8}
