local C=require(game:GetService('ReplicatedStorage'):WaitForChild('UpgradeConfig'))
local A={}
local function int(v,lo,hi) return type(v)=='number' and v==v and v%1==0 and v>=lo and v<=hi end
function A.RefreshUnlocks(a)
 for _,t in C.Tools do if a.TotalCoinsEarned>=t.Unlock then a.Unlocks[t.Id]=true end end
 if a.ToolLevels.shovel>=2 then a.Unlocks.cart=true end
 for i,s in C.Sections do if a.TotalCoinsEarned>=s.Unlock then a.Unlocks['section'..i]=true end end
end
function A.New()
 local a={ProgressionVersion=1,Coins=0,TotalCoinsEarned=0,SpentCoins=0,XP=0,CarriedCells=0,CartCells=0,SelectedTool='shovel',ToolLevels={},Unlocks={},CartLevel=0,CartEnabled=false,ConveyorSections=0,ConveyorLevel=0,ConveyorSand=0,ConveyorDeliveryAt=0,LegacyWide=false,BoardStyle='dune'}
 for _,t in C.Tools do a.ToolLevels[t.Id]=t.Id=='shovel' and 1 or 0 end
 A.RefreshUnlocks(a) return a
end
function A.Migrate(old)
 local a=A.New()
 a.Coins=old.Coins or 0 a.XP=old.XP or 0
 a.CartCells=old.CartCells or 0 a.CarriedCells=math.max(0,(old.CarriedCells or 0)-a.CartCells)
 a.SpentCoins=(old.CapacityLevel or 0)*10+(old.BarrowOwned or 0)*25+(old.ShovelLevel or 0)*20
 a.TotalCoinsEarned=a.Coins+a.SpentCoins
 a.ToolLevels.shovel=(old.CapacityLevel or 0)==1 and 2 or 1
 a.CartLevel=(old.BarrowOwned or 0)==1 and 1 or 0 a.CartEnabled=a.CartLevel>0
 a.LegacyWide=(old.ShovelLevel or 0)==1
 A.RefreshUnlocks(a) return a
end
function A.Validate(raw)
 if type(raw)~='table' then return nil,'missing progression account' end
 if raw.ProgressionVersion~=1 then return nil,'unsupported progression account' end
 local a=A.New()
 for _,k in {'Coins','TotalCoinsEarned','SpentCoins','XP'} do if not int(raw[k],0,C.MaxMoney) then return nil,'invalid '..k end a[k]=raw[k] end
 if a.Coins+a.SpentCoins~=a.TotalCoinsEarned then return nil,'wallet ledger mismatch' end
 if type(raw.ToolLevels)~='table' or type(raw.Unlocks)~='table' then return nil,'missing tool levels/unlocks' end
 for _,t in C.Tools do local n=raw.ToolLevels[t.Id]; if not int(n,t.Id=='shovel' and 1 or 0,5) then return nil,'invalid tool level' end a.ToolLevels[t.Id]=n end
 if not C.ById[raw.SelectedTool] or a.ToolLevels[raw.SelectedTool]<1 then return nil,'selected tool is not owned' end a.SelectedTool=raw.SelectedTool
 for _,k in {'CarriedCells','CartCells','ConveyorSand'} do if not int(raw[k],0,k=='ConveyorSand' and C.Conveyor.MaxBatch or C.MaxSand) then return nil,'invalid '..k end a[k]=raw[k] end
 for _,k in {'CartLevel','ConveyorSections','ConveyorLevel'} do local max=k=='CartLevel' and 2 or k=='ConveyorSections' and 4 or 5; if not int(raw[k],0,max) then return nil,'invalid '..k end a[k]=raw[k] end
 if a.CartCells>C.CartCapacity(a) then return nil,'cart exceeds capacity' end
 if a.ConveyorSections<4 and (a.ConveyorLevel~=0 or a.ConveyorSand>0) then return nil,'incomplete conveyor has active cargo/level' end
 if a.ConveyorSections==4 and a.ConveyorLevel<1 then return nil,'assembled conveyor needs level one' end
 if not int(raw.ConveyorDeliveryAt,0,C.MaxMoney) then return nil,'invalid conveyor delivery time' end a.ConveyorDeliveryAt=raw.ConveyorDeliveryAt
 if (a.ConveyorSand>0 and a.ConveyorDeliveryAt==0)or(a.ConveyorSand==0 and a.ConveyorDeliveryAt~=0)then return nil,'cargo delivery ledger mismatch' end
 if a.CarriedCells+a.CartCells+a.ConveyorSand>a.XP then return nil,'inventory exceeds lifetime sand' end
 if type(raw.CartEnabled)~='boolean' or type(raw.LegacyWide)~='boolean' then return nil,'invalid toggle' end
 a.CartEnabled=raw.CartEnabled and a.CartLevel>0 a.LegacyWide=raw.LegacyWide
 for _,t in C.Tools do local value=raw.Unlocks[t.Id];if value~=nil and type(value)~='boolean' then return nil,'invalid unlock' end a.Unlocks[t.Id]=value==true end
 for _,k in {'cart','section1','section2','section3','section4'} do local v=raw.Unlocks[k];if v~=nil and type(v)~='boolean' then return nil,'invalid unlock' end a.Unlocks[k]=v==true end
 local style=raw.BoardStyle==nil and 'dune'or raw.BoardStyle
 if style~='dune'and style~='coral'and style~='night'then return nil,'invalid board style'end
 a.BoardStyle=style
 A.RefreshUnlocks(a)
 for _,t in C.Tools do if a.ToolLevels[t.Id]>0 and not a.Unlocks[t.Id] then return nil,'owned locked tool' end end
 return a
end
function A.Advances(old,new)
 if new.TotalCoinsEarned<old.TotalCoinsEarned or new.SpentCoins<old.SpentCoins or new.XP<old.XP or new.CartLevel<old.CartLevel or new.ConveyorSections<old.ConveyorSections or new.ConveyorLevel<old.ConveyorLevel then return false end
 for id,level in old.ToolLevels do if new.ToolLevels[id]<level then return false end end
 for id,v in old.Unlocks do if v and not new.Unlocks[id] then return false end end
 return true
end
return A

