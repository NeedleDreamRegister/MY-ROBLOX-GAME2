local Session=require(game.ServerScriptService.SandPrototypeSaveSession)
local Data=require(game.ServerScriptService.SandPrototypePlotData)
local store={value=nil,calls=0}
function store:UpdateAsync(_,callback)
	self.calls+=1
	local nextValue=callback(self.value)
	if nextValue then self.value=nextValue end
	return nextValue
end
local options={owner="test",now=function()return 100 end,ttl=30,validate=Data.Validator(42)}
local first,reason=Session.Open(store,"owner_42",Data.Fresh(),options)
assert(first,reason)
local wrong=Data.Fresh()
wrong.accounts["43"]={CapacityLevel=0,CapacityCells=20,CarriedCells=0,XP=0,Coins=0}
local calls=store.calls
assert(not first:Save(wrong,false),"foreign account saved")
assert(store.calls==calls,"invalid save reached store")
store.value.snapshot=wrong
assert(not first:Save(Data.Fresh(),false),"foreign stored profile overwritten")
assert(store.value.snapshot==wrong,"invalid stored profile changed")
store.value.snapshot=Data.Fresh()
assert(first:Save(Data.Fresh(),true),"release failed")
local original=store.value
local second=Session.Open(store,"owner_42",Data.Fresh(),{owner="other",validate=Data.Validator(43)})
assert(second,"empty personal accounts are valid")
local own=Data.Fresh()
own.revision=1
own.accounts["43"]={CapacityLevel=0,CapacityCells=20,CarriedCells=0,XP=0,Coins=0}
assert(second:Save(own,true),"own account failed")
local saved=store.value
assert(Session.Open(store,"owner_42",Data.Fresh(),options)==nil,"foreign loaded record accepted")
assert(store.value==saved,"rejected load overwrote data")
return {passed=9}
