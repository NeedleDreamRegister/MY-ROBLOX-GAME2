-- Valid 10,000-hole profile; optional injected QA DataStore for real round trips.
return function(m,store,key)
 local Plot,Finds,Field,Codec,Collapse,Session=m.SandPrototypePlotData,m.SandPrototypeFindData,m.SandPrototypeVoxelField,m.SandPrototypeSaveCodec,m.SandPrototypeCollapse,m.SandPrototypeSaveSession
 local validate=Finds.Validator(1,false,false,562475)
 local initial=assert(validate(Plot.Fresh(74)))
 local field=Field.Create(initial.voxelChunks)
 local pending={}
 for x=-74,74 do for z=-74,74 do
  if #pending<10000 then
   assert(field.Set(x,0,z,false))pending[#pending+1]={x=x,y=0,z=z,budget=74}
  end
 end end
 -- Include both coordinate extremes, the peak, and a partially spent budget.
 for i,e in {{x=74,y=0,z=74,budget=74},{x=0,y=74,z=0,budget=1}}do
  local old=pending[i]assert(field.Set(old.x,old.y,old.z,true))assert(field.Set(e.x,e.y,e.z,false))pending[i]=e
 end
 pending[3].budget=8
 initial.voxelChunks=field.Export()initial.dugCells=#pending
 initial.account.XP=#pending initial.account.Coins=#pending initial.pendingCollapses=pending
 initial=assert(validate(initial))
 local q=Collapse.Queue(initial.initialCells)
 for _,entry in pending do assert(q.Push(table.clone(entry)))end
 assert(q.Count()==10000,"waiting holes were discarded")
 local packed=Codec.Pack(initial)
 assert(Codec.Format(initial,true)==4 and packed.pendingCollapses==nil and #packed.pendingPacked==50000)
 local restored=assert(validate(assert(Codec.Unpack(packed))))
 for i,e in pending do local r=restored.pendingCollapses[i]
  assert(e.x==r.x and e.y==r.y and e.z==r.z and e.budget==r.budget,"work order/budget changed")
 end
 for _,text in {"bad","!!!!!",string.rep("A",562476*5)}do
  local bad=table.clone(packed)bad.pendingPacked=text assert(not Codec.Unpack(bad),"invalid packed queue accepted")
 end
 local bad=table.clone(packed)bad.pendingCollapses={}assert(not Codec.Unpack(bad),"ambiguous queue accepted")
 bad=table.clone(packed)bad.pendingEncoding="future"assert(not Codec.Unpack(bad),"unknown queue accepted")
 bad=table.clone(packed)bad.pendingPacked="AAAAA"
 assert(not validate(assert(Codec.Unpack(bad))),"decoded zero work budget accepted")
 local real=store~=nil
 if not store then
  store={record=nil}
  function store:UpdateAsync(_,callback)local value=callback(self.record)if value then self.record=value end return value end
 end
 key=key or "large-queue-memory"
 local options={owner="large-queue-first",validate=validate,transition=Finds.Advances,compact=true}
 local session=assert(Session.Open(store,key,initial,options))
 assert(#session.snapshot.pendingCollapses==10000)
 assert(session:Save(session.snapshot,true))
 options.owner="large-queue-second"session=assert(Session.Open(store,key,initial,options))
 local data=session.snapshot field=Field.Create(data.voxelChunks)
 q=Collapse.Queue(data.initialCells)for _,entry in data.pendingCollapses do assert(q.Push(table.clone(entry)))end
 local processed=0
 q.Step(function(entry)
  processed+=1
  local moves,retry=Collapse.Process(q,entry,function(x,y,z)return field.Has(x,y,z)end,
   function(_,sx,sy,sz,x,y,z)field.Set(sx,sy,sz,false)field.Set(x,y,z,true)end,
   function()return true end,8,74,function(x,y,z)return y>=0 and y<=74 and math.abs(x)<=74-y and math.abs(z)<=74-y end)
  data.movedCells+=moves return retry
 end,10)
 data.voxelChunks=field.Export()data.pendingCollapses=q.Export()data=assert(validate(data))
 assert(processed==10 and data.movedCells>0 and field.Count()==552475)
 assert(session:Save(data,true))
 options.owner="large-queue-third"session=assert(Session.Open(store,key,initial,options))
 local final=session.snapshot
 assert(final.movedCells==data.movedCells and #final.pendingCollapses==#data.pendingCollapses)
 assert(final.account.XP==10000 and final.account.Coins==10000 and final.account.CarriedCells==0)
 assert(session:Save(final,true))
 local raw=Codec.Pack(final)
 return {realDataStore=real,key=key,pending=#final.pendingCollapses,moved=final.movedCells,retained=10000,
  packedQueueBytes=#raw.pendingPacked,payloadBytes=#game:GetService("HttpService"):JSONEncode(raw),noExtraRewards=true,reopens=2}
end
