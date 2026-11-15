local Board={}
Board.Order={'dune','coral','night'}
Board.Styles={
 dune={Name='DUNE',Deck=Color3.fromRGB(241,229,198),Rail=Color3.fromRGB(33,91,94),Accent=Color3.fromRGB(204,155,71)},
 coral={Name='CORAL',Deck=Color3.fromRGB(245,216,199),Rail=Color3.fromRGB(151,65,53),Accent=Color3.fromRGB(241,139,99)},
 night={Name='NIGHT',Deck=Color3.fromRGB(36,54,76),Rail=Color3.fromRGB(17,27,43),Accent=Color3.fromRGB(91,223,221)},
}
function Board.Build(id)
 local style=Board.Styles[id]or Board.Styles.dune
 local m=Instance.new('Model');m.Name='Sandboard';m:SetAttribute('Style',id or 'dune')
 local function p(name,size,cf,color,shape,material)
  local v=Instance.new('Part');v.Name=name;v.Size=size;v.CFrame=cf;v.Color=color;v.Material=material or Enum.Material.SmoothPlastic
  v.Anchored=true;v.Massless=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
  if shape then v.Shape=shape end;v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v.Parent=m;return v
 end
 local root=p('Deck',Vector3.new(1.92,.18,3.7),CFrame.identity,style.Deck);m.PrimaryPart=root
 p('Bottom',Vector3.new(2.02,.16,3.75),CFrame.new(0,-.11,0),style.Rail)
 for _,z in {-1.8,1.8}do
  p('RoundedRail',Vector3.new(2.03,.23,1.96),CFrame.new(0,-.07,z),style.Rail,Enum.PartType.Ball)
  p('RoundedDeck',Vector3.new(1.93,.18,1.9),CFrame.new(0,.015,z),style.Deck,Enum.PartType.Ball)
 end
 p('NoseRocker',Vector3.new(1.62,.22,1.14),CFrame.new(0,.1,-2.25)*CFrame.Angles(.16,0,0),style.Deck,Enum.PartType.Ball)
 p('CenterStringer',Vector3.new(.055,.025,4.8),CFrame.new(0,.11,0),style.Accent)
 for _,z in {-.8,.8}do
  p('TractionPad',Vector3.new(1.25,.035,.94),CFrame.new(0,.117,z),style.Rail)
  for i=1,5 do p('PadGroove',Vector3.new(1.12,.012,.026),CFrame.new(0,.141,z+(i-3)*.15),style.Rail:Lerp(style.Deck,.18))end
 end
 for _,x in {-.83,.83}do
  p('NoseRailGraphic',Vector3.new(.08,.026,1.3),CFrame.new(x,.11,-1.33),style.Accent)
  p('TailRailGraphic',Vector3.new(.08,.026,.85),CFrame.new(x,.11,1.47),style.Accent)
 end
 p('TailFin',Vector3.new(.07,.3,.8),CFrame.new(0,-.28,1.8),style.Rail)
 local plate=p('BrandPlate',Vector3.new(.85,.025,.45),CFrame.new(0,.13,-1.65),style.Rail)
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Top;gui.CanvasSize=Vector2.new(400,210);gui.LightInfluence=.8;gui.Parent=plate
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=style.Name..'\nDTM / SAND SURF';label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.TextColor3=style.Deck;label.Parent=gui
 return m
end
return Board
