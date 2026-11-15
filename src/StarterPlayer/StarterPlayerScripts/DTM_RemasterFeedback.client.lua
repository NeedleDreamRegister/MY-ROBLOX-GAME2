-- Presentation only. Listens to accepted server transactions; never requests or awards anything.
local Players = game:GetService('Players')
local R = game:GetService('ReplicatedStorage')
local Run = game:GetService('RunService')
local Tween = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local P = Players.LocalPlayer
local C = require(R:WaitForChild('UpgradeConfig'))
local Audio = require(R:WaitForChild('GameAudio'))
local rng = Random.new()
local gold = Color3.fromRGB(235,198,122)
local cream = Color3.fromRGB(247,237,211)
local teal = Color3.fromRGB(106,222,201)
local playerGui=P:WaitForChild('PlayerGui')
local generation=(playerGui:GetAttribute('DTMRemasterGeneration')or 0)+1
playerGui:SetAttribute('DTMRemasterGeneration',generation)
-- Tell an existing controller to disconnect before replacing its owned roots.
-- Yield once so this also works when Workspace.SignalBehavior is Deferred.
local oldRoots={}
for _,parent in {playerGui,workspace} do for _,root in parent:GetChildren()do
 if root.Name=='DTM_RemasterRewards' or root.Name=='DTM_RemasterLocalFX' then
  table.insert(oldRoots,root);local stop=root:FindFirstChild('Shutdown')
  if stop and stop:IsA('BindableEvent')then stop:Fire()end
 end
end end
if #oldRoots>0 then Run.Heartbeat:Wait();for _,root in oldRoots do if root.Parent then root:Destroy()end end end
if playerGui:GetAttribute('DTMRemasterGeneration')~=generation then return end
local fx = Instance.new('Folder'); fx.Name='DTM_RemasterLocalFX'; fx.Parent=workspace
local gui = Instance.new('ScreenGui'); gui.Name='DTM_RemasterRewards'; gui.ResetOnSpawn=false; gui.DisplayOrder=48; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=playerGui
-- Cosmetic diagnostics only: incremented by the same confirmed presentation handlers.
-- They are never consulted by gameplay, requests, or presentation conditions.
gui:SetAttribute('SaleCount',0);gui:SetAttribute('DeliveryCount',0);gui:SetAttribute('UpgradeCount',0)
gui:SetAttribute('WalletBaselineSeeded',false)
local alive=true
local connections,external={},{}
local function cleanup()
 if not alive then return end;alive=false
 for _,c in connections do c:Disconnect()end;table.clear(connections)
 for object in external do object:Destroy()end;table.clear(external)
 gui:Destroy();fx:Destroy()
end
local function listen(signal, fn)
 local c=signal:Connect(function(...)
  if not alive then return end
  if not script.Parent or not gui.Parent or not fx.Parent then cleanup();return end
  fn(...)
 end);table.insert(connections,c);return c
end
local function after(seconds,fn)task.delay(seconds,function()if alive and script.Parent and gui.Parent and fx.Parent then fn()end end)end
local function defer(fn)task.defer(function()if alive and script.Parent and gui.Parent and fx.Parent then fn()end end)end
for _,root in {gui,fx}do
 local stop=Instance.new('BindableEvent');stop.Name='Shutdown';stop.Parent=root
 table.insert(connections,stop.Event:Connect(cleanup))
 table.insert(connections,root.Destroying:Connect(cleanup))
end
table.insert(connections,script.Destroying:Connect(cleanup))
local function round(p,n) local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,n);c.Parent=p end
local function text(parent,name,value,size,color,pos,dims)
 local t=Instance.new('TextLabel');t.Name=name;t.BackgroundTransparency=1;t.Text=value;t.TextColor3=color;t.Font=Enum.Font.GothamMedium;t.TextSize=size;t.TextXAlignment=Enum.TextXAlignment.Left;t.Position=pos;t.Size=dims;t.TextWrapped=true;t.Parent=parent;return t
end
local function tween(p,time,props) local t=Tween:Create(p,TweenInfo.new(time,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props);t:Play();return t end
local function pretty(n) local s=tostring(math.floor(n));repeat local v,k=s:gsub('^(%d+)(%d%d%d)','%1 %2');s=v until k==0;return s end
local function part(name,size)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Transparency=1;p.Parent=fx;return p
end
local function emitter(parent,name,life,speed,size,alpha)
 local e=Instance.new('ParticleEmitter');e.Name=name;e.Texture='rbxasset://textures/particles/smoke_main.dds';e.Enabled=false;e.Rate=0;e.Lifetime=life;e.Speed=speed;e.EmissionDirection=Enum.NormalId.Top;e.SpreadAngle=Vector2.new(60,60);e.Drag=2;e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-65,65);e.LightInfluence=1;e.Size=size;e.Transparency=alpha;e.Parent=parent;return e
end
local fade=NumberSequence.new({NumberSequenceKeypoint.new(0,.06),NumberSequenceKeypoint.new(.6,.18),NumberSequenceKeypoint.new(1,1)})
local dustFade=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.13,.76),NumberSequenceKeypoint.new(.5,.9),NumberSequenceKeypoint.new(1,1)})
local slots={}
-- Fixed pool: 10 anchors, 40 disabled emitters, 50 reusable grains, 10 contact disks.
for i=1,10 do
 local a=part('SandContact_'..i,Vector3.new(.12,.12,.12))
 local e={anchor=a,untilAt=0,chips={}}
 e.grain=emitter(a,'FineSand',NumberRange.new(.28,.55),NumberRange.new(4,8),NumberSequence.new(.085,.018),fade);e.grain.Acceleration=Vector3.new(0,-24,0)
 e.dust=emitter(a,'SoftContactDust',NumberRange.new(.48,.8),NumberRange.new(.5,1.6),NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(.45,1.6),NumberSequenceKeypoint.new(1,2.4)}),dustFade);e.dust.Acceleration=Vector3.new(.5,.4,.2)
 e.settle=emitter(a,'SettlingSand',NumberRange.new(.5,.85),NumberRange.new(1.5,3),NumberSequence.new(.12,.025),fade);e.settle.Acceleration=Vector3.new(0,-8,0)
 e.accent=emitter(a,'ToolMinerals',NumberRange.new(.2,.42),NumberRange.new(2,4),NumberSequence.new(.065,0),fade);e.accent.Acceleration=Vector3.new(0,-14,0)
 e.disk=part('ContactResponse',Vector3.new(.025,1,1));e.disk.Shape=Enum.PartType.Cylinder;e.disk.Material=Enum.Material.Sand
 for j=1,5 do local p=part('SandGrain',Vector3.new(.1,.1,.1));p.Material=Enum.Material.Sand;e.chips[j]={p=p} end
 slots[i]=e
end
local surfaces={workspace.Terrain}
local function watchCells(d) if d:IsA('Folder') and d.Name=='Cells' and d.Parent and d.Parent.Name=='SandPrototype' then table.insert(surfaces,d) end end
for _,d in workspace:GetDescendants() do watchCells(d) end
listen(workspace.DescendantAdded,watchCells)
local function contact(position,uid)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 local valid={};for i=#surfaces,1,-1 do if surfaces[i].Parent then table.insert(valid,surfaces[i])else table.remove(surfaces,i)end end
 params.FilterDescendantsInstances=valid;params.IgnoreWater=true
 local actor=Players:GetPlayerByUserId(uid);local root=actor and actor.Character and actor.Character:FindFirstChild('HumanoidRootPart')
 local origins={position+Vector3.new(0,7,0),position+Vector3.new(5,3,0),position+Vector3.new(-5,3,0)}
 if root then table.insert(origins,1,root.Position+Vector3.new(0,1.3,0)) end
 for _,origin in origins do
  local delta=position-origin
  if delta.Magnitude>.1 then
   local hit=workspace:Raycast(origin,delta.Unit*(delta.Magnitude+6),params)
   if hit and (hit.Position-position).Magnitude<7 and hit.Material==Enum.Material.Sand then return hit end
  end
 end
end
local lastDig={}
local digCount,digTime=0,0
local digBadge=Instance.new('Frame');digBadge.Name='MiningReceipt';digBadge.AnchorPoint=Vector2.new(.5,.5);digBadge.Position=UDim2.fromScale(.5,.62);digBadge.Size=UDim2.fromOffset(148,35);digBadge.BackgroundColor3=Color3.fromRGB(23,47,46);digBadge.BackgroundTransparency=.12;digBadge.Visible=false;digBadge.Parent=gui;round(digBadge,12)
local digLabel=text(digBadge,'SandAmount','',13,cream,UDim2.fromOffset(8,0),UDim2.new(1,-16,1,0));digLabel.TextXAlignment=Enum.TextXAlignment.Center
listen(R:WaitForChild('SandPrototypeDig').OnClientEvent,function(position,color,uid,found,_,collapse,toolId,amount)
 if collapse or typeof(position)~='Vector3' or typeof(color)~='Color3' or type(uid)~='number' then return end
 local now=os.clock()
 if uid==P.UserId then
  if now-digTime>.65 then digCount=0 end;digTime=now;digCount+=type(amount)=='number' and math.max(1,amount) or 1
  if toolId~='conveyor' or found then digLabel.Text=found and 'НАЙДЕН ОСКОЛОК' or ('Песок  + '..pretty(digCount));digBadge.Visible=true end
 end
 local cam=workspace.CurrentCamera
 if toolId=='conveyor' or not cam or (cam.CFrame.Position-position).Magnitude>82 or now-(lastDig[uid] or -100)<.065 then return end
 lastDig[uid]=now
 local hit=contact(position,uid);if not hit then return end
 local e;for _,slot in slots do if slot.untilAt<=now then e=slot;break end end;if not e then return end
 local def=C.Tool(toolId) or C.Tools[1];local power=math.clamp((def.Index-1)/7,0,1);local scale=1+power*.6
 local n=hit.Normal;local tangent=n:Cross(math.abs(n.Y)<.94 and Vector3.yAxis or Vector3.xAxis).Unit;local side=tangent:Cross(n).Unit
 local pos=hit.Position+n*.07;e.anchor.CFrame=CFrame.fromMatrix(pos,tangent,n,tangent:Cross(n));e.untilAt=now+1
 local sand=color:Lerp(Color3.fromRGB(233,210,164),.15)
 for _,layer in {e.grain,e.dust,e.settle} do layer.Color=ColorSequence.new(sand) end
 e.accent.Color=ColorSequence.new(sand:Lerp(def.Color,.25))
 e.grain:Emit(math.floor(13*scale));e.dust:Emit(4+math.floor(power*2));e.settle:Emit(8);if power>.1 then e.accent:Emit(3+math.floor(power*3)) end
 e.disk.Color=sand;e.disk.CFrame=CFrame.fromMatrix(hit.Position+n*.015,n,tangent,n:Cross(tangent));e.disk.Size=Vector3.new(.022,.35,.35);e.disk.Transparency=.7
 tween(e.disk,.22,{Size=Vector3.new(.015,1.5*scale,1.5*scale),Transparency=1})
 for j,g in e.chips do
  local s=rng:NextNumber(.065,.16)*scale;g.p.Size=Vector3.new(s,s*.6,s*.85);g.p.Color=sand;g.p.Transparency=.05;g.start=pos;g.at=now;g.life=rng:NextNumber(.28,.46)
  g.velocity=n*rng:NextNumber(3,6)+tangent*rng:NextNumber(-3,3)+side*rng:NextNumber(-3,3);g.spin=Vector3.new(rng:NextNumber(-7,7),rng:NextNumber(-7,7),rng:NextNumber(-7,7))
 end
 Audio.Dig(hit.Position,toolId,hit.Material)
end)

-- One animated reward card plus a bounded queue, coalesced by reward type.
local card=Instance.new('CanvasGroup');card.Name='RewardCard';card.BackgroundTransparency=1;card.BorderSizePixel=0;card.Size=UDim2.fromOffset(320,94);card.GroupTransparency=1;card.Visible=false;card.Parent=gui;round(card,16)
-- A gradient on a CanvasGroup tints its entire rendered composite, including text.
-- Isolate the gradient on a background sibling below all reward content.
local cardBackground=Instance.new('Frame');cardBackground.Name='Background';cardBackground.Size=UDim2.fromScale(1,1);cardBackground.BackgroundColor3=Color3.new(1,1,1);cardBackground.BorderSizePixel=0;cardBackground.ZIndex=0;cardBackground.Parent=card;round(cardBackground,16)
local border=Instance.new('UIStroke');border.Color=gold;border.Transparency=.48;border.Parent=cardBackground
local grad=Instance.new('UIGradient');grad.Color=ColorSequence.new(Color3.fromRGB(36,67,62),Color3.fromRGB(20,39,41));grad.Rotation=28;grad.Parent=cardBackground
local icon=Instance.new('Frame');icon.Name='CoinIcon';icon.Size=UDim2.fromOffset(42,42);icon.Position=UDim2.fromOffset(15,23);icon.BackgroundColor3=gold;icon.BorderSizePixel=0;icon.Parent=card;round(icon,21)
local coinRim=Instance.new('UIStroke');coinRim.Color=Color3.fromRGB(255,229,166);coinRim.Thickness=2;coinRim.Parent=icon
local symbol=text(icon,'CoinStamp','◆',21,Color3.fromRGB(105,76,35),UDim2.fromOffset(0,0),UDim2.fromScale(1,1));symbol.TextXAlignment=Enum.TextXAlignment.Center
local heading=text(card,'Heading','ПЕСОК ПРОДАН',10,gold,UDim2.fromOffset(72,14),UDim2.new(1,-85,0,18))
local value=text(card,'Value','',24,cream,UDim2.fromOffset(72,33),UDim2.new(1,-85,0,30));value.Font=Enum.Font.GothamBold
local detail=text(card,'Detail','Монеты зачислены',10,Color3.fromRGB(168,199,187),UDim2.fromOffset(72,66),UDim2.new(1,-85,0,16))
local cardBase=UDim2.new(1,-18,0,118)
local function resize()
 local camera=workspace.CurrentCamera;if not camera then return end
 local vp=camera.ViewportSize;local compact=vp.X<650
 card.AnchorPoint=compact and Vector2.new(.5,0) or Vector2.new(1,0)
 local availableHeight=gui.AbsoluteSize.Y>0 and gui.AbsoluteSize.Y or vp.Y
 local compactTop=math.min(math.max(218,vp.Y*.30),math.max(8,availableHeight-104))
 cardBase=compact and UDim2.new(.5,0,0,compactTop) or UDim2.new(1,-18,0,118)
 card.Size=UDim2.fromOffset(math.min(320,vp.X-28),94);card.Position=cardBase
end
if workspace.CurrentCamera then listen(workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),resize) end
listen(workspace:GetPropertyChangedSignal('CurrentCamera'),resize);resize()
local queue={};local queueRunning=false
local function shopVisible()
 local ui=playerGui:FindFirstChild('UpgradeUI');local modal=ui and ui:FindFirstChild('Modal')
 return modal~=nil and modal.Visible
end
local function storeQueued(entry,front)
 for _,pending in queue do if pending.kind==entry.kind and entry.kind=='sale' then pending.amount+=entry.amount;return end end
 if #queue>=4 then if entry.kind=='sale' then for _,pending in queue do if pending.amount then pending.amount+=entry.amount;return end end end;table.remove(queue,1) end
 if front then table.insert(queue,1,entry)else table.insert(queue,entry)end
end
local function waitForCard(seconds)
 local finish=os.clock()+seconds
 repeat
  if not alive or not script.Parent or not gui.Parent or shopVisible()then return false end
  task.wait(.05)
 until os.clock()>=finish
 return alive and script.Parent~=nil and gui.Parent~=nil and not shopVisible()
end
local function enqueue(entry)
 if not alive or(entry.kind=='upgrade'and shopVisible())then return end
 storeQueued(entry)
 if queueRunning then return end;queueRunning=true
 task.spawn(function()
  while alive and script.Parent and #queue>0 and gui.Parent do
   if shopVisible()then
    card.Visible=false
    for i=#queue,1,-1 do if queue[i].kind=='upgrade'then table.remove(queue,i)end end
    task.wait(.1);continue
   end
   local item=table.remove(queue,1);card.Visible=true;card.Position=cardBase+UDim2.fromOffset(20,0);card.GroupTransparency=1
   heading.Text=item.title;value.Text=item.amount and ('+ '..pretty(item.amount)..'  ◈') or item.value;detail.Text=item.detail or 'Монеты зачислены на баланс'
   icon.BackgroundColor3=item.color or gold;symbol.Text=item.kind=='sale' and '◆' or '✓';value.TextSize=item.kind=='sale' and 24 or 18
   tween(card,.28,{Position=cardBase,GroupTransparency=0});icon.Rotation=-14;tween(icon,.45,{Rotation=0})
   local complete=waitForCard(item.kind=='sale'and 1.65 or 2.2)
   if not alive or not script.Parent or not gui.Parent then break end
   if complete then tween(card,.3,{Position=cardBase+UDim2.fromOffset(0,-9),GroupTransparency=1});complete=waitForCard(.32)end
   if not alive or not script.Parent or not gui.Parent then break end
   card.Visible=false
   if not complete and item.kind=='sale'then storeQueued(item,true)end
  end
  queueRunning=false
 end)
end

-- Reusable sale anchor: no moving/colliding parts are added to the machine.
local saleAnchor=part('SaleCelebration',Vector3.new(.1,.1,.1))
local saleGold=emitter(saleAnchor,'GoldMotes',NumberRange.new(.5,.9),NumberRange.new(2.5,5),NumberSequence.new(.16,0),fade);saleGold.Color=ColorSequence.new(gold);saleGold.Acceleration=Vector3.new(0,-7,0);saleGold.LightEmission=.25
local saleDust=emitter(saleAnchor,'WarmSaleGlow',NumberRange.new(.4,.75),NumberRange.new(.2,1),NumberSequence.new(.7,1.5),dustFade);saleDust.Color=ColorSequence.new(gold)
local saleLight=Instance.new('PointLight');saleLight.Color=gold;saleLight.Range=10;saleLight.Brightness=0;saleLight.Shadows=false;saleLight.Parent=saleAnchor
local lastSaleFX=-100
local function station()
 local ref=P:FindFirstChild('SandPrototypeMountain');local mountain=ref and ref.Value;local plot=mountain and mountain.Parent;return plot and plot:FindFirstChild('SandPrototypeStation')
end
local function sale(amount,delivery)
 if not alive then return end
 gui:SetAttribute('SaleCount',gui:GetAttribute('SaleCount')+1)
 if delivery then gui:SetAttribute('DeliveryCount',gui:GetAttribute('DeliveryCount')+1)end
 gui:SetAttribute('LastSaleAmount',amount)
 enqueue({kind='sale',title=delivery and 'ДОСТАВКА ЗАВЕРШЕНА' or 'ПЕСОК ПРОДАН',amount=amount})
 local now=os.clock();if now-lastSaleFX<.35 then return end;lastSaleFX=now
 Audio.Play(delivery and 'delivery' or 'sale')
 local s=station();local pad=s and s:FindFirstChild('SellPad');if not pad then return end
 local cam=workspace.CurrentCamera;if not cam or(cam.CFrame.Position-pad.Position).Magnitude>90 then return end
 saleAnchor.Position=pad.Position+Vector3.new(0,1.8,0);saleGold:Emit(22);saleDust:Emit(5);saleLight.Brightness=1.5;tween(saleLight,.65,{Brightness=0})
 local outline=Instance.new('Highlight');outline.Name='SaleConfirmation';outline.Adornee=pad;outline.DepthMode=Enum.HighlightDepthMode.Occluded;outline.FillColor=gold;outline.OutlineColor=gold;outline.FillTransparency=.78;outline.OutlineTransparency=.25;outline.Parent=fx;tween(outline,.7,{FillTransparency=1,OutlineTransparency=1});Debris:AddItem(outline,.75)
end

local upgradeToken=0
local function uiSparks(target,color,large)
 if not alive or not target or not target:IsA('GuiObject') or not target.Visible then return end
 local size=target.AbsoluteSize;local origin=target.AbsolutePosition;local inset=game:GetService('GuiService'):GetGuiInset()
 for i=1,large and 14 or 8 do
  local dot=Instance.new('Frame');dot.Name='UpgradeSpark';dot.BorderSizePixel=0;dot.Size=UDim2.fromOffset(i%3==0 and 5 or 3,i%3==0 and 5 or 3);dot.BackgroundColor3=color;dot.Rotation=45
  local x=rng:NextNumber(8,math.max(9,size.X-8));local y=rng:NextNumber(5,math.max(6,size.Y-5));dot.Position=UDim2.fromOffset(origin.X+x,origin.Y-inset.Y+y);dot.Parent=gui
  tween(dot,.7,{Position=dot.Position+UDim2.fromOffset(rng:NextNumber(-20,20),rng:NextNumber(-40,-12)),BackgroundTransparency=1,Rotation=125});Debris:AddItem(dot,.75)
 end
end
local function emphasizeTool(id,color)
 after(.18,function()
  local tool=P.Character and P.Character:FindFirstChildOfClass('Tool')
  if tool and tool:GetAttribute('UpgradeToolId')==id then local h=Instance.new('Highlight');h.Name='NewEquipment';h.Adornee=tool;h.FillColor=color;h.OutlineColor=cream;h.FillTransparency=.55;h.OutlineTransparency=.15;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=fx;tween(h,1.25,{FillTransparency=1,OutlineTransparency=1});Debris:AddItem(h,1.3)end
 end)
end
local function upgrade(id,oldLevel,newLevel,large,title,stats)
 if not alive then return end
 gui:SetAttribute('UpgradeCount',gui:GetAttribute('UpgradeCount')+1)
 gui:SetAttribute('LastUpgradeId',id)
 gui:SetAttribute('LastUpgradeLevel',newLevel)
 upgradeToken+=1;local token=upgradeToken
 local def=C.Tool(id);local color=def and def.Color:Lerp(gold,.35) or teal
 enqueue({kind='upgrade',title=title or (large and 'НОВЫЙ ИНСТРУМЕНТ' or 'УЛУЧШЕНИЕ УСТАНОВЛЕНО'),value=def and def.Name or id,detail=stats or ('Уровень '..oldLevel..' → '..newLevel..' / 5'),color=color})
 Audio.Play(large and 'buy' or 'upgrade')
 local ui=P.PlayerGui:FindFirstChild('UpgradeUI');local modal=ui and ui:FindFirstChild('Modal');local panel=modal and modal:FindFirstChild('Shop')
 if not panel or not modal.Visible then if def then emphasizeTool(id,color)end;return end
 local notice=panel:FindFirstChild('RemasterConfirmation')
 if not notice then
  notice=Instance.new('Frame');notice.Name='RemasterConfirmation';notice.Size=UDim2.new(1,-36,0,30);notice.BackgroundColor3=Color3.fromRGB(33,77,66);notice.ZIndex=20;notice.BorderSizePixel=0;notice.Parent=panel;round(notice,9)
  local cap=text(notice,'Level','',12,cream,UDim2.fromOffset(10,0),UDim2.new(1,-20,1,0));cap.ZIndex=21
  local line=Instance.new('Frame');line.Name='Calibrate';line.Size=UDim2.fromOffset(0,2);line.Position=UDim2.new(0,0,1,-2);line.BackgroundColor3=gold;line.BorderSizePixel=0;line.ZIndex=22;line.Parent=notice
 end
 external[notice]=true
 local compact=panel.AbsoluteSize.X<600;notice.Position=UDim2.fromOffset(18,compact and 78 or panel.AbsoluteSize.Y<360 and 51 or 68);notice.Visible=true;notice.BackgroundTransparency=.15
 notice.Level.Text=(large and 'НОВОЕ ОБОРУДОВАНИЕ  ·  ' or 'КАЛИБРОВКА  ·  ')..tostring(oldLevel)..' → '..tostring(newLevel)
 notice.Calibrate.Size=UDim2.fromOffset(0,2);tween(notice.Calibrate,.6,{Size=UDim2.new(1,0,0,2)});uiSparks(notice,color,large)
 after(.45,function()if token==upgradeToken and notice.Parent then tween(notice.Level,.13,{TextTransparency=1})end end)
 after(.6,function()if token==upgradeToken and notice.Parent then notice.Level.Text=stats or ('ГОТОВО  ·  УРОВЕНЬ '..newLevel..' / 5');notice.Level.TextTransparency=1;tween(notice.Level,.18,{TextTransparency=0});uiSparks(notice,gold,false)end end)
 after(2,function()if token==upgradeToken and notice.Parent then notice.Visible=false end end)
 defer(function()
  local items=panel:FindFirstChild('Items');local row=items and items:FindFirstChild('Item_'..id)
  if row then local h=Instance.new('UIStroke');h.Name='PurchaseConfirmation';h.Color=color;h.Thickness=2;h.Transparency=.1;h.Parent=row;tween(h,1.1,{Transparency=1});Debris:AddItem(h,1.15);uiSparks(row,color,large) end
 end)
 if def then emphasizeTool(id,color) end
end

-- Account is an atomic validated server snapshot, unlike individual attribute replication.
-- Copy the fields we compare: test callers may reuse a table and real networking serializes it.
local previous
-- Initial Economy.Init attribute publication can precede UpgradeService.Attach.
-- A returning player may therefore sell before this listener receives any Account.
-- Seed wallet fields only after persistence is ready and all replicated fields agree;
-- unknown ToolLevels must never be interpreted as newly purchased saved equipment.
local readyStatuses={Saved=true,Saving=true,Dirty=true,SessionOnly=true}
local function seedWalletBaseline()
 if previous then return end
 local state=P:FindFirstChild('SandPrototypeState');local ref=P:FindFirstChild('SandPrototypeMountain');local mountain=ref and ref.Value
 if not state or not mountain or not readyStatuses[mountain:GetAttribute('PersistenceStatus')] then return end
 local a=state:GetAttributes()
 if a.ProgressionVersion~=1 then return end
 for _,key in {'Coins','TotalCoinsEarned','CarriedCells','CartCells','ConveyorSand','InventoryCells','XP','CartLevel','ToolLevel','ConveyorSections','ConveyorLevel'}do
  local n=a[key];if type(n)~='number' or n<0 or n%1~=0 then return end
 end
 if a.InventoryCells~=a.CarriedCells+a.CartCells or a.TotalCoinsEarned<a.Coins or a.XP<a.InventoryCells+a.ConveyorSand or a.ToolLevel<1 or not C.Tool(a.SelectedTool)then return end
 previous={Coins=a.Coins,TotalCoinsEarned=a.TotalCoinsEarned,CarriedCells=a.CarriedCells,CartCells=a.CartCells,ConveyorSand=a.ConveyorSand,PartialWallet=true}
 gui:SetAttribute('WalletBaselineSeeded',true)
end
local function snapshot(a)
 local s={Coins=a.Coins,TotalCoinsEarned=a.TotalCoinsEarned,CarriedCells=a.CarriedCells or 0,CartCells=a.CartCells or 0,ConveyorSand=a.ConveyorSand or 0,CartLevel=a.CartLevel or 0,ConveyorSections=a.ConveyorSections or 0,ConveyorLevel=a.ConveyorLevel or 0,ToolLevels={}}
 for id,n in a.ToolLevels do s.ToolLevels[id]=n end;return s
end
listen(R:WaitForChild('DTMUpgradeRemote').OnClientEvent,function(m)
 if type(m)~='table' or m.Kind~='state' or type(m.Account)~='table' or type(m.Account.ToolLevels)~='table' or type(m.Account.TotalCoinsEarned)~='number' or type(m.Account.Coins)~='number' then return end
 local a=snapshot(m.Account);local old=previous;previous=a;if not old then return end
 local earned=a.TotalCoinsEarned-old.TotalCoinsEarned
 local inventoryOld=old.CarriedCells+old.CartCells;local inventoryNew=a.CarriedCells+a.CartCells
 if earned>0 and a.Coins>old.Coins then
  if inventoryNew<inventoryOld and(not old.PartialWallet or earned==(inventoryOld-inventoryNew)*C.SellPrice)then sale(earned,false)
  elseif old.ConveyorSand>0 and a.ConveyorSand<old.ConveyorSand and(not old.PartialWallet or earned==(old.ConveyorSand-a.ConveyorSand)*C.SellPrice)then sale(earned,true)end
 end
 if old.PartialWallet then return end -- First full snapshot establishes equipment ownership silently.
 -- Level/ownership deltas are authoritative. Opening, refresh, equip, denied requests produce none.
 local hadUpgrade=false
 for _,def in C.Tools do local before=old.ToolLevels[def.Id] or 0;local after=a.ToolLevels[def.Id] or 0
  if after>before then
   hadUpgrade=true;local beforeCapacity=def.Capacity[math.max(1,before)];local afterCapacity=def.Capacity[after]
   upgrade(def.Id,before,after,before==0,nil,'Вместимость '..pretty(beforeCapacity)..' → '..pretty(afterCapacity));break
  end
 end
 if not hadUpgrade then
  if a.CartLevel>old.CartLevel then upgrade('Тачка',old.CartLevel,a.CartLevel,false,'ТРАНСПОРТ УЛУЧШЕН','Вместимость '..pretty(C.Cart.Capacity[a.CartLevel]))
  elseif a.ConveyorSections>old.ConveyorSections then upgrade('Конвейер',old.ConveyorSections,a.ConveyorSections,false,'СЕКЦИЯ ПОСТРОЕНА','Транспортная линия '..a.ConveyorSections..' / 4')
  elseif a.ConveyorLevel>old.ConveyorLevel then upgrade('Конвейер',old.ConveyorLevel,a.ConveyorLevel,false,'КОНВЕЙЕР УЛУЧШЕН','Уровень '..a.ConveyorLevel..' / 5')end
 end
end)
seedWalletBaseline()
listen(Run.Heartbeat,seedWalletBaseline)

listen(Run.RenderStepped,function()
 if shopVisible()then card.Visible=false end -- Never cover shop tabs/items, even mid-toast.
 local now=os.clock();if digBadge.Visible and now-digTime>.8 then digBadge.Visible=false end
 for _,e in slots do for _,g in e.chips do if g.at then
  local age=now-g.at
  if age>=g.life then g.p.Transparency=1;g.at=nil
  else local p=g.start+g.velocity*age+Vector3.new(0,-18,0)*age*age;g.p.CFrame=CFrame.new(p)*CFrame.Angles(g.spin.X*age,g.spin.Y*age,g.spin.Z*age);g.p.Transparency=.06+.94*(age/g.life)^3 end
 end end end
end)
listen(Players.PlayerRemoving,function(player)lastDig[player.UserId]=nil end)