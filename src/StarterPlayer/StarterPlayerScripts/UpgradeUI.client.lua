local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local R=game.ReplicatedStorage
local P=Players.LocalPlayer
local C=require(R:WaitForChild('UpgradeConfig'))
local Art=require(R:WaitForChild('UpgradeToolAppearance'))
local remote=R:WaitForChild('DTMUpgradeRemote')
local Audio=require(R:WaitForChild('GameAudio'))
local gui=Instance.new('ScreenGui');gui.Name='UpgradeUI';gui.ResetOnSpawn=false;gui.DisplayOrder=40;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=P:WaitForChild('PlayerGui')
local toast=Instance.new('TextLabel');toast.Name='UnlockToast';toast.AnchorPoint=Vector2.new(.5,1);toast.Position=UDim2.new(.5,0,1,-12);toast.Size=UDim2.new(0,260,0,30);toast.BackgroundColor3=Color3.fromRGB(29,84,78);toast.TextColor3=Color3.fromRGB(206,255,236);toast.Font=Enum.Font.GothamBold;toast.TextSize=12;toast.TextWrapped=true;toast.Visible=false;toast.ZIndex=60;toast.Parent=gui;local tc=Instance.new('UICorner');tc.CornerRadius=UDim.new(0,12);tc.Parent=toast
local toastToken=0
local function unlockToast(text)toastToken+=1;local token=toastToken;toast.Text=text;toast.Visible=true;task.delay(2,function()if toastToken==token then toast.Visible=false end end)end
local shade=Instance.new('Frame');shade.Name='Modal';shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.fromRGB(2,7,16);shade.BackgroundTransparency=.28;shade.Visible=false;shade.Active=true;shade.Parent=gui
local panel=Instance.new('Frame');panel.Name='Shop';panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.fromScale(.94,.88);panel.BackgroundColor3=Color3.new(1,1,1);panel.BorderSizePixel=0;panel.Parent=shade
local constraint=Instance.new('UISizeConstraint');constraint.MaxSize=Vector2.new(1060,700);constraint.Parent=panel
local function round(v,n)local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,n or 12);c.Parent=v end
local function stroke(v,color,thick)local s=Instance.new('UIStroke');s.Color=color;s.Thickness=thick or 1;s.Transparency=.2;s.Parent=v return s end
round(panel,18);stroke(panel,Color3.fromRGB(71,158,174),1)
local panelGradient=Instance.new('UIGradient');panelGradient.Color=ColorSequence.new(Color3.fromRGB(26,48,57),Color3.fromRGB(13,23,33));panelGradient.Rotation=25;panelGradient.Parent=panel
local function label(parent,text,size,pos,dims,color)
 local l=Instance.new('TextLabel');l.BackgroundTransparency=1;l.Text=text;l.Font=Enum.Font.GothamMedium;l.TextSize=size;l.TextColor3=color or Color3.fromRGB(231,237,250);l.Position=pos;l.Size=dims;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=true;l.Parent=parent return l
end
local title=label(panel,'FORGE / МАСТЕРСКАЯ',21,UDim2.fromOffset(18,10),UDim2.new(1,-80,0,28),Color3.fromRGB(238,207,147))
local balance=label(panel,'Монеты: 0',16,UDim2.fromOffset(18,39),UDim2.new(1,-100,0,24),Color3.fromRGB(250,203,106))

local subtitle=label(panel,'ИНСТРУМЕНТЫ  /  ТРАНСПОРТ  /  АВТОМАТИЗАЦИЯ',11,UDim2.fromOffset(18,42),UDim2.new(1,-350,0,20),Color3.fromRGB(138,174,185))
local wallet=Instance.new('Frame');wallet.Name='Wallet';wallet.Position=UDim2.new(1,-314,0,10);wallet.Size=UDim2.fromOffset(242,56);wallet.BackgroundColor3=Color3.fromRGB(55,48,34);wallet.BorderSizePixel=0;wallet.Parent=panel;round(wallet,12);stroke(wallet,Color3.fromRGB(149,119,67))
local walletCaption=label(wallet,'ВАШ БАЛАНС',10,UDim2.fromOffset(12,6),UDim2.new(1,-24,0,15),Color3.fromRGB(184,167,132))
balance.Parent=wallet;balance.Position=UDim2.fromOffset(12,23);balance.Size=UDim2.new(1,-24,0,28);balance.Font=Enum.Font.GothamBold;balance.TextSize=21

local close=Instance.new('TextButton');close.Name='Close';close.Text='X';close.Font=Enum.Font.GothamBold;close.TextSize=20;close.Size=UDim2.fromOffset(42,42);close.Position=UDim2.new(1,-56,0,14);close.BackgroundColor3=Color3.fromRGB(58,42,67);close.TextColor3=Color3.new(1,1,1);close.Parent=panel;round(close,10)
local notice=label(panel,'',13,UDim2.fromOffset(18,68),UDim2.new(1,-36,0,28),Color3.fromRGB(139,233,181))
local installation=Instance.new('Frame');installation.Name='Installation';installation.Position=notice.Position;installation.Size=notice.Size;installation.BackgroundColor3=Color3.fromRGB(29,76,74);installation.BorderSizePixel=0;installation.Visible=false;installation.ZIndex=10;installation.Parent=panel;round(installation,8)
local installText=label(installation,'',13,UDim2.fromOffset(8,0),UDim2.new(1,-16,1,-3),Color3.fromRGB(242,215,158));installText.ZIndex=11
local installFill=Instance.new('Frame');installFill.Name='Progress';installFill.Size=UDim2.new(0,0,0,3);installFill.Position=UDim2.new(0,0,1,-3);installFill.BackgroundColor3=Color3.fromRGB(237,188,101);installFill.BorderSizePixel=0;installFill.ZIndex=11;installFill.Parent=installation
local installToken=0
local function install(toolId)
 installToken+=1;local token=installToken;installation.Visible=true;installText.Text='УСТАНОВКА: '..C.Tool(toolId).Name;installFill.Size=UDim2.new(0,0,0,3)
 Tween:Create(installFill,TweenInfo.new(1.1,Enum.EasingStyle.Quad),{Size=UDim2.new(1,0,0,3)}):Play()
 task.delay(1.1,function()if token==installToken then installText.Text='ГОТОВО · КОМПЛЕКТ УСТАНОВЛЕН';Audio.Play('upgrade')end end)
 task.delay(1.9,function()if token==installToken then installation.Visible=false end end)
end
local tabs=Instance.new('Frame');tabs.Name='Tabs';tabs.BackgroundTransparency=1;tabs.Position=UDim2.fromOffset(12,100);tabs.Size=UDim2.new(1,-24,0,38);tabs.Parent=panel
local scroll=Instance.new('ScrollingFrame');scroll.Name='Items';scroll.Position=UDim2.fromOffset(12,148);scroll.Size=UDim2.new(1,-24,1,-160);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=5;scroll.ScrollBarImageColor3=Color3.fromRGB(78,169,216);scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.Parent=panel
local layout=Instance.new('UIGridLayout');layout.CellPadding=UDim2.fromOffset(12,12);layout.CellSize=UDim2.new(.5,-8,0,290);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local tabNames={'ИНСТРУМЕНТЫ','УЛУЧШЕНИЯ','ТАЧКА','КОНВЕЙЕР'}
local buttons={}local account local active=1 local render local compact=false
local shortLayout=false;local tileMode=true
local focused='shovel';local hero;local heroKey;local heroCamera;local heroCenter;local heroDistance;local heroSpin=0;local wide=false;local refreshHero
local function money(n)local s=tostring(n);repeat local new,count=s:gsub('^(%-?%d+)(%d%d%d)','%1 %2');s=new until count==0;return s end
local lastRequest=-math.huge
local function send(action,item)if os.clock()-lastRequest<C.ActionInterval+.03 then return end;lastRequest=os.clock();remote:FireServer({OwnerUserId=P.UserId,Action=action,Item=item})end
local function button(parent,name,text,position,size,enabled,callback)
 local b=Instance.new('TextButton');b.Name=name;b.Text=text;b.TextSize=14;b.TextWrapped=true;b.Font=Enum.Font.GothamBold;b.Position=position;b.Size=size;b.BackgroundColor3=enabled and Color3.fromRGB(42,150,98)or Color3.fromRGB(57,64,82);b.TextColor3=enabled and Color3.fromRGB(237,255,246)or Color3.fromRGB(170,178,195);b.AutoButtonColor=enabled;b.Parent=parent;round(b,9)
 if enabled then b.Activated:Connect(function()Audio.Play('click');callback()end)end;return b
end
local function icon(parent,kind,id,large)
 local v=Instance.new('ViewportFrame');v.Name='ItemIcon';v.Size=large and UDim2.new(1,-20,.49,0)or UDim2.fromOffset(compact and 72 or 108,compact and 88 or 112);v.Position=large and UDim2.new(0,10,.1,0)or UDim2.fromOffset(9,10);v.BackgroundColor3=Color3.fromRGB(11,17,29);v.LightColor=Color3.fromRGB(225,236,255);v.Ambient=Color3.fromRGB(155,169,195);v.Parent=parent;round(v,10)
 local world=Instance.new('WorldModel');world.Parent=v
 if kind=='tool'then local model=Art.Build(id);if tileMode and not large and model:GetAttribute('TwoHanded')then for _,p in model:GetChildren()do if p:IsA('BasePart')then p.CFrame=CFrame.Angles(0,0,-.7)*p.CFrame end end end;if id=='crystal'or id=='abyss'or id=='gravity'or id=='reality'then for _,p in model:GetChildren()do if p:IsA('BasePart')then p.CFrame=CFrame.Angles(0,math.pi,0)*p.CFrame end end end;model.Parent=world
 elseif kind=='cart'then require(R.SandPrototypeCartAppearance).Build().Parent=world
 else
  local length=4+tonumber(id)*.35
  local function part(size,pos,color)local p=Instance.new('Part');p.Size=size;p.Position=pos;p.Color=color;p.Anchored=true;p.Parent=world end
  part(Vector3.new(3,.25,length),Vector3.new(),Color3.fromRGB(46,57,71));for i=1,4 do part(Vector3.new(2.8,.12,.15),Vector3.new(0,.2,(i-2.5)*length/4),Color3.fromRGB(53+tonumber(id)*25,151,194))end
  for _,x in {-1.6,1.6}do part(Vector3.new(.17,.5,length),Vector3.new(x,0,0),Color3.fromRGB(189,151,84))end
 end
 for _,p in world:GetDescendants()do if p:IsA('BasePart')then p.Anchored=true;p.CanCollide=false end end
 local cf,size=world:GetBoundingBox();local cam=Instance.new('Camera');local d=math.max(size.X,size.Y,size.Z)*1.55;cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(d*.7,d*.35,d),cf.Position);cam.FieldOfView=36;cam.Parent=v;v.CurrentCamera=cam
 if large then heroCamera=cam;heroCenter=cf.Position;heroDistance=d end
 return v
end
hero=Instance.new('Frame');hero.Name='Showcase';hero.Position=UDim2.fromOffset(12,154);hero.Size=UDim2.new(0,252,1,-166);hero.BackgroundColor3=Color3.fromRGB(13,25,35);hero.Visible=false;hero.BorderSizePixel=0;hero.Parent=panel;round(hero,14);stroke(hero,Color3.fromRGB(53,92,104))
refreshHero=function()
 if not account then return end
 P:SetAttribute('ForgePreviewTool',focused);P:SetAttribute('ForgePreviewLevel',account.ToolLevels[focused]or 0)
 if not hero.Visible then return end
 local key=focused..':'..active..':'..account.ToolLevels[focused]..':'..account.CartLevel..':'..account.ConveyorSections..':'..account.Coins
 if key==heroKey then return end;heroKey=key;heroCamera=nil
 for _,v in hero:GetChildren()do if v:IsA('GuiObject')then v:Destroy()end end
 local tool=C.Tool(focused);local level=account.ToolLevels[focused];local color=tool.Color
 label(hero,'КОЛЛЕКЦИЯ / '..(active==3 and 'ТРАНСПОРТ'or active==4 and 'АВТОМАТИЗАЦИЯ'or 'ИНСТРУМЕНТЫ'),11,UDim2.fromOffset(15,13),UDim2.new(1,-30,0,21),Color3.fromRGB(125,176,182))
 icon(hero,active==3 and 'cart'or active==4 and 'section'or 'tool',active==3 and 'cart'or active==4 and '4'or focused,true)
 local name=active==3 and 'Тачка для песка'or active==4 and 'Конвейерная линия'or tool.Name
 label(hero,name,23,UDim2.new(0,16,.62,0),UDim2.new(1,-32,0,55),active<3 and color or Color3.fromRGB(123,224,225))
 local stats=active==3 and('УРОВЕНЬ '..account.CartLevel..' / 2\nВместимость: '..money(C.Cart.Capacity[math.max(1,account.CartLevel)]))or active==4 and('СЕКЦИИ '..account.ConveyorSections..' / 4\nУровень '..account.ConveyorLevel..' / 5')or('УРОВЕНЬ '..level..' / 5\nВместимость: '..money(tool.Capacity[math.max(1,level)]))
 if active==2 and level>0 and level<5 then stats='ВМЕСТИМОСТЬ\n'..money(tool.Capacity[level])..'  →  '..money(tool.Capacity[level+1])end
 if active==1 then local current=C.Tool(account.SelectedTool);local currentLevel=account.ToolLevels[account.SelectedTool]
  stats='ВМЕСТИМОСТЬ: '..money(current.Capacity[currentLevel])..'  →  '..money(tool.Capacity[math.max(1,level)])..'\nДОБЫЧА: '..C.Yield(account)..'  →  '..math.max(1,math.floor(tool.Yield*(1+.15*(math.max(1,level)-1))))..' за раскоп'
 end
 label(hero,stats,14,UDim2.new(0,16,.78,0),UDim2.new(1,-32,0,45),Color3.fromRGB(218,231,226))
 local stripe=Instance.new('Frame');stripe.Size=UDim2.new(1,-32,0,3);stripe.Position=UDim2.new(0,16,.94,0);stripe.BackgroundColor3=color;stripe.BorderSizePixel=0;stripe.Parent=hero
end
Run.RenderStepped:Connect(function(dt)if shade.Visible and hero.Visible and heroCamera then heroSpin+=dt*.32;local d=heroDistance;heroCamera.CFrame=CFrame.lookAt(heroCenter+Vector3.new(math.sin(heroSpin)*d*.4,d*.23,d),heroCenter)end end)
local function card(name,description,kind,id,color)
 local row=Instance.new('Frame');row.Name='Item_'..id;row.BackgroundColor3=Color3.new(1,1,1);row.BorderSizePixel=0;row.Parent=scroll;round(row,14)
 local outline=stroke(row,color or Color3.fromRGB(72,87,118));outline.Transparency=.65
 local gradient=Instance.new('UIGradient');gradient.Color=ColorSequence.new(Color3.fromRGB(36,55,65),Color3.fromRGB(20,33,43));gradient.Rotation=35;gradient.Parent=row
 local rail=Instance.new('Frame');rail.Size=UDim2.new(1,-28,0,2);rail.Position=UDim2.fromOffset(14,0);rail.BackgroundColor3=color or Color3.fromRGB(71,145,159);rail.BorderSizePixel=0;rail.Parent=row
 row.MouseEnter:Connect(function()Tween:Create(outline,TweenInfo.new(.15),{Transparency=.12}):Play()end);row.MouseLeave:Connect(function()Tween:Create(outline,TweenInfo.new(.15),{Transparency=.65}):Play()end)
 local art=icon(row,kind,id)
 if tileMode then
  art.Position=UDim2.fromOffset(10,25);art.Size=UDim2.new(1,-20,0,110);art.BackgroundColor3=Color3.fromRGB(13,24,35)
  label(row,kind=='tool'and 'ИНСТРУМЕНТ' or kind=='cart'and 'ТРАНСПОРТ'or 'ЛИНИЯ ДОБЫЧИ',10,UDim2.fromOffset(14,7),UDim2.new(1,-60,0,15),Color3.fromRGB(132,159,170))
 else art.Position=UDim2.fromOffset(10,10);art.Size=UDim2.fromOffset(106,116)end
 if kind=='tool'then local inspect=Instance.new('TextButton');inspect.Name='Inspect';inspect.Size=UDim2.fromScale(1,1);inspect.BackgroundTransparency=1;inspect.Text='';inspect.Parent=art;inspect.Activated:Connect(function()focused=id;heroKey=nil;render();Audio.Play('click')end)end
 local left=tileMode and 14 or 130
 label(row,name,tileMode and 17 or 18,UDim2.fromOffset(left,tileMode and 143 or 10),UDim2.new(1,-left-12,0,27),color)
 label(row,description,tileMode and 12 or 13,UDim2.fromOffset(left,tileMode and 174 or 42),UDim2.new(1,-left-12,0,tileMode and 55 or 54),Color3.fromRGB(183,203,216))
 return row,left
end
local function action(row,text,enabled,fn,name)
 return button(row,name or 'Purchase',text,tileMode and UDim2.new(0,12,1,-52)or UDim2.new(1,-238,1,-50),tileMode and UDim2.new(1,-24,0,44)or UDim2.fromOffset(226,44),enabled,fn)
end
local function lock(row)
 local shackle=Instance.new('Frame');shackle.Size=UDim2.fromOffset(15,15);shackle.Position=UDim2.new(1,-36,0,12);shackle.BackgroundTransparency=1;shackle.Parent=row;round(shackle,7);stroke(shackle,Color3.fromRGB(155,161,180),3)
 local body=Instance.new('Frame');body.Size=UDim2.fromOffset(22,17);body.Position=UDim2.new(1,-40,0,22);body.BackgroundColor3=Color3.fromRGB(133,140,159);body.Parent=row;round(body,4)
end
render=function()
 if not account then return end
 refreshHero()
 local old=scroll.CanvasPosition
 for _,v in scroll:GetChildren()do if v:IsA('Frame')then v:Destroy()end end
 for i,b in buttons do b.BackgroundColor3=i==active and Color3.fromRGB(220,181,109)or Color3.fromRGB(32,48,61);b.TextColor3=i==active and Color3.fromRGB(26,36,40)or Color3.fromRGB(191,209,215)end
 balance.Text=money(account.Coins)..'  ◈'
 if active==1 or active==2 then
  for _,t in C.Tools do
   local level=account.ToolLevels[t.Id];local owned=level>0;local unlocked=account.Unlocks[t.Id]
   local desc
   if active==1 then desc=owned and string.format('КУПЛЕНО · уровень %d/5\nВместимость: %s',level,money(t.Capacity[level]))or unlocked and('Вместимость: '..money(t.Capacity[1])..'\nПокупка: '..money(t.Price)..' монет')or('ЗАКРЫТО · заработайте всего '..money(t.Unlock)..'\nПрогресс: '..money(account.TotalCoinsEarned)..' / '..money(t.Unlock))
   else desc=not owned and 'Сначала купите этот инструмент во вкладке «Инструменты»'or level==5 and('МАКСИМАЛЬНЫЙ УРОВЕНЬ\nВместимость: '..money(t.Capacity[level]))or string.format('Уровень %d/5 · вместимость %s → %s\nУлучшение: %s монет',level,money(t.Capacity[level]),money(t.Capacity[level+1]),money(t.Upgrades[level+1]))end
   if active==1 and focused==t.Id then
    local nextLevel=math.max(1,level);local nextYield=math.max(1,math.floor(t.Yield*(1+.15*(nextLevel-1))))
    desc='Вместимость '..money(C.Capacity(account))..' → '..money(t.Capacity[nextLevel])..'\nДобыча '..C.Yield(account)..' → '..nextYield..' за раскоп\n'..(owned and('Куплено · уровень '..level..'/5')or unlocked and 'Доступен к покупке'or('Нужен общий заработок '..money(t.Unlock)))
   end
   local row,left=card(t.Name,desc,'tool',t.Id,unlocked and t.Color or Color3.fromRGB(131,142,165))
   if not unlocked then lock(row);if active==1 then local bar=Instance.new('Frame');bar.Position=UDim2.new(0,14,1,-60);bar.Size=UDim2.new(1,-28,0,4);bar.BackgroundColor3=Color3.fromRGB(62,77,92);bar.BorderSizePixel=0;bar.Parent=row;local fill=Instance.new('Frame');fill.Size=UDim2.new(math.clamp(account.TotalCoinsEarned/math.max(1,t.Unlock),0,1),0,1,0);fill.BackgroundColor3=t.Color;fill.BorderSizePixel=0;fill.Parent=bar end end
   if active==2 then for j=1,5 do local tick=Instance.new('Frame');tick.Size=UDim2.fromOffset(tileMode and 24 or 24,4);tick.Position=UDim2.new(0,left+(j-1)*(tileMode and 30 or 29),1,tileMode and -60 or -15);tick.BorderSizePixel=0;tick.BackgroundColor3=j<=level and t.Color or Color3.fromRGB(63,73,94);tick.Parent=row end end
   if active==1 then
    if owned then local selected=account.SelectedTool==t.Id;action(row,selected and 'ВЫБРАН' or 'ВЫБРАТЬ',not selected,function()send('equipTool',t.Id)end)
    else action(row,unlocked and('КУПИТЬ · '..money(t.Price))or 'ЗАКРЫТО',unlocked and account.Coins>=t.Price,function()send('buyTool',t.Id)end)end
   else local cost=owned and t.Upgrades[level+1];action(row,not owned and 'НЕ КУПЛЕН' or level==5 and 'МАКСИМУМ' or('УЛУЧШИТЬ · '..money(cost)),owned and level<5 and account.Coins>=cost,function()send('upgradeTool',t.Id)end)end
  end
 elseif active==3 then
  local level=account.CartLevel;local desc=level==0 and('Вместимость: 500\n'..(account.Unlocks.cart and 'Доступна покупка за 2 000 монет' or 'Нужна Обычная лопата уровня 2'))or string.format('Уровень %d/2 · песок %s / %s\n%s',level,money(account.CartCells),money(C.CartCapacity(account)),level==1 and 'Следующее улучшение: 1 500 песка · 5 000 монет' or 'Усиленная тачка · максимальный уровень')
  local row=card('Тачка для песка',desc,'cart','cart',Color3.fromRGB(255,191,92))
  action(row,level==0 and 'КУПИТЬ · 2 000' or level==1 and 'УЛУЧШИТЬ · 5 000' or 'МАКСИМУМ',level==0 and account.Unlocks.cart and account.Coins>=2000 or level==1 and account.Coins>=5000,function()send(level==0 and 'buyCart' or 'upgradeCart')end)
  if level>0 then local r=card('Использование тачки','Включена: песок идёт только в тачку.\nОтключена: песок идёт в выбранный инструмент.','cart','toggle',Color3.fromRGB(98,211,205));action(r,account.CartEnabled and 'ОТКЛЮЧИТЬ ТАЧКУ' or 'ВКЛЮЧИТЬ ТАЧКУ',true,function()send('toggleCart')end,'ToggleCart')end
 else
  for i,s in C.Sections do
   local owned=account.ConveyorSections>=i;local unlocked=account.Unlocks['section'..i];local nextSection=account.ConveyorSections+1==i
   local row=card('Секция конвейера '..i,owned and 'ПОСТРОЕНА · часть транспортной линии'or('Цена '..money(s.Price)..' · общий заработок '..money(s.Unlock)..'\n'..(not nextSection and 'Сначала постройте предыдущую секцию' or not unlocked and('Заработано: '..money(account.TotalCoinsEarned)..' / '..money(s.Unlock))or 'Доступна постройка')),'section',tostring(i),Color3.fromRGB(82,197,235))
   action(row,owned and 'ПОСТРОЕНО' or 'ПОСТРОИТЬ · '..money(s.Price),not owned and nextSection and unlocked and account.Coins>=s.Price,function()send('buySection',tostring(i))end)
  end
  local level=account.ConveyorLevel;local descriptions={'Ручная загрузка песка','Лента перевозит быстрее','Ещё больше скорость перевозки','Автоматическая добыча песка','Автоматическая добыча вдвое быстрее'}
  local desc=level==0 and 'Сначала купите все четыре секции'or('Уровень '..level..'/5 · '..descriptions[level]..'\n'..(level<5 and('Далее: '..descriptions[level+1])or 'Максимальный уровень'))
  local row=card('Развитие конвейера',desc,'section','4',Color3.fromRGB(183,124,255));local cost=C.Conveyor.UpgradePrice[level+1]
  action(row,level==0 and 'НУЖНЫ 4 СЕКЦИИ'or level==5 and 'МАКСИМУМ'or('УЛУЧШИТЬ · '..money(cost)),level>0 and level<5 and account.Coins>=cost,function()send('upgradeConveyor')end)
 end
 task.defer(function()scroll.CanvasPosition=old end)
end
for i,name in tabNames do local b=button(tabs,'Tab'..i,name,UDim2.new((i-1)/4,3,0,0),UDim2.new(.25,-6,1,0),true,function()active=i;scroll.CanvasPosition=Vector2.zero;render()end);b.TextScaled=true;local cap=Instance.new('UITextSizeConstraint');cap.MaxTextSize=15;cap.MinTextSize=9;cap.Parent=b;buttons[i]=b end
local function hide()if shade.Visible then Audio.Play('close')end;shade.Visible=false;P:SetAttribute('ForgePreviewTool',nil);P:SetAttribute('ForgePreviewLevel',nil)end
close.Activated:Connect(hide)
Input.InputBegan:Connect(function(input,processed)if input.KeyCode==Enum.KeyCode.Escape and shade.Visible then hide()end end)
local function resize()
 compact=panel.AbsoluteSize.X<600;local short=panel.AbsoluteSize.Y<360;shortLayout=short;tileMode=not short
 wide=panel.AbsoluteSize.X>=880 and panel.AbsoluteSize.Y>=500;hero.Visible=wide;heroKey=nil
 title.TextSize=compact and 18 or short and 18 or 23;balance.TextSize=short and 17 or 21
 title.Position=UDim2.fromOffset(18,short and 6 or 10);title.Size=UDim2.new(1,-80,0,short and 24 or 28)
 balance.Position=UDim2.fromOffset(12,short and 16 or 22);balance.Size=UDim2.new(1,-24,0,27)
 notice.Position=UDim2.fromOffset(18,short and 51 or 68);notice.Size=UDim2.new(1,-36,0,short and 24 or 28)
 tabs.Position=UDim2.fromOffset(12,short and 82 or 100);tabs.Size=UDim2.new(1,-24,0,44)
 scroll.Position=UDim2.fromOffset(12,short and 134 or 154);scroll.Size=UDim2.new(1,-24,1,short and -146 or -166)
 close.Size=UDim2.fromOffset(44,44)
 subtitle.Visible=not short and not compact
 title.Size=UDim2.new(1,compact and -80 or -340,0,28)
 wallet.Position=UDim2.new(1,short and -270 or -320,0,8);wallet.Size=UDim2.fromOffset(short and 198 or 248,short and 43 or 56);walletCaption.Visible=true
 if compact then
  wallet.Position=UDim2.fromOffset(18,40);wallet.Size=UDim2.new(1,-94,0,33);walletCaption.Visible=false;balance.Position=UDim2.fromOffset(10,2);balance.Size=UDim2.new(1,-20,0,29);balance.TextSize=17
  notice.Position=UDim2.fromOffset(18,78);tabs.Position=UDim2.fromOffset(12,114);scroll.Position=UDim2.fromOffset(12,166);scroll.Size=UDim2.new(1,-24,1,-178)
 end
 layout.CellSize=tileMode and UDim2.new(scroll.AbsoluteSize.X>=540 and .5 or 1,-8,0,290)or UDim2.new(1,-8,0,148)
 if wide then scroll.Position=UDim2.fromOffset(276,154);scroll.Size=UDim2.new(1,-288,1,-166)end
 layout.CellSize=tileMode and UDim2.new((wide and panel.AbsoluteSize.X-288 or panel.AbsoluteSize.X-24)>=540 and .5 or 1,-8,0,290)or UDim2.new(1,-8,0,148)
 installation.Position=notice.Position;installation.Size=notice.Size
 if shade.Visible then render()end
end
panel:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize)
remote.OnClientEvent:Connect(function(message)
 if type(message)~='table'or message.Kind~='state'then return end
 if account then local milestone;for key,value in message.Account.Unlocks do if value and not account.Unlocks[key]then if key=='cart'then milestone='ОТКРЫТА ТАЧКА!'elseif not milestone then milestone='НОВЫЙ ПРЕДМЕТ ОТКРЫТ!'end end end;if milestone then unlockToast(milestone)end end
 local oldAccount=account
 local installed
 if oldAccount then for id,level in message.Account.ToolLevels do if level>(oldAccount.ToolLevels[id]or 0)then installed=id;break end end end
 local previousSelection=account and account.SelectedTool;account=message.Account
 if installed then P:SetAttribute('ForgeInstallTool',installed);P:SetAttribute('ForgeInstallSerial',(P:GetAttribute('ForgeInstallSerial')or 0)+1);notice.Text='КОМПЛЕКТ УСТАНОВЛЕН · '..C.Tool(installed).Name end
 if previousSelection~=account.SelectedTool then focused=account.SelectedTool;heroKey=nil end
 if message.Message then notice.Text=message.Message;notice.TextColor3=message.Message:find('Недостаточно')and Color3.fromRGB(255,164,133)or Color3.fromRGB(139,233,181) end
 if message.Open then shade.Visible=true;resize();panel.BackgroundTransparency=.3;Tween:Create(panel,TweenInfo.new(.2),{BackgroundTransparency=0}):Play()end
 if shade.Visible then render()end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.5 then return end;elapsed=0;if not shade.Visible then return end
 local r=P.Character and P.Character:FindFirstChild('HumanoidRootPart');local m=P:FindFirstChild('SandPrototypeMountain');local plot=m and m.Value and m.Value.Parent;local machine=plot and plot.SandPrototypeStation:FindFirstChild('UpgradeMachine')
 if not r or not machine or(r.Position-machine.PrimaryPart.Position).Magnitude>17 then hide()end
end)