local Finds=require(game.ServerScriptService.SandPrototypeFindData)
local Coop=require(game.ServerScriptService.SandPrototypeCoopData)
local Plot=require(game.ServerScriptService.SandPrototypePlotData)
local count=0
local function check(ok,message)assert(ok,message)count+=1 end
local function fresh(id)return assert(Finds.Validator(id)(Plot.Fresh()))end
local function clone(id,value)return assert(Finds.Validator(id)(value))end
local function removeArtifact(data)
	for i,cell in data.cells do if Finds.Matches(data.artifact,cell.x,cell.y,cell.z)then table.remove(data.cells,i)data.dugCells+=1 return end end
	error("No artifact cell")
end
local source=fresh(1)
check(source.schemaVersion==3 and #source.cells==165,"migrate v1")
local v2=assert(Coop.Validator(1)(Plot.Fresh()))
check(Finds.Validator(1)(v2).schemaVersion==3,"migrate v2")
check(Coop.Validator(1)(source)==nil,"old consumer refuses v3")
check(Finds.Matches(source.artifact,0,1,0),"buried initial location")
local moved=Finds.Move(source.artifact,0,1,0,1,0,0)
check(Finds.Matches(moved,1,0,0)and Finds.Matches(source.artifact,0,1,0),"fall moves find without mutating source")
check(Finds.Move(source.artifact,4,0,4,3,0,4)==source.artifact,"unrelated cell does not move item")
local shifted=clone(1,source)shifted.artifact=moved
check(not Finds.Advances(source,shifted),"move requires digging")
local disabled=clone(1,source)disabled.artifact=false
check(Finds.Validator(1)(disabled).artifact==false,"explicit absence stays absent")
check(not Finds.Advances(source,disabled),"cannot erase hidden artifact")
local bad=clone(1,source)bad.artifact.y=4 bad.artifact.x=4
check(Finds.Validator(1)(bad)==nil,"item cannot exist in missing cell")
bad=clone(1,source)bad.artifact=nil
check(Finds.Validator(1)(bad)==nil,"missing artifact field is corruption")
bad=clone(1,source)bad.collection=false
check(Finds.Validator(1)(bad)==nil,"missing collection refused")
local own=clone(1,source)removeArtifact(own)
own.account.CarriedCells=1 own.account.XP=1
own.artifact={kind=Finds.Kind,finderId="1",counter=0}
own.collection["1"]={kind=Finds.Kind,counter=0}
check(Finds.Validator(1)(own)~=nil and Finds.Advances(source,own),"own find persisted with mining")
bad=clone(1,own)bad.collection={}
check(Finds.Validator(1)(bad)==nil,"own find must be in collection")
local sold=clone(1,own)sold.account.CarriedCells=0 sold.account.Coins=1
check(Finds.Validator(1)(sold)~=nil and sold.collection["1"]~=nil,"selling sand preserves collectible")
local helperSource=clone(1,source)removeArtifact(helperSource)
helperSource.outbound["2"]=1
helperSource.artifact={kind=Finds.Kind,finderId="2",counter=1}
check(Finds.Validator(1)(helperSource)~=nil,"helper proof bound to export")
check(not Finds.CanClaim(helperSource.artifact,2,0),"unpaid contribution cannot claim")
check(Finds.CanClaim(helperSource.artifact,2,1),"paid contribution can claim")
check(not Finds.CanClaim(helperSource.artifact,3,1),"wrong recipient refused")
check(not Finds.CanClaim(helperSource.artifact,2,nil),"invalid watermark refused")
local receiver=fresh(2)receiver.imports["1"]=0 receiver.collection["1"]={kind=Finds.Kind,counter=1}
check(Finds.Validator(2)(receiver)==nil,"collection cannot exceed import")
receiver.imports["1"]=1 receiver.account.CarriedCells=1 receiver.account.XP=1
check(Finds.Validator(2)(receiver)~=nil,"helper collection in own profile")
local duplicate=clone(2,receiver)duplicate.collection["1"]={kind=Finds.Kind,counter=1}
local items=0 for _ in duplicate.collection do items+=1 end
check(items==1 and Coop.CreditDelta(duplicate.account,1,1)==0,"duplicate receipt gives no extra item/sand")
bad=clone(2,receiver)bad.collection={}
check(not Finds.Advances(receiver,bad),"collection cannot roll back")
bad=clone(1,helperSource)bad.artifact.counter=2
check(Finds.Validator(1)(bad)==nil,"find counter cannot exceed exported reward")
local other=clone(1,helperSource)other.artifact={kind=Finds.Kind,finderId="1",counter=0}other.collection["1"]={kind=Finds.Kind,counter=0}
check(not Finds.Advances(helperSource,other),"finder proof immutable")
bad=clone(2,receiver)bad.collection["01"]={kind=Finds.Kind,counter=1}
check(Finds.Validator(2)(bad)==nil,"canonical collection identities")
local empty=assert(Coop.Validator(1)(Plot.Fresh()))empty.cells={}empty.dugCells=165 empty.account.XP=165 empty.account.Coins=165
check(Finds.Validator(1)(empty).artifact==false,"no new sand/item in excavated mountain")
return {passed=count}
