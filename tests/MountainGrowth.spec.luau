-- Prepare templates before entering UpdateAsync; no production records are used.
return function(m,store,key)
 local Plot,Finds,Geometry,Field,Codec,Session,Collapse=m.SandPrototypePlotData,m.SandPrototypeFindData,m.SandPrototypeGeometry,m.SandPrototypeVoxelField,m.SandPrototypeSaveCodec,m.SandPrototypeSaveSession,m.SandPrototypeCollapse
 local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
 local target=assert(Finds.Validator(1,false,false,2925)(Plot.Fresh(12)))
 local original=assert(Finds.Validator(1)(Plot.Fresh()))
 for _=1,100 do table.remove(original.cells,1)end
 original.dugCells=100 original.revision=7 original.outbound={["2"]=5}original.accessMode="Friends"
 original.account={CarriedCells=35,CartCells=20,CapacityCells=120,CapacityLevel=1,BarrowOwned=1,ShovelLevel=1,Coins=5,XP=95}
 original=assert(Finds.Validator(1)(original))
 local frozen=game.HttpService:JSONEncode(original)
 local thread=coroutine.create(function()return Plot.Grow(1,original,2925)end)
 local ok,grown,reason=coroutine.resume(thread)
 assert(ok and coroutine.status(thread)=="dead"and grown,reason or "migration yielded")
 assert(game.HttpService:JSONEncode(original)==frozen,"source mutated")
 local oldField=Field.Create()for _,c in original.cells do oldField.Set(c.x,c.y,c.z,true)end
 local field=Field.Create(grown.voxelChunks)
 for y=0,6 do for x=-(6-y),6-y do for z=-(6-y),6-y do
  assert(field.Has(x,y,z+6)==oldField.Has(x,y,z),"old hole was restored or old sand deleted")
  local a=Vector3.new(-22,2,-66)+Vector3.new(x,y,z)*4
  local b=Vector3.new(-22,2,-90)+Vector3.new(x,y,z+6)*4
  assert(a==b,"physical core moved")
 end end end
 assert(field.Count()==2825 and grown.dugCells==100 and #grown.pendingCollapses==100)
 assert(grown.artifact.z==original.artifact.z+6)
 assert(grown.account.CarriedCells==35 and grown.account.CartCells==20 and grown.account.Coins==5 and grown.account.XP==95)
 assert(grown.account.BarrowOwned==1 and grown.account.ShovelLevel==1 and grown.account.CapacityLevel==1)
 assert(grown.outbound["2"]==5 and grown.accessMode=="Friends")
 local proof=copy(original)proof.artifact={kind="PotteryShard",finderId="2",counter=3}
 assert(assert(Plot.Grow(1,proof,2925)).artifact.counter==3,"helper find proof changed")
 local realStore=store~=nil
 if not store then
  store={records={}}
  function store:UpdateAsync(k,callback)
   callback(copy(self.records[k]))local value=callback(copy(self.records[k]))
   if value then self.records[k]=copy(value)end return copy(value)
  end
  function store:SetAsync(k,value)self.records[k]=copy(value)end
  function store:GetAsync(k)return copy(self.records[k])end
 end
 key=key or "growth-memory"
 local function read()
  if realStore then local options=Instance.new("DataStoreGetOptions")options.UseCache=false return store:GetAsync(key,options)end
  return store:GetAsync(key)
 end
 -- A real QA key must be unique; only that key is seeded.
 store:SetAsync(key,{formatVersion=2,snapshot=Codec.Pack(original)})
 local options={owner="grow",validate=Finds.Validator(1,false,false,2925),compact=true,transition=Finds.Advances,
  migrate=function(raw)return Plot.Grow(1,raw,2925)end}
 local session=assert(Session.Open(store,key,target,options))
 assert(session.snapshot.dugCells==100 and Field.Create(session.snapshot.voxelChunks).Count()==2825)
 assert(session:Save(session.snapshot,true))
 local record=read()
 assert(record.formatVersion==3 and record.migrationBackups and record.migrationBackups["455"].formatVersion==2)
 local backup=assert(Session.Read(record.migrationBackups["455"],Finds.Validator(1)))
 assert(backup.initialCells==455 and backup.dugCells==100 and backup.account.Coins==5)
 options.owner="again"
 session=assert(Session.Open(store,key,target,options))
 assert(session.snapshot.initialCells==2925 and session.snapshot.dugCells==100 and #session.snapshot.pendingCollapses==100,"expansion repeated")
 -- Settle the newly supported old holes. Moving sand adds no currency or XP.
 local data=copy(session.snapshot)local q=Collapse.Queue(2925)field=Field.Create(data.voxelChunks)
 for _,entry in data.pendingCollapses do q.Push(entry)end
 local frames=0
 while q.Count()>0 do
  q.Step(function(entry)
   local n,r=Collapse.Process(q,entry,function(x,y,z)return field.Has(x,y,z)end,function(_,sx,sy,sz,x,y,z)
    field.Set(sx,sy,sz,false)field.Set(x,y,z,true)data.artifact=Finds.Move(data.artifact,sx,sy,sz,x,y,z)
   end,function()return true end,8,12,function(x,y,z)return Geometry.Contains(2925,x,y,z)end,100)
   data.movedCells+=n return r
  end,4)
  frames+=1 assert(frames<2048,"expanded core never settled")
  if frames%64==0 then task.wait()end
 end
 data.voxelChunks=field.Export()data.pendingCollapses={}
 data=assert(options.validate(data))
 assert(data.account.XP==95 and data.account.Coins==5 and data.account.CarriedCells==35 and field.Count()==2825)
 assert(session:Save(data,true))
 record=read()
 assert(record.migrationBackups["455"].snapshot.initialCells==455,"backup lost after movement")
 local final=assert(Session.Read(record,options.validate))
 assert(final.movedCells==data.movedCells and #final.pendingCollapses==0 and final.account.Coins==5 and final.account.XP==95,"fresh stored state differs")
 -- Active lease and invalid wallet must cancel without rewriting the source.
 local function rejected(snapshot,lease)
  local saved={formatVersion=2,snapshot=Codec.Pack(snapshot),lease=lease}
  local fake={writes=0}
  function fake:UpdateAsync(_,callback)local v=callback(copy(saved))if v then self.writes+=1 end return v end
  local o=table.clone(options)o.owner="new"o.now=function()return 100 end
  local s,r=Session.Open(fake,"denied",target,o)
  assert(not s and fake.writes==0,"unsafe expansion overwrote source")return r
 end
 assert(rejected(original,{owner="old",expiresAt=200})=="locked")
 local bad=copy(original)bad.account.Coins+=1 rejected(bad,nil)
 local full=assert(Finds.Validator(1)(Plot.Fresh()))
 full.cells={}full.dugCells=455 full.account.XP=455 full.account.Coins=455 full.artifact=false
 full=assert(Finds.Validator(1)(full))
 local expanded=assert(Plot.Grow(1,full,2925))
 assert(Field.Create(expanded.voxelChunks).Count()==2470 and #expanded.pendingCollapses==455,"completed mountain regrew")
 return {realDataStore=realStore,key=key,from=455,to=2925,added=2470,remaining=2825,dug=100,
  moved=data.movedCells,settleFrames=frames,noExtraRewards=true,physicalHolesPreserved=true,originalBackup=true,
  oldLeaseProtected=true,invalidWalletRejected=true,noCallbackYield=true,completedCorePreserved=true}
end
