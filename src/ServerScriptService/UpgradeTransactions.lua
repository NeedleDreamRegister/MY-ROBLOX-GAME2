-- Non-yielding server transactions: the client supplies an action and item ID only.
local C=require(game:GetService('ReplicatedStorage').UpgradeConfig)
local Account=require(script.Parent.ProgressionAccount)
local T={}
local function charge(a,cost)
 if a.Coins<cost then return false,'Недостаточно монет' end
 a.Coins-=cost a.SpentCoins+=cost return true
end
function T.Earn(a,n)
 if type(n)~='number' or n%1~=0 or n<1 or a.TotalCoinsEarned+n>C.MaxMoney then return false end
 a.Coins+=n a.TotalCoinsEarned+=n Account.RefreshUnlocks(a) return true
end
function T.FreeCapacity(a)
 if a.CartEnabled and a.CartLevel>0 then return math.max(0,C.CartCapacity(a)-a.CartCells) end
 return math.max(0,C.Capacity(a)-a.CarriedCells)
end
function T.AddSand(a,n)
 if type(n)~='number' or n%1~=0 or n<1 or n>T.FreeCapacity(a)or a.XP+n>C.MaxMoney then return false end
 if a.CartEnabled and a.CartLevel>0 then a.CartCells+=n else a.CarriedCells+=n end
 a.XP+=n return true
end
function T.Sell(a,cartNearby)
 local amount=a.CarriedCells+(cartNearby and a.CartCells or 0)
 if amount<1 then return false,'Нет песка для продажи' end
 if not T.Earn(a,amount*C.SellPrice) then return false,'Лимит баланса' end
 a.CarriedCells=0 if cartNearby then a.CartCells=0 end return true,amount
end
function T.Apply(a,action,item)
 if type(action)~='string' or (item~=nil and type(item)~='string') then return false,'Неверный запрос' end
 if action=='boardStyle'then
  if item~='dune'and item~='coral'and item~='night'then return false,'Неизвестное оформление доски'end
  a.BoardStyle=item return true,'Оформление доски выбрано'
 elseif action=='buyTool' then
  local t=C.Tool(item) if not t then return false,'Неизвестный инструмент' end
  if a.ToolLevels[item]>0 then return false,'Уже куплено' end
  if not a.Unlocks[item] then return false,'Сначала заработайте '..t.Unlock..' монет' end
  local ok,msg=charge(a,t.Price) if not ok then return false,msg end
  a.ToolLevels[item]=1 a.SelectedTool=item return true,'Инструмент куплен'
 elseif action=='equipTool' then
  if not C.Tool(item) or a.ToolLevels[item]<1 then return false,'Инструмент не куплен' end
  a.SelectedTool=item return true,'Инструмент выбран'
 elseif action=='upgradeTool' then
  local t=C.Tool(item);local level=t and a.ToolLevels[item]
  if not level or level<1 then return false,'Сначала купите инструмент' end
  if level>=5 then return false,'Максимальный уровень' end
  local ok,msg=charge(a,t.Upgrades[level+1]) if not ok then return false,msg end
  a.ToolLevels[item]+=1 Account.RefreshUnlocks(a) return true,'Улучшение куплено'
 elseif action=='buyCart' then
  if a.CartLevel>0 then return false,'Уже куплено' end
  if not a.Unlocks.cart then return false,'Нужна Обычная лопата уровня 2' end
  local ok,msg=charge(a,C.Cart.Price) if not ok then return false,msg end
  a.CartLevel=1 a.CartEnabled=true return true,'Тачка куплена'
 elseif action=='upgradeCart' then
  if a.CartLevel~=1 then return false,'Улучшение недоступно' end
  local ok,msg=charge(a,C.Cart.UpgradePrice) if not ok then return false,msg end
  a.CartLevel=2 return true,'Тачка усилена'
 elseif action=='toggleCart' then
  if a.CartLevel<1 then return false,'Тачка не куплена' end
  a.CartEnabled=not a.CartEnabled return true,a.CartEnabled and 'Тачка включена' or 'Тачка отключена'
 elseif action=='buySection' then
  local section=tonumber(item)
  if not section or section%1~=0 or section~=a.ConveyorSections+1 or not C.Sections[section] then return false,'Секции покупаются по порядку' end
  if not a.Unlocks['section'..section] then return false,'Недостаточно общего заработка' end
  local ok,msg=charge(a,C.Sections[section].Price) if not ok then return false,msg end
  a.ConveyorSections=section if section==4 then a.ConveyorLevel=1 end return true,'Секция построена'
 elseif action=='upgradeConveyor' then
  if a.ConveyorSections~=4 or a.ConveyorLevel>=5 then return false,'Улучшение недоступно' end
  local ok,msg=charge(a,C.Conveyor.UpgradePrice[a.ConveyorLevel+1]) if not ok then return false,msg end
  a.ConveyorLevel+=1 return true,'Конвейер улучшен'
 end
 return false,'Неизвестное действие'
end
function T.LoadConveyor(a,now,travelTime,cartNearby)
 if a.ConveyorSections~=4 or a.ConveyorSand>0 then return false,'Конвейер ещё занят или не собран' end
 local amount=a.CarriedCells+(cartNearby and a.CartCells or 0)
 if amount<1 then return false,'Нет песка' end
 if amount>C.Conveyor.MaxBatch then return false,'Слишком большая партия' end
 a.ConveyorSand=amount a.ConveyorDeliveryAt=now+math.ceil(travelTime)
 a.CarriedCells=0 if cartNearby then a.CartCells=0 end return true,amount
end
function T.Deliver(a,now)
 if a.ConveyorSand<1 or now<a.ConveyorDeliveryAt then return false end
 local amount=a.ConveyorSand
 if not T.Earn(a,amount*C.SellPrice) then return false end
 a.ConveyorSand=0 a.ConveyorDeliveryAt=0 return true,amount
end
return T

