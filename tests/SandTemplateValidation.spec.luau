-- The cached template path must give exact counts and keep validating changed bits.
return function(Geometry,Field)
 local checked=0
 for _,size in {165,455,2925,562475}do
  local shape=Geometry.Prepare(size)
  local result,count=Geometry.ValidateChunks(shape,size)
  assert(result and count==size,"template count changed")
  local field=Field.Create(shape)field.Set(0,0,0,false)
  local partial,remaining=Geometry.ValidateChunks(field.Export(),size)
  assert(partial and remaining==size-1,"changed chunk count was cached incorrectly")
  local key,edge
  for k,bits in shape do key=key or k if bits~="ffffffffffffffff"then edge=k end end
  local corrupt=table.clone(shape)corrupt[edge]="ffffffffffffffff"
  assert(not Geometry.ValidateChunks(corrupt,size),"out-of-shape bits passed the cached path")
  corrupt=table.clone(shape)corrupt[key]="xxxxxxxxxxxxxxxx"
  assert(not Geometry.ValidateChunks(corrupt,size),"invalid bits accepted")
  corrupt=table.clone(shape)corrupt["1000,0,0"]="0000000000000000"
  assert(not Geometry.ValidateChunks(corrupt,size),"unknown address accepted")
  checked+=5
 end
 return {checks=checked,shapes=4,templateCountsExact=true,changedBitsValidated=true}
end
