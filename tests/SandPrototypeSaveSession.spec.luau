local Session = require(game.ServerScriptService.SandPrototypeSaveSession)
local function copy(v)
	if type(v) ~= "table" then return v end
	local result = {} for k, child in v do result[k] = copy(child) end return result
end
local initial = {schemaVersion=1,revision=0,initialCells=165,dugCells=0,movedCells=0,cells={},accounts={}}
for y=0,4 do for x=-(4-y),4-y do for z=-(4-y),4-y do table.insert(initial.cells,{x=x,y=y,z=z}) end end end
local store = {value=nil, fail=false}
function store:UpdateAsync(_, callback)
	if self.fail then error("injected network error") end
	-- Real UpdateAsync may run its callback again after a conflict.
	callback(copy(self.value))
	local result=callback(copy(self.value))
	if result then self.value=copy(result) end
	return copy(result)
end
local clock=1000
local function options(owner) return {owner=owner,now=function()return clock end,ttl=30} end
local passed=0
local first,reason=Session.Open(store,"test",initial,options("one"))
assert(first,reason) passed+=1
local second,blocked=Session.Open(store,"test",initial,options("two"))
assert(not second and blocked=="locked") passed+=1
local state=copy(first.snapshot)
table.remove(state.cells) state.dugCells=1
state.accounts["1"]={CarriedCells=1,CapacityCells=20,CapacityLevel=0,XP=1,Coins=0}
assert(first:Save(state,false))
assert(store.value.snapshot.revision==1 and store.value.snapshot.dugCells==1) passed+=1
assert(not first:Save(state,false),"stale local revision accepted") passed+=1
store.fail=true
assert(not first:Save(first.snapshot,false))
assert(first.revision==1 and store.value.snapshot.revision==1) passed+=1
store.fail=false
clock+=31
second=assert(Session.Open(store,"test",initial,options("two")))
assert(not first:Save(first.snapshot,false),"lost lease overwrote newer session") passed+=1
assert(second:Save(second.snapshot,true))
assert(store.value.lease==nil and second.closed) passed+=1
local third=assert(Session.Open(store,"test",initial,options("three")))
assert(third.snapshot.dugCells==1 and third.snapshot.accounts["1"].CarriedCells==1) passed+=1
local corrupt={value={formatVersion=99}}
corrupt.UpdateAsync=store.UpdateAsync
local bad=Session.Open(corrupt,"test",initial,options("bad"))
assert(not bad and corrupt.value.formatVersion==99,"corrupt data overwritten") passed+=1
return {passed=passed}
