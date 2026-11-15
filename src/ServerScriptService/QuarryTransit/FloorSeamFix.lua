-- Join the existing park spurs to the workshop paving without overlapping faces.
local Geometry=game:GetService('GeometryService')
return function(garden,offset)
 offset=offset or Vector3.zero
 if garden:GetAttribute('WorkshopSeamFixed') then return end
 require(script.Parent.MergeEntrance)(garden,offset)
 local trimmed=0
 for _,rect in {{23,-18,31.08,23.88},{3,-2,12,12}} do
 local cutter=Instance.new('Part')
 cutter.Size=Vector3.new(rect[3],4,rect[4])
 cutter.CFrame=CFrame.new(Vector3.new(rect[1],-.5,rect[2])+offset)
 for _,name in {'WestPromenade','EastPromenade'} do
  local model=garden:FindFirstChild(name)
  if model then
   for _,p in model:GetChildren() do
    if p:IsA('BasePart') then
     local h=p.Size/2 local cf=p.CFrame
     local ex=math.abs(cf.XVector.X)*h.X+math.abs(cf.YVector.X)*h.Y+math.abs(cf.ZVector.X)*h.Z
     local ez=math.abs(cf.XVector.Z)*h.X+math.abs(cf.YVector.Z)*h.Y+math.abs(cf.ZVector.Z)*h.Z
     local q=p.Position-offset
     if q.X+ex>rect[1]-rect[3]/2 and q.X-ex<rect[1]+rect[3]/2 and q.Z+ez>rect[2]-rect[4]/2 and q.Z-ez<rect[2]+rect[4]/2 then
      local pieces=Geometry:SubtractAsync(p,{cutter},{SplitApart=false,CollisionFidelity=Enum.CollisionFidelity.Box})
      for _,piece in pieces do
       piece.Name=p.Name piece.Color=p.Color piece.Material=p.Material piece.Anchored=true
       piece.CanCollide=p.CanCollide piece.CanTouch=p.CanTouch piece.CanQuery=p.CanQuery piece.CastShadow=false
       piece.Parent=model
      end
      p:Destroy() trimmed+=1
     end
    end
   end
  end
 end
 cutter:Destroy()
 end
 garden:SetAttribute('WorkshopSeamFixed',true)
 return trimmed
end

