local G={}
function G.Build()
 local m=Instance.new('Model');m.Name='QuarryGroundV17';m:SetAttribute('PurelyVisual',true)
 local cream=Color3.fromRGB(239,232,216);local pale=Color3.fromRGB(231,220,193);local edge=Color3.fromRGB(225,201,160)
 local function p(class,name,size,cf,color,mat)
  local v=Instance.new(class);v.Name=name;v.Size=size;v.CFrame=cf;v.Color=color;v.Material=mat or Enum.Material.Sandstone;v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v.Parent=m;return v
 end
 local function triangle(a,b,c,col,mat)
  local ab,ac,bc=b-a,c-a,c-b
  if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c elseif ac.Magnitude>bc.Magnitude then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  local cross=ac:Cross(ab);if cross.Magnitude<.001 then return end
  local right=cross.Unit;local up=bc:Cross(right).Unit;local back=bc.Unit;local h=math.abs(ab:Dot(up))
  local x,y=math.abs(ab:Dot(back)),math.abs(ac:Dot(back))
  if x>.001 then p('WedgePart','LimestoneTransition',Vector3.new(.055,h,x),CFrame.fromMatrix((a+b)/2,right,up,back),col,mat)end
  if y>.001 then p('WedgePart','LimestoneTransition',Vector3.new(.055,h,y),CFrame.fromMatrix((a+c)/2,-right,up,-back),col,mat)end
 end
 local n=20;local rings={};local radii={.55,.72,.86,.98,1.08}
 for r,scale in radii do
  rings[r]={}
  for i=1,n do
   local angle=(i-1)*math.pi*2/n;local wobble=1+.045*math.sin(i*1.73)+.035*math.cos(i*2.21)
   rings[r][i]=Vector3.new(-25+math.cos(angle)*93*scale*wobble,.055,math.min(12.6,-28+math.sin(angle)*39*scale*wobble))
  end
 end
 for i=1,n do
  local j=i%n+1;local shade=cream:Lerp(pale,(math.sin(i*2.1)+1)*.045)
  triangle(Vector3.new(-25,.055,-28),rings[1][i],rings[1][j],shade,Enum.Material.Sandstone)
  for r=1,#rings-1 do
   local color=({cream:Lerp(pale,.4),Color3.fromRGB(231,216,186),Color3.fromRGB(226,204,165),Color3.fromRGB(224,195,147)})[r]
   local mat=r==1 and Enum.Material.Sandstone or Enum.Material.Sand
   triangle(rings[r][i],rings[r+1][i],rings[r+1][j],color,mat)
   triangle(rings[r][i],rings[r+1][j],rings[r][j],color,mat)
  end
 end
 local rng=Random.new(1717)
 -- A small service apron only: the spawn-to-mountain route stays open sand.
 for ix=1,6 do for iz=1,4 do
  local x=10+(ix-1)*5.2;local z=-9-(iz-1)*6
  p('Part','WorkshopPaver',Vector3.new(5.08,.09,5.88),CFrame.new(x,.1425,z),cream:Lerp(pale,rng:NextNumber(0,.26)))
 end end
 for _,bank in {{-114,-30},{66,-40},{-102,-55},{53,-56}}do
  for i=1,6 do
   local h=rng:NextNumber(.18,.7);local pos=Vector3.new(bank[1]+rng:NextNumber(-6,6),h/2,bank[2]+rng:NextNumber(-3,3))
   local v=p('Part','WeatheredLimestone',Vector3.new(rng:NextNumber(1.4,3.5),h,rng:NextNumber(1,2.6)),CFrame.new(pos)*CFrame.Angles(0,rng:NextNumber(-2,2),rng:NextNumber(-.08,.08)),pale:Lerp(Color3.fromRGB(180,162,127),rng:NextNumber(.1,.55)),Enum.Material.Limestone)
   v.Shape=Enum.PartType.Block;v.CanQuery=true
  end
 end
 -- Low inset accents frame the workshop, without drawing a path to the mountain.
 for _,x in {7.3,38.7}do p('Part','WorkshopInlay',Vector3.new(.07,.025,24),CFrame.new(x,.19,-18),Color3.fromRGB(165,132,80),Enum.Material.Metal)end
 for _,p in m:GetChildren()do if p.Name=='LimestoneTransition'and p.Material==Enum.Material.Sand then if p.Color==Color3.fromRGB(224,195,147)then p.Transparency=.55 elseif p.Color==Color3.fromRGB(226,204,165)then p.Transparency=.15 end end end
 return m
end
return G
