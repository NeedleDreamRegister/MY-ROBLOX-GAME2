local C=require(script.Parent.UpgradeConfig)
local J={}
function J.Resolve(a,info)
 info=info or {}
 local selected=C.Tool(a.SelectedTool)or C.Tools[1]
 local level=math.clamp(a.ToolLevel or 1,1,5)
 local carried=(a.CarriedCells or 0)+(a.CartCells or 0)
 local active=a.CartEnabled and(a.CartCells or 0)or(a.CarriedCells or 0)
 local capacity=a.CartEnabled and(a.CartCapacity or 500)or(a.ManualCapacity or 20)
 local full=capacity>0 and active>=capacity
 local empty=info.Remaining~=nil and info.Remaining<=0
 local result={Title='Наполните контейнер',Detail='Удерживайте копание · '..tostring(a.MiningYield or 1)..' песка за раскоп',Target='mine',AutoSale=full}
 if empty then
  if carried>0 then
   return {Title='Последний песок добыт',Detail='Продайте оставшийся груз · '..carried..' песка',Target='sale',AutoSale=true}
  elseif(a.ConveyorSand or 0)>0 then
   return {Title='Последняя партия в пути',Detail='На конвейере '..a.ConveyorSand..' · '..math.max(0,(a.ConveyorDeliveryAt or 0)-(info.Now or os.time()))..' сек.',Target=nil,AutoSale=false}
  end
  return {Title='Гора полностью выработана',Detail='Весь доступный песок добыт. Разработка этой горы завершена.',Target=nil,AutoSale=false,Complete=true}
 end
 if a.CartEnabled and a.CartNearby==false then
  result.Title='Вернитесь к тачке';result.Detail='Тачка пока далеко · приблизьтесь к ней';result.Target='cart'
 elseif full then
  result.Title='Контейнер заполнен';result.Detail='Продайте песок и освободите место';result.Target='sale'
 elseif not info.HasTool then
  result.Title='Возьмите инструмент';result.Detail=info.Touch and 'Нажмите на значок инструмента внизу экрана'or 'Клавиша 1 — взять инструмент';result.Target='mine'
 elseif(a.CartLevel or 0)==0 and(a.CapacityLevel or 0)>=1 then
  local afford=(a.Coins or 0)>=C.Cart.Price
  result.Title=afford and 'Доступна ручная тачка'or('На тачку: '..tostring(a.Coins or 0)..' / '..C.Cart.Price)
  result.Detail='Автозагрузка рядом · от '..C.Cart.Capacity[1]..' песка · или улучшите инструмент'
  result.Target=afford and 'shop'or 'mine'
 else
  local nextTool
  if info.ToolLevels then
   for _,t in C.Tools do
    if(info.ToolLevels[t.Id]or 0)==0 and(a.TotalCoinsEarned or 0)>=t.Unlock and(a.Coins or 0)>=t.Price then nextTool=t;break end
   end
  end
  if nextTool then
   result.Title='Доступен новый инструмент';result.Detail=nextTool.Name..' · '..nextTool.Price..' ◈';result.Target='shop';result.ToolId=nextTool.Id
  elseif selected.Upgrades[level+1]and(a.Coins or 0)>=selected.Upgrades[level+1]then
   result.Title='Доступно улучшение';result.Detail=selected.Capacity[level]..' → '..selected.Capacity[level+1]..' песка · '..selected.Upgrades[level+1]..' ◈';result.Target='shop'
  elseif(a.ConveyorSand or 0)>0 then
   result.Title='Песок на конвейере';result.Detail='В пути '..a.ConveyorSand..' · '..math.max(0,(a.ConveyorDeliveryAt or 0)-(info.Now or os.time()))..' сек.'
  end
 end
 return result
end
return J
