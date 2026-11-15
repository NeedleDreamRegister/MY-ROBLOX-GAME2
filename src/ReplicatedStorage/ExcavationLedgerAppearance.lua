local Ledger={}
local cream=Color3.fromRGB(237,228,205);local teal=Color3.fromRGB(30,72,76);local bronze=Color3.fromRGB(181,137,72)
local function part(parent,name,size,cf,color,mat)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=mat or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent;return p
end
local function text(parent,name,value,pos,size,font,color)
 local t=Instance.new('TextLabel');t.Name=name;t.Text=value;t.BackgroundTransparency=1;t.Position=pos;t.Size=size;t.TextColor3=color or cream;t.Font=Enum.Font.GothamBold;t.TextSize=font;t.TextScaled=true;t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent;local cap=Instance.new('UITextSizeConstraint');cap.MaxTextSize=font;cap.MinTextSize=8;cap.Parent=t;return t
end
function Ledger.Build(base)
 local m=Instance.new('Model');m.Name='ExcavationLedger';m:SetAttribute('PresentationVersion',17)
 local function p(n,s,o,c,mat)return part(m,n,s,CFrame.new(base+o),c,mat)end
 p('LimestonePlinth',Vector3.new(10,.22,4),Vector3.new(0,.13,0),cream,Enum.Material.Sandstone)
 for _,x in {-3.9,3.9}do p('BronzeSupport',Vector3.new(.14,4.6,.14),Vector3.new(x,2.5,0),bronze)end
 local panel=p('LedgerPanel',Vector3.new(8.6,3.75,.24),Vector3.new(0,3.2,0),teal);m.PrimaryPart=panel
 for _,y in {1.29,5.11}do p('BronzeEdge',Vector3.new(8.7,.07,.3),Vector3.new(0,y,0),bronze)end
 local g=Instance.new('SurfaceGui');g.Name='LedgerDisplay';g.Face=Enum.NormalId.Back;g.CanvasSize=Vector2.new(860,375);g.LightInfluence=.2;g.MaxDistance=110;g.Parent=panel
 text(g,'Eyebrow','АРХИВ ЭКСПЕДИЦИИ',UDim2.fromScale(.045,.045),UDim2.fromScale(.91,.09),22,bronze)
 text(g,'Owner','ВАШ УЧАСТОК',UDim2.fromScale(.045,.18),UDim2.fromScale(.91,.13),35)
 text(g,'Progress','РАСКОПАНО 0.00%',UDim2.fromScale(.045,.37),UDim2.fromScale(.91,.18),49)
 local bg=Instance.new('Frame');bg.Name='ProgressTrack';bg.Position=UDim2.fromScale(.045,.6);bg.Size=UDim2.fromScale(.91,.035);bg.BackgroundColor3=Color3.fromRGB(59,104,105);bg.BorderSizePixel=0;bg.Parent=g
 local fill=Instance.new('Frame');fill.Name='Fill';fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=bronze;fill.BorderSizePixel=0;fill.Parent=bg
 text(g,'Finds','НАХОДКИ: 0  /  ГЛИНЯНЫЕ ОСКОЛКИ',UDim2.fromScale(.045,.7),UDim2.fromScale(.91,.09),24)
 text(g,'Status','КАЖДЫЙ РАСКОП ОСТАЁТСЯ В ИСТОРИИ',UDim2.fromScale(.045,.86),UDim2.fromScale(.91,.07),18,Color3.fromRGB(156,196,192))
 return m
end
function Ledger.Trophy(base)
 local m=Instance.new('Model');m.Name='QuarryCompletionTrophy';m:SetAttribute('CompletionTrophy',true)
 local function p(n,s,o,c,mat,rot)return part(m,n,s,CFrame.new(base+o)*(rot or CFrame.identity),c,mat)end
 p('Base',Vector3.new(3.4,.35,3.4),Vector3.new(0,.2,0),cream,Enum.Material.Sandstone)
 p('ObsidianPedestal',Vector3.new(2.8,1.2,2.8),Vector3.new(0,.95,0),teal,Enum.Material.Slate)
 p('BronzeCap',Vector3.new(2.9,.1,2.9),Vector3.new(0,1.6,0),bronze)
 local art=require(game.ReplicatedStorage.UpgradeToolAppearance).Build('shovel')
 local sculpture=Instance.new('Model');sculpture.Name='GoldenShovel';local anchor
 local baseCF=CFrame.new(base+Vector3.new(0,3.2,0))*CFrame.Angles(0,.2,-.15)
 for _,source in art:GetChildren()do if source:IsA('BasePart')then
  local v=source:Clone();for _,child in v:GetDescendants()do if child:IsA('WeldConstraint')then child:Destroy()end end
  v.Size*=.5;v.CFrame=baseCF*CFrame.new(source.Position*.5)*source.CFrame.Rotation;v.Color=bronze;v.Material=Enum.Material.Metal;v.Reflectance=.08;v.Anchored=true;v.Massless=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.Parent=sculpture
  if v.Transparency<1 then anchor=v end
 end end
 art:Destroy();sculpture.Parent=m
 for i=1,18 do local angle=i*math.pi/9;local o=Vector3.new(math.cos(angle)*1.27,2.85+math.sin(angle)*1.27,-.23)
  p('LaurelHalo',Vector3.new(.065,.18,.08),o,bronze,nil,CFrame.Angles(0,0,angle))end
 for _,side in {-1,1}do for i=1,4 do
  local leaf=p('LaurelLeaf',Vector3.new(.18,.42,.1),Vector3.new(side*(.8+i*.08),1.8+i*.23,.05),bronze,nil,CFrame.Angles(0,0,side*-.55));leaf.Shape=Enum.PartType.Ball
 end end
 for _,x in {-1.35,1.35}do p('PedestalReveal',Vector3.new(.045,1.05,.045),Vector3.new(x,1,1.43),bronze)end
 local shine=Instance.new('PointLight');shine.Color=Color3.fromRGB(255,205,116);shine.Range=5;shine.Brightness=.25;shine.Parent=anchor
 local plate=p('Plaque',Vector3.new(2.4,.75,.06),Vector3.new(0,1,1.43),bronze)
 local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Back;g.CanvasSize=Vector2.new(480,150);g.LightInfluence=.3;g.Parent=plate
 text(g,'Title','ГОРА ПОКОРЕНА\n100% РАСКОПОК',UDim2.fromScale(.04,.05),UDim2.fromScale(.92,.9),31,teal)
 return m
end
function Ledger.Update(model,data)
 local g=model.LedgerPanel.LedgerDisplay
 local healthy=data.Status=='Saved'or data.Status=='Dirty'or data.Status=='Saving'or data.Status=='SessionOnly'
 local initial=math.max(1,data.Initial or 1);local ratio=math.clamp((data.Dug or 0)/initial,0,1)
 local complete=healthy and (data.Initial or 0)>0 and data.Remaining==0 and (data.Dug or 0)>=initial
 g.Owner.Text=data.Owner or 'ЛИЧНЫЙ УЧАСТОК';g.Progress.Text=healthy and string.format('РАСКОПАНО %.2f%%',ratio*100)or 'ЗАГРУЗКА УЧАСТКА'
 g.ProgressTrack.Fill.Size=UDim2.fromScale(healthy and ratio or 0,1)
 g.Finds.Text='НАХОДКИ: '..(data.Finds or 0)..'  /  ГЛИНЯНЫЕ ОСКОЛКИ'
 g.Status.Text=complete and 'ЭКСПЕДИЦИЯ ЗАВЕРШЕНА · ГОРА ПОЛНОСТЬЮ РАЗРАБОТАНА'or 'КАЖДЫЙ РАСКОП ОСТАЁТСЯ В ИСТОРИИ'
 model:SetAttribute('Completed',complete);model:SetAttribute('Progress',ratio);model:SetAttribute('FindCount',data.Finds or 0)
 return complete
end
return Ledger
