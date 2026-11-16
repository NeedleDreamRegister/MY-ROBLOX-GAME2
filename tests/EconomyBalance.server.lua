-- Pure shipped transactions, zero starting money. No player profiles/DataStore.
return function()
 local C=require(game.ReplicatedStorage.UpgradeConfig)
 local A=require(game.ServerScriptService.ProgressionAccount)
 local T=require(game.ServerScriptService.UpgradeTransactions)
 local function simulate(maximum)
  local a=A.New();local cells,trips=0,0;local stages={};local firstUpgrade,firstCart
  local function pay(action,item,cost)
   while a.Coins<cost do
    local cargo=a.CarriedCells+a.CartCells
    if cargo>0 and(a.Coins+cargo*C.SellPrice>=cost or T.FreeCapacity(a)==0)then assert(T.Sell(a,true));trips+=1
    else
     local amount=math.min(C.Yield(a),T.FreeCapacity(a));assert(amount>0)
     assert(T.AddSand(a,amount));cells+=1
     assert(cells<=67525,'route exceeds the finite mountain')
     if cells%1000==0 then task.wait()end
    end
   end
   local ok,why=T.Apply(a,action,item);assert(ok,why);assert(A.Validate(a))
  end
  for i,tool in C.Tools do
   if i>1 then pay('buyTool',tool.Id,tool.Price)end
   if i==3 then pay('upgradeCart',nil,C.Cart.UpgradePrice)end
   if i==4 then
    for n,section in C.Sections do pay('buySection',tostring(n),section.Price)end
    if maximum then for level=2,5 do pay('upgradeConveyor',nil,C.Conveyor.UpgradePrice[level])end end
   end
   for level=2,(maximum and 5 or i==1 and 2 or 1)do
    pay('upgradeTool',tool.Id,tool.Upgrades[level])
    if i==1 and level==2 then
     firstUpgrade={cells=cells,trips=trips}
     pay('buyCart',nil,C.Cart.Price);firstCart={cells=cells,trips=trips}
    end
   end
   stages[#stages+1]={tool=tool.Id,cells=cells,trips=trips,yield=C.Yield(a),spent=a.SpentCoins,cart=C.CartCapacity(a)}
  end
  assert(a.Coins+a.SpentCoins==a.TotalCoinsEarned)
  return {cells=cells,trips=trips,spent=a.SpentCoins,firstUpgrade=firstUpgrade,firstCart=firstCart,stages=stages}
 end
 local compatibility=A.New();compatibility.CarriedCells=600000;compatibility.XP=600000
 assert(A.Validate(compatibility),'legacy carried sand was destroyed by capacity reduction')
 local overflow=compatibility.CarriedCells;assert(T.Sell(compatibility,false));assert(compatibility.Coins==overflow)
 for _,tool in C.Tools do for level=2,5 do assert(C.YieldAt(tool,level)>C.YieldAt(tool,level-1),'upgrade has no yield benefit')end end
 local cap=A.New();cap.ToolLevels.reality=1;cap.CartLevel=2;local high=C.CartCapacity(cap)
 cap.SelectedTool='shovel';assert(C.CartCapacity(cap)==high,'equipping a weaker tool shrinks loaded cart')
 return {direct=simulate(false),allUpgrades=simulate(true),legacyOverflowPreserved=true,cartNeverShrinksOnEquip=true,balanceVersion=C.BalanceVersion,productionWrites=0}
end
