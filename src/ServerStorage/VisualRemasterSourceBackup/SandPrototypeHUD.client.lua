local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local Input=game:GetService('UserInputService')
local P=Players.LocalPlayer
local C=require(game.ReplicatedStorage:WaitForChild('UpgradeConfig'))
local Geometry=require(game.ReplicatedStorage:WaitForChild('SandPrototypeGeometry'))
local cachedInitial,cachedHeight
local Journey=require(game.ReplicatedStorage:WaitForChild('ExcavationJourney'))
local knownAccount
local accountRemote=game.ReplicatedStorage:WaitForChild('DTMUpgradeRemote')
accountRemote.OnClientEvent:Connect(function(message)if type(message)=='table'and message.Kind=='state'and type(message.Account)=='table'then knownAccount=message.Account end end)
local Context=require(game.ReplicatedStorage:WaitForChild('SandPrototypeClientContext'))
local mountain=Context.GetMountain(P)
local state=P:WaitForChild('SandPrototypeState')
local gold=Color3.fromRGB(230,189,115);local cyan=Color3.fromRGB(92,215,221)
local gui=Instance.new('ScreenGui');gui.Name='SandPrototypeHUD';gui.ResetOnSpawn=false;gui.DisplayOrder=5;gui.Parent=P.PlayerGui
local function round(p,r)local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,r);c.Parent=p end
local function panel(name,pos,size)
 local f=Instance.new('Frame');f.Name=name;f.Position=pos;f.Size=size;f.BackgroundColor3=Color3.fromRGB(19,37,45);f.BackgroundTransparency=.06;f.BorderSizePixel=0;f.Parent=gui;round(f,12)
 local s=Instance.new('UIStroke');s.Color=Color3.fromRGB(118,143,141);s.Transparency=.5;s.Parent=f;return f
end
local function label(parent,name,text,pos,size,font,color)
 local l=Instance.new('TextLabel');l.Name=name;l.Text=text;l.BackgroundTransparency=1;l.Position=pos;l.Size=size;l.Font=Enum.Font.GothamMedium;l.TextSize=font;l.TextColor3=color or Color3.fromRGB(228,235,222);l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=true;l.Parent=parent;return l
end
local card=panel('InventoryCard',UDim2.fromOffset(12,12),UDim2.fromOffset(306,134))
local brand=label(card,'Brand','DIG / THE MOUNTAIN',UDim2.fromOffset(14,8),UDim2.new(1,-28,0,15),10,Color3.fromRGB(141,179,182))
local money=label(card,'MoneyAndXP','0 ◈',UDim2.new(1,-128,0,5),UDim2.fromOffset(112,23),17,gold);money.TextXAlignment=Enum.TextXAlignment.Right;money.Font=Enum.Font.GothamBold;money.TextScaled=true;local moneyCap=Instance.new('UITextSizeConstraint');moneyCap.MinTextSize=10;moneyCap.MaxTextSize=17;moneyCap.Parent=money
local inventory=label(card,'Inventory','Песок 0 / 20',UDim2.fromOffset(14,31),UDim2.new(1,-28,0,25),19);inventory.Font=Enum.Font.GothamBold;inventory.TextScaled=true;local inventoryCap=Instance.new('UITextSizeConstraint');inventoryCap.MinTextSize=12;inventoryCap.MaxTextSize=19;inventoryCap.Parent=inventory
local bar=Instance.new('Frame');bar.Name='CapacityBar';bar.Position=UDim2.fromOffset(14,63);bar.Size=UDim2.new(1,-28,0,7);bar.BackgroundColor3=Color3.fromRGB(52,74,77);bar.BorderSizePixel=0;bar.Parent=card;round(bar,4)
local fill=Instance.new('Frame');fill.Name='Fill';fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=cyan;fill.BorderSizePixel=0;fill.Parent=bar;round(fill,4)
local tool=label(card,'Upgrade','Обычная лопата · 1/5',UDim2.fromOffset(14,78),UDim2.new(1,-28,0,18),12,cyan)
local progress=label(card,'MountainProgress','',UDim2.fromOffset(14,101),UDim2.new(1,-28,0,17),10,Color3.fromRGB(160,183,185))
local objective=panel('ObjectiveCard',UDim2.fromOffset(12,154),UDim2.fromOffset(306,83))
local objectiveTitle=label(objective,'ObjectiveTitle','Наполните контейнер',UDim2.fromOffset(14,10),UDim2.new(1,-106,0,23),14,gold);objectiveTitle.Font=Enum.Font.GothamBold
local detail=label(objective,'ObjectiveDetail','',UDim2.fromOffset(14,39),UDim2.new(1,-28,0,32),11,Color3.fromRGB(188,210,207))
local guide=Instance.new('TextButton');guide.Name='Guide';guide.Position=UDim2.new(1,-90,0,8);guide.Size=UDim2.fromOffset(78,30);guide.BackgroundColor3=Color3.fromRGB(43,78,81);guide.TextColor3=Color3.fromRGB(229,222,197);guide.Font=Enum.Font.GothamBold;guide.TextSize=10;guide.Text='МЕТКА';guide.Parent=objective;round(guide,9)
local status=label(gui,'SaveState','',UDim2.fromOffset(22,242),UDim2.fromOffset(296,18),9,Color3.fromRGB(158,178,182))
local anchor=Instance.new('Part');anchor.Name='DTMNavigationAnchor';anchor.Size=Vector3.new(.1,.1,.1);anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Parent=workspace
local bubble=Instance.new('BillboardGui');bubble.Name='ObjectiveBeacon';bubble.Size=UDim2.fromOffset(210,54);bubble.AlwaysOnTop=true;bubble.MaxDistance=1500;bubble.Enabled=false;bubble.Parent=anchor;bubble.Adornee=anchor
local badge=Instance.new('Frame');badge.Size=UDim2.fromScale(1,1);badge.BackgroundColor3=Color3.fromRGB(19,42,46);badge.BackgroundTransparency=.08;badge.BorderSizePixel=0;badge.Parent=bubble;round(badge,12)
local beaconTitle=label(badge,'Title','',UDim2.fromOffset(10,6),UDim2.new(1,-20,0,22),14,gold);beaconTitle.TextXAlignment=Enum.TextXAlignment.Center;beaconTitle.Font=Enum.Font.GothamBold
local beaconDistance=label(badge,'Distance','',UDim2.fromOffset(10,29),UDim2.new(1,-20,0,17),11);beaconDistance.TextXAlignment=Enum.TextXAlignment.Center
local compass=panel('DirectionCard',UDim2.new(.5,-100,0,12),UDim2.fromOffset(200,46));compass.Visible=false
local arrow=label(compass,'DirectionArrow','↑',UDim2.fromOffset(8,7),UDim2.fromOffset(30,30),24,gold);arrow.TextXAlignment=Enum.TextXAlignment.Center
local directionTitle=label(compass,'DirectionTitle','',UDim2.fromOffset(44,7),UDim2.new(1,-52,0,17),11,gold)
local directionDistance=label(compass,'DirectionDistance','',UDim2.fromOffset(44,25),UDim2.new(1,-52,0,15),10,Color3.fromRGB(190,214,212))
local canGuide=true
local manual=false;local auto=false;local wasFull=false;local lastInventory=0;local lastRatio=-1;local fillTween;local compact=false
local function pretty(n)local s=tostring(math.floor(n));repeat local changed,count=s:gsub('^(%d+)(%d%d%d)','%1 %2');s=changed until count==0;return s end
local function refresh()
 local a=state:GetAttributes();local plot=mountain.Parent;local station=plot and plot:FindFirstChild('SandPrototypeStation')
 local root=P.Character and P.Character:FindFirstChild('HumanoidRootPart');local h=P.Character and P.Character:FindFirstChildOfClass('Humanoid')
 local shop=P.PlayerGui:FindFirstChild('UpgradeUI');local modal=shop and shop:FindFirstChild('Modal');local inShop=modal and modal.Visible
 local cart=a.CartEnabled==true;local n=cart and(a.CartCells or 0)or(a.CarriedCells or 0);local capacity=cart and(a.CartCapacity or 500)or(a.ManualCapacity or 20)
 local all=(a.CarriedCells or 0)+(a.CartCells or 0);local full=n>=capacity and capacity>0
 local held=P.Character and P.Character:FindFirstChildOfClass('Tool')
 local advice=Journey.Resolve(a,{Remaining=mountain:GetAttribute('RemainingCells'),HasTool=held~=nil and held:GetAttribute('SandPrototypeTool')==true,Touch=Input.PreferredInput==Enum.PreferredInput.Touch,ToolLevels=knownAccount and knownAccount.ToolLevels})
 if P.Character and P.Character:GetAttribute('MountainSliding')then advice={Title='Спуск с горы',Detail=Input.PreferredInput==Enum.PreferredInput.Touch and 'Управляйте джойстиком · прыжок или СТОП — остановиться'or 'A / D — поворот · C или пробел — остановиться',Target=nil,AutoSale=false}end
 local autoSale=advice.AutoSale
 if autoSale and not wasFull then auto=true end;if not autoSale then auto=false end;wasFull=autoSale
 if all==0 and lastInventory>0 then manual=false end;lastInventory=all
 inventory.Text=string.format('%s %s / %s',cart and 'Тачка' or 'Песок',pretty(n),pretty(capacity))
 money.Text=pretty(a.Coins or 0)..' ◈';tool.Text=(a.ToolName or 'Обычная лопата')..' · '..tostring(a.ToolLevel or 1)..'/5'
 local dug=mountain:GetAttribute('DugCells')or 0;local initial=mountain:GetAttribute('InitialCells')or 1
 progress.Text=string.format('Добыто %.2f%%  ·  Находок %d',math.min(100,dug/math.max(1,initial)*100),a.FindCount or 0)
 local ratio=math.clamp(n/math.max(1,capacity),0,1)
 if ratio~=lastRatio then if fillTween then fillTween:Cancel()end;fillTween=Tween:Create(fill,TweenInfo.new(.12),{Size=UDim2.fromScale(ratio,1),BackgroundColor3=full and gold or cyan});fillTween:Play();lastRatio=ratio end
 local terrainOrigin=mountain:GetAttribute('TerrainOrigin')
 local initialCells=mountain:GetAttribute('InitialCells')or 67525
 if initialCells~=cachedInitial then cachedInitial=initialCells;cachedHeight=Geometry.Height(initialCells)or 36 end
 local height=cachedHeight
 local entry=typeof(terrainOrigin)=='Vector3'and terrainOrigin+Vector3.new(0,4,((height or 36)*4)+12)or Vector3.new(-34,6,-58)
 local target=entry;local targetName='ЗОНА ДОБЫЧИ'
 local compactTitles={['Доступен новый инструмент']='Новый инструмент',['Гора полностью выработана']='Гора выработана',['Последний песок добыт']='Гора выкопана',['Последняя партия в пути']='Последняя партия'}
 objectiveTitle.Text=compact and(compactTitles[advice.Title]or advice.Title)or advice.Title;detail.Text=advice.Detail
 if advice.Target=='shop'then
  local machine=station and station:FindFirstChild('UpgradeMachine');if machine and machine.PrimaryPart then target=machine.PrimaryPart.Position+Vector3.new(0,5,0);targetName='МАСТЕРСКАЯ'end
 elseif advice.Target=='cart'then
  local cartModel=plot and plot:FindFirstChild('FollowWheelbarrow');if cartModel and cartModel.PrimaryPart then target=cartModel.PrimaryPart.Position+Vector3.new(0,4,0);targetName='ВАША ТАЧКА'end
 elseif advice.Target==nil then target=nil end
 if(advice.Target=='sale'or manual and all>0)and station then target=station.SellPad.Position+Vector3.new(0,9,0);targetName='ПРОДАЖА ПЕСКА'end
 canGuide=target~=nil
 guide.Text=not canGuide and 'ГОТОВО'or(manual or auto)and 'СКРЫТЬ'or all>0 and 'ПРОДАЖА'or 'МЕТКА'
 guide.Visible=canGuide
 objectiveTitle.Size=UDim2.new(1,canGuide and -106 or -28,0,23)
 detail.Size=compact and canGuide and UDim2.new(1,-106,0,30)or UDim2.new(1,-28,0,compact and 30 or 32)
 local save=mountain:GetAttribute('PersistenceStatus')or 'Loading'
 local messages={SessionOnly='ТЕСТ В STUDIO · ПРОГРЕСС ДО ОСТАНОВКИ ИГРЫ',Saved='ПРОГРЕСС СОХРАНЁН',Dirty='СОХРАНЕНИЕ ПРОГРЕССА…',Saving='СОХРАНЕНИЕ ПРОГРЕССА…',Loading='ЗАГРУЗКА ПРОГРЕССА…',SaveFailed='НЕ УДАЛОСЬ СОХРАНИТЬ ПРОГРЕСС',LoadFailed='НЕ УДАЛОСЬ ЗАГРУЗИТЬ ПРОГРЕСС',LockLost='ПРОФИЛЬ ВРЕМЕННО НЕДОСТУПЕН',Locked='ПРОФИЛЬ УЖЕ ОТКРЫТ'}
 status.Text=compact and save=='SessionOnly'and 'STUDIO · ВРЕМЕННЫЙ ПРОГРЕСС'or messages[save]or 'ПРОВЕРКА ПРОГРЕССА…'
 local healthy=save=='SessionOnly'or save=='Saved'or save=='Dirty'or save=='Saving'
 if not healthy then objectiveTitle.Text='Дождитесь загрузки';detail.Text='Ваш прогресс подготавливается';status.TextColor3=Color3.fromRGB(242,169,124)else status.TextColor3=Color3.fromRGB(158,178,182)end
 if root and target then
  local distance=math.floor(Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z).Magnitude)
  local cam=workspace.CurrentCamera;local relative=cam and cam.CFrame:VectorToObjectSpace(Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z))
  if relative and relative.Magnitude>.1 then arrow.Rotation=math.deg(math.atan2(relative.X,-relative.Z))end
  directionTitle.Text=({['ПРОДАЖА ПЕСКА']='ПРОДАЖА',['ЗОНА ДОБЫЧИ']='ДОБЫЧА'})[targetName]or targetName;directionDistance.Text=distance<=9 and 'Вы у цели'or(distance..' м до цели')
  anchor.Position=target;beaconTitle.Text=targetName;beaconDistance.Text=distance<=9 and(targetName=='ПРОДАЖА ПЕСКА'and(Input.PreferredInput==Enum.PreferredInput.Touch and 'УДЕРЖИВАЙТЕ КНОПКУ ПРОДАЖИ'or 'УДЕРЖИВАЙТЕ E')or 'ВЫ У ЦЕЛИ')or(distance..' м')
 end
 card.Visible=not inShop;objective.Visible=not inShop;status.Visible=not inShop
 bubble.Enabled=(manual or auto)and canGuide and healthy and root~=nil and h~=nil and h.Health>0 and not inShop
 compass.Visible=bubble.Enabled
end
guide.Activated:Connect(function()if not canGuide then return end;if auto then auto=false;manual=false;wasFull=true else manual=not manual end;refresh()end)
local function resize()
 local vp=workspace.CurrentCamera.ViewportSize;compact=vp.X<600 or vp.Y<450
 local width=compact and math.clamp(vp.X*.44,222,260)or 306
 card.Size=UDim2.fromOffset(width,compact and 116 or 134);objective.Position=UDim2.fromOffset(12,compact and 142 or 154);objective.Size=UDim2.fromOffset(width,compact and 64 or 83)
 brand.TextSize=compact and 8 or 10;money.TextSize=compact and 14 or 17;money.Position=UDim2.new(1,-111,0,5);money.Size=UDim2.fromOffset(96,23)
 inventory.TextSize=compact and 16 or 19;inventoryCap.MaxTextSize=compact and 16 or 19;moneyCap.MaxTextSize=compact and 14 or 17;tool.Position=UDim2.fromOffset(14,compact and 75 or 78);progress.Position=UDim2.fromOffset(14,compact and 95 or 101);progress.TextSize=compact and 9 or 10
 objectiveTitle.TextSize=compact and 12 or 14;objectiveTitle.Size=UDim2.new(1,-102,0,23);detail.Position=UDim2.fromOffset(14,compact and 33 or 39);detail.Size=UDim2.new(1,-28,0,compact and 30 or 32);detail.TextSize=compact and 10 or 11
 guide.Size=UDim2.fromOffset(78,compact and 44 or 32);guide.Position=UDim2.new(1,-90,0,compact and 6 or 8)
 detail.Size=compact and UDim2.new(1,-106,0,30)or UDim2.new(1,-28,0,32)
 local navLeft=width+24;local navWidth=math.min(200,math.max(120,vp.X-navLeft-146));local navX=math.clamp(vp.X/2-navWidth/2,navLeft,math.max(navLeft,vp.X-146-navWidth))
 compass.Position=vp.X<600 and UDim2.fromOffset(12,232)or UDim2.fromOffset(navX,12);compass.Size=UDim2.fromOffset(vp.X<600 and width or navWidth,46)
 status.Position=UDim2.fromOffset(18,compact and 124 or 242);status.Size=UDim2.fromOffset(width-8,18);status.TextSize=8
end
workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(resize)
local elapsed=0;Run.Heartbeat:Connect(function(dt)elapsed+=dt;if elapsed>=.2 then elapsed=0;refresh()end end)
gui.Destroying:Connect(function()anchor:Destroy()end)
resize();refresh()
