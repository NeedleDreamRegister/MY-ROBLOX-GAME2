-- Bounded deterministic vacancy propagation. No services, rewards or new mass.
local Collapse={}
local diagonals={{1,0},{0,1},{-1,0},{0,-1},{1,1},{-1,1},{-1,-1},{1,-1}}
local function sourceAbove(x,y,z,getCell,phase)
		local source,sx,sz=getCell(x,y+1,z),x,z
		if not source then
			local start=(x*31+y*17+z*13+(phase or 0))%#diagonals
			for i=1,#diagonals do
				local offset=diagonals[(start+i-1)%#diagonals+1]
				local candidate=getCell(x+offset[1],y+1,z+offset[2])
				if candidate then source=candidate sx=x+offset[1]sz=z+offset[2]break end
			end
		end
	return source,sx,sz
end
function Collapse.Run(x,y,z,getCell,moveCell,canOccupy,budget,phase)
	local moves=0
	while moves<budget do
		local source,sx,sz=sourceAbove(x,y,z,getCell,phase)
		if not source then break end
		if not canOccupy(source,x,y,z)then return moves,true,x,y,z end
		moveCell(source,sx,y+1,sz,x,y,z)
		x,y,z=sx,y+1,sz
		moves+=1
	end
	-- The frame limit may stop a still-unsupported column. Return its vacancy.
	local nextSource=sourceAbove(x,y,z,getCell,phase)
	return moves,not not nextSource,x,y,z
end

-- A vacancy rises one level per transfer. Its remaining height bounds total work;
-- frameBudget bounds one step. Both character and frame stops preserve the job.
function Collapse.Advance(entry,getCell,moveCell,canOccupy,frameBudget,phase)
	local moves,pending,x,y,z=Collapse.Run(entry.x,entry.y,entry.z,getCell,moveCell,canOccupy,math.min(entry.budget,frameBudget),phase)
	local remaining=entry.budget-moves
	return moves,pending and remaining>0 and {x=x,y=y,z=z,budget=remaining}or nil
end

-- Resume old holes when a later transfer makes a source available above them.
-- A filled vacancy is cancelled before waking neighbours, so budgets never duplicate.
function Collapse.Process(queue,entry,getCell,moveCell,canOccupy,frameBudget,height,contains,phase)
 if getCell(entry.x,entry.y,entry.z)then return 0,nil end
 return Collapse.Advance(entry,getCell,function(source,sx,sy,sz,x,y,z)
  queue.Cancel(x,y,z)
  moveCell(source,sx,sy,sz,x,y,z)
  local below=y-1
  if below>=0 then
   for dx=-1,1 do for dz=-1,1 do
    local bx,bz=x+dx,z+dz
    if contains(bx,below,bz)and not getCell(bx,below,bz)then
     queue.Push({x=bx,y=below,z=bz,budget=height-below})
    end
   end end
  end
 end,canOccupy,frameBudget,phase)
end

-- Bounded round-robin continuation. Linked nodes allow O(1) cancellation.
function Collapse.Queue(limit)
 local first,last,count=nil,nil,0
 local byKey={}
 local api={}
 local function key(x,y,z)return string.format("%d,%d,%d",x,y,z)end
 local function remove(node)
  if node.previous then node.previous.next=node.next else first=node.next end
  if node.next then node.next.previous=node.previous else last=node.previous end
  byKey[node.key]=nil count-=1
  return node.entry
 end
 function api.Push(entry)
  if not entry or entry.budget<=0 then return false end
  local address=key(entry.x,entry.y,entry.z)
  local previous=byKey[address]
  if previous then previous.entry.budget=math.max(previous.entry.budget,entry.budget)return true end
  if count>=limit then return false end
  local node={entry=entry,key=address,previous=last}
  if last then last.next=node else first=node end
  last=node byKey[address]=node count+=1
  return true
 end
 function api.Cancel(x,y,z)
  local node=byKey[key(x,y,z)]
  return node and remove(node)or nil
 end
 function api.Step(callback,budget,canContinue)
  local checks=math.min(count,budget)
  local visited=0
  for _=1,checks do
   if not first or(canContinue and not canContinue())then break end
   local entry=remove(first)visited+=1
   api.Push(callback(entry))
  end
  return visited
 end
 function api.Count()return count end
 function api.Export()
  local result={}
  local node=first
  while node do result[#result+1]=table.clone(node.entry)node=node.next end
  return result
 end
 return api
end
return Collapse
