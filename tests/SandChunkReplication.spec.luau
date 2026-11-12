-- Template fallback must never resurrect fully removed chunks.
return function(Field)
 local base=Field.Create()base.Set(0,0,0,true)base.Set(1,0,0,true)base.Set(4,0,0,true)
 local template=base.Export()
 local folder=Instance.new("Folder")
 local function visible(x,y,z)
  local key=Field.Address(x,y,z)local chunk=folder:FindFirstChild(key)
  return Field.Contains(chunk and chunk.Value or template[key],x,y,z)
 end
 local field=Field.Create(template)field.Publish(folder,nil,template)
 assert(#folder:GetChildren()==0 and visible(0,0,0)and visible(4,0,0),"fresh template needed network instances")
 field.Set(0,0,0,false)field.Set(1,0,0,false)field.Publish(folder,nil,template)
 assert(#folder:GetChildren()==1 and folder["0,0,0"].Value=="0000000000000000","removed chunk not explicit")
 assert(not visible(0,0,0)and not visible(1,0,0)and visible(4,0,0),"deleted sand reappeared")
 field.Set(0,0,0,true)field.Publish(folder,nil,template)
 assert(visible(0,0,0)and not visible(1,0,0))
 field.Set(1,0,0,true)field.Publish(folder,nil,template)
 assert(#folder:GetChildren()==0 and visible(0,0,0),"restored baseline kept a stale delta")
 local empty=Field.Create()empty.Publish(folder,nil,template)
 assert(#folder:GetChildren()==2 and not visible(0,0,0)and not visible(4,0,0),"empty saved chunks fell back to baseline")
 folder:Destroy()
 return {freshInstances=0,fullyRemovedChunkExplicit=true,allEmptyRestored=true,baselineRestored=true}
end
