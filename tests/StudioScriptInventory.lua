-- Edit-only inventory: source equality alone does not detect extra script instances.
return function(manifest)
 assert(not game:GetService('RunService'):IsRunning(),'use the Edit model')
 local expected,roots={},{}
 local result={missing={},unexpected={},duplicates={},wrongClass={},expected=#manifest,actual=0}
 for _,row in manifest do
  assert(not expected[row.instance],'duplicate manifest path')
  expected[row.instance]=row
  roots[row.instance:match('^[^.]+')]=true
 end
 local seen={}
 for name in roots do
  local root=assert(game:FindFirstChild(name))
  for _,o in root:GetDescendants()do
   if o:IsA('LuaSourceContainer')then
    result.actual+=1
    local path=o:GetFullName()
    if seen[path]then table.insert(result.duplicates,path)end
    seen[path]=true
    local row=expected[path]
    if not row then table.insert(result.unexpected,path)
    elseif o.ClassName~=row.class then table.insert(result.wrongClass,path)end
   end
  end
 end
 for path in expected do if not seen[path]then table.insert(result.missing,path)end end
 return result
end
