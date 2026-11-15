-- Schema 4 keeps the existing geometry, lease and cooperative proof format.
local Finds=require(script.Parent.SandPrototypeFindData)
local Account=require(script.Parent.ProgressionAccount)
local Geometry=require(game:GetService('ReplicatedStorage').SandPrototypeGeometry)
local D={}
local LIMIT=1000000000000
local function int(v,lo,hi)return type(v)=='number' and v==v and v%1==0 and v>=lo and v<=hi end
local function id(value,test)
 local n=type(value)=='string' and tonumber(value)
 return n and (int(n,1,9007199254740991) or test and int(n,-8,-1)) and string.format('%.0f',n)==value
end
local function counters(raw,owner,test,zero)
 if type(raw)~='table' then return nil,'missing contribution counters' end
 local out,total,count={},0,0
 for key,n in raw do
  if key==owner or not id(key,test) or not int(n,zero and 0 or 1,LIMIT) then return nil,'invalid contribution counter' end
  out[key]=n total+=n count+=1 if count>128 or total>LIMIT then return nil,'contribution limit' end
 end
 return out,total
end
function D.Validator(userId,test,expected)
 expected=expected or 2925
 local owner=tostring(userId)
 local legacy=Finds.Validator(userId,test,false,expected)
 return function(raw)
  if type(raw)~='table' then return nil,'missing world snapshot' end
  if raw.schemaVersion~=4 then
   local old,why=legacy(raw) if not old then return nil,why end
   old.account=Account.Migrate(old.account) old.schemaVersion=4 old.Cycles=0 old.LifetimeDug=old.dugCells
   return old
  end
  if raw.ownerId~=owner or not id(owner,test) then return nil,'invalid progression owner' end
  if not int(raw.dugCells,0,expected) or not int(raw.Cycles,0,100000000) or not int(raw.LifetimeDug,0,LIMIT)
   or raw.LifetimeDug~=raw.Cycles*expected+raw.dugCells then return nil,'invalid mining cycle ledger' end
  local account,why=Account.Validate(raw.account) if not account then return nil,why end
  -- Validate current physical sand and collapse work using the existing tested geometry path.
  local projection=table.clone(raw) projection.schemaVersion=3
  projection.account={Coins=raw.dugCells,XP=raw.dugCells,CarriedCells=0,CartCells=0,CapacityCells=20,CapacityLevel=0,BarrowOwned=0,ShovelLevel=0}
  projection.outbound={} projection.imports={} projection.artifact=false projection.collection={}
  local data,reason=legacy(projection) if not data then return nil,reason end
  local outbound,exported=counters(raw.outbound,owner,test,false) if not outbound then return nil,exported end
  local imports,imported=counters(raw.imports,owner,test,true) if not imports then return nil,imported end
  if exported>raw.LifetimeDug then return nil,'exports exceed lifetime extraction' end
  local artifact=raw.artifact
  if artifact~=false then
   if type(artifact)~='table' or artifact.kind~=Finds.Kind then return nil,'invalid artifact' end
   if artifact.finderId then
    if not id(artifact.finderId,test) or not int(artifact.counter,0,LIMIT) or raw.LifetimeDug<1 then return nil,'invalid artifact proof' end
    if artifact.finderId==owner then if artifact.counter~=0 then return nil,'invalid owner artifact proof' end
    elseif artifact.counter<1 or artifact.counter>(outbound[artifact.finderId] or 0) then return nil,'artifact exceeds export' end
    artifact={kind=Finds.Kind,finderId=artifact.finderId,counter=artifact.counter}
   else
    if not int(artifact.x,-74,74) or not int(artifact.y,0,74) or not int(artifact.z,-74,74)
     or not Geometry.Has(data,artifact.x,artifact.y,artifact.z) then return nil,'hidden artifact has no sand' end
    artifact={kind=Finds.Kind,x=artifact.x,y=artifact.y,z=artifact.z}
   end
  end
  if type(raw.collection)~='table' then return nil,'missing collection' end
  local collection,n={},0
  for source,proof in raw.collection do
   if not id(source,test) or type(proof)~='table' or proof.kind~=Finds.Kind or not int(proof.counter,0,LIMIT) then return nil,'invalid collection proof' end
   if source==owner then
    if not artifact or artifact.finderId~=owner or proof.counter~=0 then return nil,'unconfirmed owner collection' end
   elseif proof.counter<1 or proof.counter>(imports[source] or 0) then return nil,'unconfirmed imported collection' end
   collection[source]={kind=Finds.Kind,counter=proof.counter} n+=1 if n>129 then return nil,'collection limit' end
  end
  if artifact and artifact.finderId==owner and not collection[owner] then return nil,'missing owner collection' end
  data.schemaVersion=4 data.account=account data.Cycles=raw.Cycles data.LifetimeDug=raw.LifetimeDug
  data.outbound=outbound data.imports=imports data.artifact=artifact data.collection=collection
  return data
 end
end
function D.Advances(old,new)
 if old.schemaVersion~=4 or new.schemaVersion~=4 or old.ownerId~=new.ownerId or old.initialCells~=new.initialCells then return false end
 if new.Cycles~=old.Cycles or new.LifetimeDug<old.LifetimeDug then return false end
 if new.Cycles==old.Cycles and (new.dugCells<old.dugCells or new.movedCells<old.movedCells) then return false end
 if not Account.Advances(old.account,new.account) then return false end
 for _,field in {'outbound','imports'} do for key,n in old[field] do if (new[field][key] or -1)<n then return false end end end
 for key,proof in old.collection do local nextProof=new.collection[key];if not nextProof or nextProof.kind~=proof.kind or nextProof.counter~=proof.counter then return false end end
 if old.artifact and old.artifact.finderId then
  if not new.artifact or old.artifact.finderId~=new.artifact.finderId or old.artifact.counter~=new.artifact.counter then return false end
 elseif old.artifact==false and new.artifact~=false then return false end
 return true
end
function D.CanClaim(proof,recipient,received)
 return type(proof)=='table' and proof.kind==Finds.Kind and proof.finderId==tostring(recipient)
  and int(proof.counter,1,LIMIT)and int(received,0,LIMIT)and received>=proof.counter
end
return D

