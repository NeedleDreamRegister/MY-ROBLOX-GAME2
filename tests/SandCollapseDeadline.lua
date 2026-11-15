-- The deadline must interrupt inside one vacancy, preserving its remaining work.
return function(Collapse)
 local cells={}
 for y=1,8 do cells[y]=true end
 local moves=0
 local function get(x,y,z)return x==0 and z==0 and cells[y]or nil end
 local function transfer(_,sx,sy,sz,x,y,z)
  assert(cells[sy]and not cells[y])
  cells[sy]=nil cells[y]=true moves+=1
 end
 local function contains(x,y,z)return x==0 and z==0 and y>=0 and y<=8 end
 local queue=Collapse.Queue(9)
 local n,retry=Collapse.Process(queue,{x=0,y=0,z=0,budget=8},get,transfer,function()return true end,8,8,contains,0,function()return moves<2 end)
 assert(n==2 and moves==2,'deadline must stop after two transfers, got '..moves)
 assert(retry and retry.y==2 and retry.budget==6,'unfinished vacancy lost')
 local paused,nextRetry=Collapse.Process(queue,retry,get,transfer,function()return true end,8,8,contains,0,function()return false end)
 assert(paused==0 and nextRetry and nextRetry.y==2 and nextRetry.budget==6)
 local resumed,left=Collapse.Process(queue,nextRetry,get,transfer,function()return true end,8,8,contains,0)
 assert(resumed==6 and not left and moves==8)
 local remaining=0 for _ in cells do remaining+=1 end
 assert(remaining==8 and not cells[8]and cells[0])
 return {interrupted=n,resumed=resumed,remaining=remaining,pausedWithoutMutation=true}
end
