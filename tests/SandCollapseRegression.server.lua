-- Pure regression using shipped occupancy/collapse modules; no Terrain or DataStore writes.
return function()
 local Collapse=require(game.ServerScriptService.SandPrototypeCollapse)
 local Field=require(game.ReplicatedStorage.SandPrototypeVoxelField)
 local height=6
 local field=Field.Create()
 local function contains(x,y,z)return y>=0 and y<=height and math.abs(x)<=height-y and math.abs(z)<=height-y end
 for y=0,height do for x=-(height-y),height-y do for z=-(height-y),height-y do field.Set(x,y,z,true)end end end
 local initial=field.Count()
 local queue=Collapse.Queue(initial)
 local dug,moved,blocked=0,0,false
 local function get(x,y,z)return field.Has(x,y,z)and true or nil end
 local function transfer(_,sx,sy,sz,x,y,z)
  assert(field.Has(sx,sy,sz)and not field.Has(x,y,z))
  assert(contains(x,y,z))
  field.Set(sx,sy,sz,false)field.Set(x,y,z,true)moved+=1
 end
 local function process(e)
  local _,retry=Collapse.Process(queue,e,get,transfer,function()return not blocked end,2,height,contains,dug)
  return retry
 end
 local function dig(x,y,z)
  if not field.Set(x,y,z,false)then return false end
  dug+=1
  queue.Push({x=x,y=y,z=z,budget=height-y})
  return true
 end
 assert(dig(0,0,0))
 blocked=true queue.Step(process,8)
 assert(queue.Count()>0 and moved==0,'blocked collapse must remain pending')
 local encoded=field.Export()
 local jobs=queue.Export()
 field=Field.Create(encoded)queue=Collapse.Queue(initial)
 for _,e in jobs do queue.Push(e)end
 blocked=false
 local iterations,maxSeconds=0,0
 local function drain()
  while queue.Count()>0 do
   local started=os.clock()
   queue.Step(process,8)
   maxSeconds=math.max(maxSeconds,os.clock()-started)
   iterations+=1 assert(iterations<10000,'collapse queue failed to converge')
   assert(field.Count()+dug==initial,'mass changed')
  end
 end
 drain()
 assert(moved>0)
 for x=-3,3 do for z=-3,3 do
  dig(x,0,z)drain()
 end task.wait()end
 local restored=Field.Create(field.Export())
 assert(restored.Count()==initial-dug)
 return {initial=initial,remaining=field.Count(),dug=dug,moved=moved,queue=queue.Count(),steps=iterations,maxBatchSeconds=maxSeconds,blockedResume=true,snapshotRoundtrip=true}
end
