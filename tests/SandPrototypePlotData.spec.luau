local Data=require(game.ServerScriptService.SandPrototypePlotData)
local Snapshot=require(game.ServerScriptService.SandPrototypeSnapshot)
local count=0
local function check(ok,message)assert(ok,message)count+=1 end
local fresh=Data.Fresh()
check(#fresh.cells==165 and Snapshot.Validate(fresh)~=nil,"fresh valid")
local initial,kind=Data.Initial(42,nil,100)
check(initial and kind=="fresh","no legacy")
local legacy={formatVersion=1,snapshot=Data.Fresh()}
local state={CapacityLevel=0,CapacityCells=20,CarriedCells=1,XP=1,Coins=0}
legacy.snapshot.accounts["42"]=state
table.remove(legacy.snapshot.cells)
legacy.snapshot.dugCells=1
legacy.snapshot.revision=17
initial,kind=Data.Initial(42,legacy,100)
check(initial and kind=="copied legacy" and #initial.cells==164,"copy progress")
check(initial.revision==0 and legacy.snapshot.revision==17,"separate revision")
initial.accounts["42"].Coins=77
check(state.Coins==0,"isolated copy")
initial,kind=Data.Initial(43,legacy,100)
check(initial and kind=="fresh" and #initial.cells==165,"other user starts fresh")
legacy.lease={owner="old",expiresAt=101}
check(Data.Initial(42,legacy,100)==nil,"active legacy refused")
legacy.lease.expiresAt=99
check(Data.Initial(42,legacy,100)~=nil,"expired legacy")
legacy.snapshot.accounts["43"]={CapacityLevel=0,CapacityCells=20,CarriedCells=0,XP=0,Coins=0}
check(Data.Initial(42,legacy,100)==nil,"ambiguous contributors")
local validate=Data.Validator(42)
check(validate(legacy.snapshot)==nil,"foreign account rejected")
legacy.snapshot.accounts["43"]=nil
check(validate(legacy.snapshot)~=nil,"own account accepted")
legacy.snapshot.dugCells=2
check(Data.Initial(42,legacy,100)==nil,"corruption refused")
return {passed=count}
