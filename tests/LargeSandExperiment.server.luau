-- Temporary, non-persistent Studio experiment. Never ship this fixture.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local main=game.ServerScriptService.SandPrototype
assert(not main.Enabled and main:GetAttribute("PersistenceEnabled")==false,"Disable production bootstrap and persistence")
workspace:SetAttribute("PersonalPlotsEnabled",false)
local mountain=workspace.SandPrototype
mountain:SetAttribute("PersistenceStatus","Loading")
local cells=mountain.Cells
local template=cells:FindFirstChildWhichIsA("BasePart"):Clone()
local origin=cells.Cell_0_0_0.Position
cells:ClearAllChildren()
local initial={schemaVersion=3,initialCells=1771,revision=0,dugCells=0,movedCells=0,cells={},outbound={},imports={},collection={},artifact=false,accessMode="Closed"}
local batch=Instance.new("Folder")
local inBatch=0
local function flush()
	batch.Parent=cells
	for _,part in batch:GetChildren()do part.Parent=cells end
	batch:Destroy()task.wait()
	batch=Instance.new("Folder")inBatch=0
end
for y=0,10 do for x=-(10-y),10-y do for z=-(10-y),10-y do
	local part=template:Clone()
	part.Name=string.format("Cell_%d_%d_%d",x,y,z)
	part:SetAttribute("GridX",x)part:SetAttribute("GridY",y)part:SetAttribute("GridZ",z)
	part.Position=origin+Vector3.new(x*2,y*2,z*2)
	part.Parent=batch
	table.insert(initial.cells,{x=x,y=y,z=z})inBatch+=1
	if inBatch>=200 then flush()end
end end end
if inBatch>0 then flush()else batch:Destroy()end
template:Destroy()
local station=workspace.SandPrototypeStation
station.SellPad.Position=Vector3.new(14,0.5,-6)
station.UpgradePad.Position=Vector3.new(22,0.5,-6)
local players=game:GetService("Players")
while #players:GetPlayers()==0 do task.wait(0.1)end
local player=players:GetPlayers()[1]
initial.ownerId=tostring(player.UserId)
initial.account={CapacityLevel=0,CapacityCells=20,CarriedCells=0,Coins=0,XP=0}
-- This experiment tests production mining/physics only, not the 165-cell save schema.
local function validate(raw)
	assert(raw.initialCells==1771 and #raw.cells+raw.dugCells==1771,"Experiment mass mismatch")
	return raw
end
local world=require(game.ServerScriptService.SandPrototypeWorld).Start({owner=player,mountain=mountain,station=station,
	persistent=false,key="unused_experiment",initial=initial,validate=validate})
assert(world)
game:BindToClose(function()world.Close()end)
local remote=Instance.new("RemoteEvent")remote.Name="LargeSandQA"remote.Parent=game.ReplicatedStorage
workspace:SetAttribute("LargeSandReady",true)
