local C = {Version=1, MaxMoney=1000000000000, MaxSand=600000, SellPrice=1, ActionInterval=.25, ShopDistance=12}
C.BalanceVersion=2 -- Account/schema version intentionally stays compatible.
C.Tools = {
 {Id='shovel',Name='Обычная лопата',Price=0,Unlock=0,Color=Color3.fromRGB(173,147,102),Effect='dust'},
 {Id='turbo',Name='Турболопата',Price=1500,Unlock=1000,Color=Color3.fromRGB(49,211,255),Effect='wave'},
 {Id='crystal',Name='Кристальная лапа',Price=5000,Unlock=4000,Color=Color3.fromRGB(178,97,255),Effect='crystal'},
 {Id='vortex',Name='Вихрекоп',Price=15000,Unlock=12000,Color=Color3.fromRGB(103,242,216),Effect='vortex'},
 {Id='lava',Name='Лавовая пасть',Price=45000,Unlock=35000,Color=Color3.fromRGB(255,105,38),Effect='lava'},
 {Id='gravity',Name='Гравитационное ядро',Price=120000,Unlock=100000,Color=Color3.fromRGB(77,149,255),Effect='gravity'},
 {Id='abyss',Name='Рука Бездны',Price=350000,Unlock=300000,Color=Color3.fromRGB(114,49,207),Effect='portal'},
 {Id='reality',Name='Разлом Реальности',Price=1000000,Unlock=850000,Color=Color3.fromRGB(255,94,215),Effect='rift'},
}
C.ById={}
local yields={{1,2,3,4,5},{6,7,8,9,10},{11,12,13,14,15},{16,18,20,22,24},{25,28,31,34,37},{38,42,46,50,54},{55,60,65,70,75},{76,82,88,94,100}}
local capacities={{20,40,60,80,100},{60,80,100,120,140},{80,110,140,170,200},{100,140,180,220,260},{120,160,200,240,280},{140,180,220,260,300},{160,200,240,280,320},{180,220,260,300,340}}
local upgrades={{0,100,250,500,900},{0,350,650,1000,1500},{0,1000,1800,2800,4000},{0,3000,5000,8000,12000},{0,8000,14000,22000,32000},{0,22000,36000,55000,80000},{0,60000,100000,150000,220000},{0,150000,250000,400000,600000}}
for i,t in C.Tools do t.Index=i;t.Yields=yields[i];t.Yield=yields[i][1];t.Capacity=capacities[i];t.Upgrades=upgrades[i];C.ById[t.Id]=t end
C.Cart={Price=350,UpgradePrice=1250,Capacity={500,1500}}
C.Sections={{Price=500,Unlock=1500},{Price=1000,Unlock=2500},{Price=1500,Unlock=4000},{Price=2000,Unlock=6000}}
C.Conveyor={UpgradePrice={0,2000,4000,10000,20000},Speed={5,8,12,18,26},MaxBatch=1000000}
function C.Tool(id) return C.ById[id] end
function C.Capacity(a) local t=C.ById[a.SelectedTool]; return t.Capacity[a.ToolLevels[t.Id]] end
function C.CartCapacity(a,level)
 local tier=1
 for i,t in C.Tools do if a.ToolLevels and(a.ToolLevels[t.Id]or 0)>0 then tier=math.max(tier,i)end end
 -- Highest owned tier: switching tools must never invalidate stored cargo.
 return math.floor((C.Cart.Capacity[level or a.CartLevel]or 0)*(1+(tier-1)*.5))
end
-- Physical shovels use visible-surface reach; advanced tools keep centre reach.
function C.Reach(id)return(id==nil or id=='shovel'or id=='turbo')and 5 or 24 end
function C.YieldAt(t,level)return t.Yields[math.clamp(level,1,5)]end
function C.Yield(a) local t=C.ById[a.SelectedTool];return C.YieldAt(t,a.ToolLevels[t.Id])end
return C

