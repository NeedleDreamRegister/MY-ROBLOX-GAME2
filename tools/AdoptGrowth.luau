-- One-off, guarded import of a tested growth session. Not a Remote or boot script.
-- Store and key are injected. A missing/changed source or another lease cancels.
return function(m,store,key,userId,baselineRecord,candidateRecord,options)
 options=options or {}
 assert(type(options.owner)=="string"and #options.owner>0,"stable import owner required for retries")
 local Session,Finds,Plot,Geometry,Codec=m.SandPrototypeSaveSession,m.SandPrototypeFindData,m.SandPrototypePlotData,m.SandPrototypeGeometry,m.SandPrototypeSaveCodec
 local sourceSize=baselineRecord.snapshot.initialCells
 local targetSize=candidateRecord.snapshot.initialCells
 assert(targetSize>sourceSize,"candidate must expand the source")
 Geometry.PrepareFamily(targetSize)
 local validateSource=Finds.Validator(userId,false,false,sourceSize)
 local validateTarget=Finds.Validator(userId,false,false,targetSize)
 local baseline,reason=Session.Read(baselineRecord,validateSource)if not baseline then return nil,reason end
 local candidate,why=Session.Read(candidateRecord,validateTarget)if not candidate then return nil,why end
 local function equal(a,b)
  if type(a)~=type(b)then return false end
  if type(a)~="table"then return a==b end
  for k,v in a do if not equal(v,b[k])then return false end end
  for k in b do if a[k]==nil then return false end end
  return true
 end
 local function same(a,b)
  local x,y=Codec.Pack(a),Codec.Pack(b)x.revision=nil y.revision=nil
  return equal(x,y)
 end
 local denied,mode
 local guarded={}
 function guarded:UpdateAsync(k,callback)
  return store:UpdateAsync(k,function(old)
   denied,mode=nil,nil
   if type(old)~="table"or type(old.snapshot)~="table"then denied="source missing"return nil end
   local size=old.snapshot.initialCells
   if size==sourceSize then
    local current=Session.Read(old,validateSource)
    if not current or not same(current,baseline)then denied="source progress changed"return nil end
    mode="adopted"
   elseif size==targetSize then
    local current=Session.Read(old,validateTarget)
    if not current or not same(current,candidate)then denied="target progress differs"return nil end
    local archived=type(old.migrationBackups)=="table"and old.migrationBackups[tostring(sourceSize)]
    local prior=archived and Session.Read(archived,validateSource)
    if not prior or not same(prior,baseline)then denied="target backup differs"return nil end
    mode="already-current"
   else denied="source size changed"return nil end
   return callback(old)
  end)
 end
 local session,err=Session.Open(guarded,key,candidate,{owner=options.owner,now=options.now,compact=true,
  validate=validateTarget,transition=Finds.Advances,migrate=function(current)
   local expanded,message=Plot.Grow(userId,current,targetSize)
   if not expanded then return nil,message end
   local data=assert(validateTarget(candidate))
   if not Finds.Advances(expanded,data)then return nil,"candidate rolls back growth progress"end
   data.revision=current.revision
   return data
  end})
 if not session then return nil,denied or err end
 local acquiredMode=mode
 if not same(session.snapshot,candidate)then session:Save(session.snapshot,true)return nil,"import returned different progress"end
 local saved,saveError=session:Save(session.snapshot,true)
 if not saved then return nil,denied or saveError end
 return {mode=acquiredMode,snapshot=session.snapshot,originalBackupKept=true}
end
