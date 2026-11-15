local F={}
function F.Apply(m)
 local glass=m:FindFirstChild('DisplayGlass');local bay=m:FindFirstChild('ShowcaseBody');local back=m:FindFirstChild('DisplayBack')
 if not glass or not bay or not back then return end
 bay.Size=Vector3.new(2.55,6.75,.35);bay.Position=Vector3.new(glass.Position.X,bay.Position.Y,glass.Position.Z-3.7)
 back.Position=Vector3.new(glass.Position.X,glass.Position.Y,glass.Position.Z-3.5)
 glass.Transparency=.91
 if not m:FindFirstChild('DisplaySideWall')then
  for _,side in {-1,1}do local p=Instance.new('Part');p.Name='DisplaySideWall';p.Size=Vector3.new(.12,4.2,3.5);p.Position=Vector3.new(glass.Position.X+side*1.18,glass.Position.Y,glass.Position.Z-1.75);p.Color=Color3.fromRGB(28,39,49);p.Material=Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=m end
 end
 m:SetAttribute('VisualVersion',17)
end
return F
