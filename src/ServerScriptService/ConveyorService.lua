local Run=game:GetService('RunService')
local C=require(game.ReplicatedStorage.UpgradeConfig)
local T=require(script.Parent.UpgradeTransactions)
local S={}
function S.Create(config)
 local owner=config.owner local E=config.economy
 local start=config.origin+Vector3.new(16,-config.origin.Y+1.4,config.height*4+5)
 local finish=config.station.SellPad.Position+Vector3.new(-3.5,.9,0)
 local direction=(finish-start).Unit local length=(finish-start).Magnitude
 local model=Instance.new('Model');model.Name='PersonalConveyor';model:SetAttribute('OwnerUserId',owner.UserId);model:SetAttribute('Start',start);model:SetAttribute('Finish',finish)
 local sections={} local count=0 local closed=false local lastLoad=-math.huge local nextAuto=os.clock()+3
 local function part(parent,name,size,cf,color,material)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent return p
 end
 local intake=part(model,'Intake',Vector3.new(3.8,.3,2),CFrame.lookAt(start,start+direction),Color3.fromRGB(38,48,60))
 local prompt=Instance.new('ProximityPrompt');prompt.Name='LoadPrompt';prompt.ActionText='Загрузить песок';prompt.ObjectText='КОНВЕЙЕР';prompt.KeyboardKeyCode=Enum.KeyCode.F;prompt.HoldDuration=.3;prompt.MaxActivationDistance=9;prompt.RequiresLineOfSight=false;prompt.Parent=intake
 local function build(i)
  local f=Instance.new('Model');f.Name='Section'..i
  local seg=length/4;local mid=start+direction*((i-.5)*seg);local cf=CFrame.lookAt(mid,mid+direction)
  part(f,'Belt',Vector3.new(3.2,.28,seg),cf,Color3.fromRGB(32,36,44),Enum.Material.Rubber)
  for _,side in {-1,1}do
   part(f,'Rail',Vector3.new(.18,.45,seg),cf*CFrame.new(side*1.72,0,0),Color3.fromRGB(95,112,129))
   for _,z in {-seg*.36,seg*.36}do part(f,'Support',Vector3.new(.25,1.35,.3),cf*CFrame.new(side*1.4,-.7,z),Color3.fromRGB(76,86,101))end
  end
  for j=1,5 do local p=part(f,'Roller',Vector3.new(3.3,.4,.4),cf*CFrame.new(0,-.18,(j-3)*seg/5),Color3.fromRGB(122,137,147));p.Shape=Enum.PartType.Cylinder end
  local marks=Instance.new('Folder');marks.Name='BeltMarks';marks.Parent=f
  for j=1,math.max(2,math.floor(seg/2))do
   local p=part(marks,'Mark',Vector3.new(3.05,.035,.18),cf*CFrame.new(0,.16,-seg/2+j*2),Color3.fromRGB(209,160,69),Enum.Material.SmoothPlastic)
   p:SetAttribute('TrackFrame',cf);p:SetAttribute('TrackLength',seg);p:SetAttribute('Phase',j*2)
  end
  part(f,'Motor',Vector3.new(.6,.75,1.3),cf*CFrame.new(2.05,-.15,0),Color3.fromRGB(33,146,177))
  if i==4 then part(f,'OutletHood',Vector3.new(3.7,.3,1.4),CFrame.lookAt(finish,finish+direction)*CFrame.new(0,.8,-.25),Color3.fromRGB(29,66,70))end
  local badge=part(f,'Badge',Vector3.new(.08,.7,1.1),cf*CFrame.new(-1.85,.2,0),Color3.fromRGB(233,159,44))
  local gui=Instance.new('BillboardGui');gui.Size=UDim2.fromOffset(100,28);gui.StudsOffset=Vector3.new(0,1,0);gui.MaxDistance=45;gui.Parent=badge
  local l=Instance.new('TextLabel');l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=Color3.fromRGB(19,27,38);l.TextColor3=Color3.fromRGB(236,218,168);l.Text='СЕКЦИЯ '..i;l.TextSize=13;l.Font=Enum.Font.GothamBold;l.Parent=gui
  f.Parent=model;sections[i]=f
 end
 local api={}
 function api.Update()
  if closed then return end
  local a=E.GetMutable(owner);if not a then return end
  while count<a.ConveyorSections do count+=1;build(count)end
  model:SetAttribute('Sections',a.ConveyorSections);model:SetAttribute('Level',a.ConveyorLevel);model:SetAttribute('Speed',C.Conveyor.Speed[math.max(1,a.ConveyorLevel)])
  model:SetAttribute('Cargo',a.ConveyorSand);model:SetAttribute('Arrival',a.ConveyorDeliveryAt)
  prompt.Enabled=a.ConveyorSections==4;prompt.ObjectText=a.ConveyorSand>0 and 'ЛЕНТА ПЕРЕВОЗИТ ПЕСОК' or 'КОНВЕЙЕР · РУЧНАЯ ЗАГРУЗКА'
  intake.Transparency=a.ConveyorSections>0 and 0 or 1
 end
 local loadConnection=prompt.Triggered:Connect(function(player)
  if player~=owner or not config.canMutate() or os.clock()-lastLoad<.5 then return end
  local r=player.Character and player.Character:FindFirstChild('HumanoidRootPart');if not r or(r.Position-start).Magnitude>11 then return end
  lastLoad=os.clock();local a=E.GetMutable(owner);local ok=T.LoadConveyor(a,os.time(),length/C.Conveyor.Speed[math.max(1,a.ConveyorLevel)],config.cart.CanSell(intake))
  if ok then E.Notify(owner);config.save();api.Update()end
 end)
 model.Parent=config.station.Parent;api.Update()
 local elapsed=0
 local heartbeat=Run.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<.1 then return end;elapsed=0
  if closed or not config.canMutate()then return end
  local a=E.GetMutable(owner)
  if T.Deliver(a,os.time())then E.Notify(owner);config.save();api.Update()end
  local interval=C.Conveyor.AutoInterval[a.ConveyorLevel]or 0
  if interval>0 and os.clock()>=nextAuto then
   nextAuto=os.clock()+interval
   if a.ConveyorSand+C.Conveyor.AutoYield<=C.Conveyor.MaxBatch and config.extract()then
    if a.ConveyorSand==0 then a.ConveyorDeliveryAt=os.time()+math.ceil(length/C.Conveyor.Speed[a.ConveyorLevel])end
    a.ConveyorSand+=C.Conveyor.AutoYield;a.XP+=C.Conveyor.AutoYield;E.Notify(owner);config.save();api.Update()
   end
  end
 end)
 function api.Destroy()closed=true;loadConnection:Disconnect();heartbeat:Disconnect();model:Destroy()end
 return api
end
return S

