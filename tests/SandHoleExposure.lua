-- Runtime delay stays outside serialized vacancy entries.
return function(Collapse)
 local now,calls=0,0
 local queue=Collapse.Queue(8,function()return now end)
 queue.Push({x=0,y=0,z=0,budget=6},.2)
 queue.Push({x=1,y=0,z=0,budget=6})
 queue.Step(function(entry)calls+=1;assert(entry.x==1,'fresh hole refilled before exposure window')return nil end,8)
 assert(calls==1 and queue.Count()==1)
 local saved=queue.Export()
 assert(#saved==1 and saved[1].x==0)
 local fields=0;for _ in saved[1]do fields+=1 end
 assert(fields==4,'runtime deadline leaked into saved format')
 queue.Push({x=0,y=0,z=0,budget=7})
 now=.19
 queue.Step(function()error('neighbour wake erased exposure window')end,8)
 now=.2
 queue.Step(function(entry)assert(entry.budget==7);calls+=1 return nil end,8)
 assert(queue.Count()==0 and calls==2)
 return {delayed=true,fair=true,mergedBudget=true,savedFields=fields}
end
