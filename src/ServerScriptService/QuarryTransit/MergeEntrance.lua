local Geometry=game:GetService('GeometryService')
return function(garden,offset)
 if garden:GetAttribute('EntranceMerged') then return end
 offset=offset or Vector3.zero
 local group=garden.WestPromenade
 local input={}
 local function triangle(a,b,c)
  local ab,ac,bc=b-a,c-a,c-b
  if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c elseif ac.Magnitude>bc.Magnitude then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  local right=ac:Cross(ab).Unit local up=bc:Cross(right).Unit local back=bc.Unit local h=math.abs(ab:Dot(up))
  for _,v in {{math.abs(ab:Dot(back)),(a+b)/2,right},{math.abs(ac:Dot(back)),(a+c)/2,-right}} do
   if v[1]>.001 and h>.001 then
    local p=Instance.new('WedgePart') p.Size=Vector3.new(.035,h,v[1]) p.CFrame=CFrame.fromMatrix(v[2]+offset,v[3],up,v[3]:Cross(up)) p.Anchored=true table.insert(input,p)
   end
  end
 end
 -- A single shared mouth: west walk and workshop branch merge before the plaza.
 local poly={Vector3.new(-3,.17,-8),Vector3.new(9,.17,-8),Vector3.new(9,.17,-18),Vector3.new(5,.17,-21),Vector3.new(-6,.17,-19)}
 for i=2,#poly-1 do triangle(poly[1],poly[i],poly[i+1]) end
 local originals={}
 for _,p in group:GetChildren() do
  if p:IsA('BasePart') then
   local q=p.Position-offset
   if q.X> -15 and q.Z> -30 then
    table.insert(originals,p)
    if p.Name~='LowLimestonePathEdge' then table.insert(input,p) end
   end
  end
 end
 local main=table.remove(input,1)
 local merged=Geometry:UnionAsync(main,input,{SplitApart=false,CollisionFidelity=Enum.CollisionFidelity.Box})
 for _,p in originals do p:Destroy() end
 main:Destroy() for _,p in input do if p.Parent==nil then p:Destroy() end end
 for _,p in merged do
  p.Name='MergedEntranceWalk' p.Color=Color3.fromRGB(218,204,169) p.Material=Enum.Material.Ground
  p.UsePartColor=true p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=group
 end
 garden:SetAttribute('EntranceMerged',true)
end

