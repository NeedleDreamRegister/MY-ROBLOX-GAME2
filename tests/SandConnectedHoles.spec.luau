-- Connected vacancies must wake again after a later transfer provides their source.
return function(Collapse,Field)
 local function column(height,initial,holes,blockedAtFirst)
  local field=Field.Create()
  for _,y in initial do field.Set(0,y,0,true)end
  local q=Collapse.Queue(128)
  for _,y in holes do q.Push({x=0,y=y,z=0,budget=height-y})end
  local total,steps=0,0
  local blocked=blockedAtFirst
  local function advance(e)
   local n,retry=Collapse.Process(q,e,function(x,y,z)return field.Has(x,y,z)end,function(_,sx,sy,sz,x,y,z)
    assert(field.Has(sx,sy,sz)and not field.Has(x,y,z),"duplicated sand")
    field.Set(sx,sy,sz,false)field.Set(x,y,z,true)
   end,function()return not blocked end,1,height,function(x,y,z)return x==0 and z==0 and y>=0 and y<=height end,0)
   assert(n<=1)total+=n
   return retry
  end
  if blocked then q.Step(advance,2)assert(total==0 and q.Count()==1)blocked=false end
  while q.Count()>0 do
   q.Step(advance,1)steps+=1 assert(steps<64,"connected holes never settled")
   if steps==2 then
    local saved=game.HttpService:JSONDecode(game.HttpService:JSONEncode({chunks=field.Export(),pending=q.Export()}))
    field=Field.Create(saved.chunks)q=Collapse.Queue(128)
    for _,e in saved.pending do q.Push(e)end
   end
  end
  return field,total,steps
 end
 local f,m=column(3,{2,3},{0,1},false)
 assert(f.Has(0,0,0)and f.Has(0,1,0)and not f.Has(0,2,0)and m==4,"sand floats over an older hole")
 local b,bm=column(3,{2,3},{0,1},true)
 assert(b.Has(0,0,0)and b.Has(0,1,0)and bm==4,"blocked connected hole did not resume")
 local q=Collapse.Queue(4)
 q.Push({x=0,y=0,z=0,budget=2})q.Push({x=1,y=0,z=0,budget=2})
 local visits=q.Step(function(e)q.Cancel(1,0,0)end,4)
 assert(visits==1 and q.Count()==0 and #q.Export()==0,"cancelling a queued neighbour corrupted traversal")
 -- A diagonal older hole also needs waking, without creating vacancies outside bounds.
 local field=Field.Create()field.Set(0,2,0,true)q=Collapse.Queue(4)
 q.Push({x=1,y=0,z=0,budget=3})q.Push({x=0,y=1,z=0,budget=2})
 local diagonalMoves=0
 while q.Count()>0 do q.Step(function(e)
  local n,r=Collapse.Process(q,e,function(x,y,z)return field.Has(x,y,z)end,function(_,sx,sy,sz,x,y,z)
   field.Set(sx,sy,sz,false)field.Set(x,y,z,true)
  end,function()return true end,1,3,function(x,y,z)return z==0 and((x==1 and y==0)or(x==0 and(y==1 or y==2)))end,0)
  diagonalMoves+=n return r
 end,1)end
 assert(diagonalMoves==2 and field.Has(1,0,0)and field.Count()==1,"diagonal vacancy stayed dormant")
 -- Deterministic multi-hole dig sequence with blocked destinations and bounded frames.
 field=Field.Create()
 local height=6
 local function contains(x,y,z)return y>=0 and y<=height and math.abs(x)<=height-y and math.abs(z)<=height-y end
 local initialPotential=0
 for y=0,height do for x=-(height-y),height-y do for z=-(height-y),height-y do field.Set(x,y,z,true)initialPotential+=y end end end
 q=Collapse.Queue(455)
 local dug,moved,removedPotential=0,0,0
 local blocked=false
 local function advance(e)
  local n,r=Collapse.Process(q,e,function(x,y,z)return field.Has(x,y,z)end,function(_,sx,sy,sz,x,y,z)
   assert(contains(x,y,z)and not field.Has(x,y,z)and sy==y+1)
   field.Set(sx,sy,sz,false)field.Set(x,y,z,true)
  end,function()return not blocked end,2,height,contains,dug)
  moved+=n return r
 end
 local function invariant()
  local mass,potential,budget=0,0,0
  field.Each(function(x,y,z)assert(contains(x,y,z))mass+=1 potential+=y end)
  for _,e in q.Export()do assert(not field.Has(e.x,e.y,e.z))budget+=e.budget end
  assert(mass+dug==455 and potential+moved+removedPotential==initialPotential,"mass/height changed")
  assert(budget+moved<=dug*8,"pending budget cannot be saved")
 end
 for action=1,180 do
  blocked=action%7<3
  local target
  field.Each(function(x,y,z)
   if not target and(not field.Has(x,y+1,z)or not field.Has(x+1,y,z)or not field.Has(x-1,y,z)
    or not field.Has(x,y,z+1)or not field.Has(x,y,z-1))then target={x=x,y=y,z=z}end
  end)
  if not target then break end
  field.Set(target.x,target.y,target.z,false)dug+=1 removedPotential+=target.y
  target.budget=height-target.y q.Push(advance(target))
  q.Step(advance,4)invariant()
 end
 blocked=false local frames=0
 while q.Count()>0 do q.Step(advance,4)frames+=1 assert(frames<512)invariant()end
 return {connectedMoves=m,blockedMoves=bm,diagonalMoves=diagonalMoves,queueCancellation=true,savedAndRestored=true,randomDigs=dug,randomMoves=moved,massConserved=true,saveBudgetValid=true}
end
