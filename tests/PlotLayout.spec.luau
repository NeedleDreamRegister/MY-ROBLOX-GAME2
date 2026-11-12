return function(Layout)
 local small=Layout.Get(6)
 assert(small.cells==455 and small.spacing==128 and small.origin==Vector3.new(-22,2,-66))
 assert(small.groundSize==Vector3.new(96,0,112)and small.groundCenter==Vector3.new(-8,0,-42),"old plot layout changed")
 for _,height in {12,74}do
  local l=Layout.Get(height)
  local plots={}
  for slot=1,4 do
   local offset=Vector3.new(((slot-1)%2)*l.spacing,0,math.floor((slot-1)/2)*l.spacing)
   local lo,hi=l.minimum+offset,l.maximum+offset
   for _,old in plots do assert(hi.X<=old.lo.X or lo.X>=old.hi.X or hi.Z<=old.lo.Z or lo.Z>=old.hi.Z,"plots overlap")end
   table.insert(plots,{lo=lo,hi=hi})
   local origin=l.origin+offset assert(origin.X%4==2 and origin.Z%4==2)
  end
  local right=l.origin.X+(height*2+1)*2
  local museum=19+l.equipmentShift.X
  local bay=16+l.equipmentShift.X
  assert(museum-4>right and bay-6>right,"equipment or museum buried")
  assert(museum+11<l.maximum.X and bay+6<l.maximum.X,"equipment outside ground")
  local old=Vector3.new(-22,2,-66)+Vector3.new(0,1,0)*4
  local shifted=l.origin+Vector3.new(0,1,height-6)*4
  assert(old==shifted,"physical core moved")
  assert(l.origin.Z+height*4+2==-40,"mountain moved into the forecourt")
 end
 return {oldLayoutPreserved=true,layouts=3,fourPlotsSeparated=true,equipmentOutsideSand=true,physicalCoreStable=true}
end
