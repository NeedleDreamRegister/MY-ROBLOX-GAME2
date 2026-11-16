local C = {Version=1, MaxMoney=1000000000000, MaxSand=600000, SellPrice=1, ActionInterval=.25, ShopDistance=12}
C.Tools = {
 {Id='shovel',Name='Обычная лопата',Price=0,Unlock=0,Color=Color3.fromRGB(173,147,102),Effect='dust',Yield=1,Capacity={20,40,60,80,100},Upgrades={0,100,250,500,900}},
 {Id='turbo',Name='Турболопата',Price=1500,Unlock=1000,Color=Color3.fromRGB(49,211,255),Effect='wave',Yield=3,Capacity={150,200,250,300,350},Upgrades={0,500,1000,1700,2500}},
 {Id='crystal',Name='Кристальная лапа',Price=5000,Unlock=4000,Color=Color3.fromRGB(178,97,255),Effect='crystal',Yield=8,Capacity={500,650,800,1000,1200},Upgrades={0,1800,3200,5500,8500}},
 {Id='vortex',Name='Вихрекоп',Price=15000,Unlock=12000,Color=Color3.fromRGB(103,242,216),Effect='vortex',Yield=20,Capacity={1500,2000,2500,3200,4000},Upgrades={0,5000,8500,14000,22000}},
 {Id='lava',Name='Лавовая пасть',Price=45000,Unlock=35000,Color=Color3.fromRGB(255,105,38),Effect='lava',Yield=50,Capacity={5000,6500,8000,10000,12000},Upgrades={0,15000,26000,42000,65000}},
 {Id='gravity',Name='Гравитационное ядро',Price=120000,Unlock=100000,Color=Color3.fromRGB(77,149,255),Effect='gravity',Yield=120,Capacity={15000,20000,25000,32000,40000},Upgrades={0,40000,70000,110000,170000}},
 {Id='abyss',Name='Рука Бездны',Price=350000,Unlock=300000,Color=Color3.fromRGB(114,49,207),Effect='portal',Yield=300,Capacity={50000,70000,90000,120000,150000},Upgrades={0,120000,210000,330000,500000}},
 {Id='reality',Name='Разлом Реальности',Price=1000000,Unlock=850000,Color=Color3.fromRGB(255,94,215),Effect='rift',Yield=800,Capacity={200000,280000,360000,480000,600000},Upgrades={0,350000,600000,950000,1450000}},
}
C.ById={}
for i,t in C.Tools do t.Index=i C.ById[t.Id]=t end
C.Cart={Price=2000,UpgradePrice=5000,Capacity={500,1500}}
C.Sections={{Price=500,Unlock=1500},{Price=1000,Unlock=2500},{Price=1500,Unlock=4000},{Price=2000,Unlock=6000}}
C.Conveyor={UpgradePrice={0,2000,4000,10000,20000},Speed={5,9,14,14,18},AutoInterval={0,0,0,3,1.5},AutoYield=3,MaxBatch=1000000}
function C.Tool(id) return C.ById[id] end
function C.Capacity(a) local t=C.ById[a.SelectedTool]; return t.Capacity[a.ToolLevels[t.Id]] end
function C.CartCapacity(a) return C.Cart.Capacity[a.CartLevel] or 0 end
-- Physical shovels use visible-surface reach; advanced tools keep centre reach.
function C.Reach(id)return(id==nil or id=='shovel'or id=='turbo')and 5 or 24 end
function C.Yield(a) local t=C.ById[a.SelectedTool]; return math.max(1,math.floor(t.Yield*(1+.15*(a.ToolLevels[t.Id]-1)))) end
return C

