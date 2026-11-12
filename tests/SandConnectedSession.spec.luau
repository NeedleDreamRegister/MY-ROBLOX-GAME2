-- QA store only. Reopens a connected-hole avalanche twice without adding rewards.
return function(modules,store,key)
 local C,F,Finds,Plot,Session=modules.SandPrototypeCollapse,modules.SandPrototypeVoxelField,modules.SandPrototypeFindData,modules.SandPrototypePlotData,modules.SandPrototypeSaveSession
 local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
 local realStore=store~=nil
 if not store then
  store={records={}}
  function store:UpdateAsync(k,callback)
   callback(copy(self.records[k]))local value=callback(copy(self.records[k]))
   if value then self.records[k]=copy(value)end return copy(value)
  end
 end
 key=key or "connected-holes-memory"
 local validate=Finds.Validator(1)
 local initial=assert(validate(Plot.Fresh()))
 initial.cells={{x=0,y=2,z=0},{x=0,y=3,z=0}}initial.dugCells=453 initial.artifact=false initial.collection={}
 initial.account.XP=453 initial.account.Coins=453
 initial.pendingCollapses={{x=0,y=0,z=0,budget=6},{x=0,y=1,z=0,budget=5}}
 initial=assert(validate(initial))
 local session=assert(Session.Open(store,key,initial,{owner="first",validate=validate,transition=Finds.Advances,compact=true}))
 local function run(data,limit)
  local field=F.Create()for _,v in data.cells do field.Set(v.x,v.y,v.z,true)end
  local q=C.Queue(455)for _,v in data.pendingCollapses do q.Push(table.clone(v))end
  local moved=data.movedCells local steps=0
  while q.Count()>0 and steps<limit do
   q.Step(function(e)
    local n,r=C.Process(q,e,function(x,y,z)return field.Has(x,y,z)end,function(_,sx,sy,sz,x,y,z)
     field.Set(sx,sy,sz,false)field.Set(x,y,z,true)
    end,function()return true end,1,6,function(x,y,z)return y>=0 and y<=6 and math.abs(x)<=6-y and math.abs(z)<=6-y end,0)
    moved+=n return r
   end,1)steps+=1
  end
  local nextValue=copy(data)nextValue.cells={}
  field.Each(function(x,y,z)table.insert(nextValue.cells,{x=x,y=y,z=z})end)
  nextValue.movedCells=moved nextValue.pendingCollapses=q.Export()
  return assert(validate(nextValue))
 end
 local partial=run(session.snapshot,2)
 assert(partial.movedCells==1 and #partial.pendingCollapses>0)
 assert(session:Save(partial,true))
 session=assert(Session.Open(store,key,initial,{owner="second",validate=validate,transition=Finds.Advances,compact=true}))
 assert(session.snapshot.movedCells==1 and #session.snapshot.pendingCollapses==#partial.pendingCollapses)
 local final=run(session.snapshot,128)
 assert(final.movedCells==5 and #final.pendingCollapses==0 and #final.cells==2)
 for _,v in final.cells do assert(v.y==0)end
 assert(session:Save(final,true))
 session=assert(Session.Open(store,key,initial,{owner="third",validate=validate,transition=Finds.Advances,compact=true}))
 final=session.snapshot
 assert(final.dugCells==453 and final.movedCells==5 and final.account.XP==453 and final.account.Coins==453 and final.account.CarriedCells==0)
 assert(session:Save(final,true))
 return {realDataStore=realStore,key=key,reopens=2,partialMoves=1,moved=5,pending=0,remaining=2,noExtraRewards=true}
end
