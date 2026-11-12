-- Edit-only native .rbxm checkpoint. Returns base64, never publishes or starts scripts.
assert(not game:GetService("RunService"):IsRunning(), "Export only in Edit")
local root=Instance.new("Model")
root.Name="DigMountainCheckpoint"
root:SetAttribute("PlaceId",game.PlaceId)
root:SetAttribute("UniverseId",game.GameId)
root:SetAttribute("CheckpointVersion",1)
local function group(name, instances)
	local folder=Instance.new("Folder")
	folder.Name=name
	folder.Parent=root
	for _,item in instances do
		local clone=item:Clone()
		assert(clone,"Not archivable: "..item:GetFullName())
		clone.Parent=folder
	end
end
local world={}
for _,item in workspace:GetChildren() do
	if not item:IsA("Terrain") and not item:IsA("Camera") then table.insert(world,item) end
end
group("Workspace",world)
group("ServerScriptService",game.ServerScriptService:GetChildren())
group("StarterPlayerScripts",game.StarterPlayer.StarterPlayerScripts:GetChildren())
group("StarterPack",game.StarterPack:GetChildren())
group("ReplicatedStorage",game.ReplicatedStorage:GetChildren())
local serializer=game:GetService("SerializationService")
local data=serializer:SerializeInstancesAsync({root})
local restored=serializer:DeserializeInstancesAsync(data)[1]
assert(#restored.Workspace.SandPrototype.Cells:GetChildren()==165,"Checkpoint lost initial cells")
assert(restored.StarterPack:FindFirstChild("Лопата"):GetAttribute("SandPrototypeTool"),"Checkpoint lost tool tag")
local scripts=0
for _,item in restored:GetDescendants() do if item:IsA("LuaSourceContainer") then scripts+=1 end end
assert(scripts==15,"Unexpected script count")
for _,item in root:GetDescendants() do
	if item:IsA("LuaSourceContainer") then
		local names={}
		local current=item
		while current~=root do table.insert(names,1,current.Name) current=current.Parent end
		local copy=restored
		for _,name in names do copy=copy and copy:FindFirstChild(name) end
		assert(copy and copy.Source==item.Source,"Source mismatch: "..item.Name)
	end
end
assert(restored.ServerScriptService.SandPrototype:GetAttribute("PersistenceEnabled")==true,"Persistence must be restored before checkpoint")
assert(restored.ServerScriptService.SandPrototype.Enabled,"Production bootstrap must be enabled before checkpoint")
local tool=restored.StarterPack:FindFirstChild("Лопата")
assert(tool.Blade:FindFirstChildOfClass("WeldConstraint").Part0==tool.Handle,"Shovel weld reference lost")
assert(restored.ReplicatedStorage.SandPrototypeDig:IsA("RemoteEvent"),"Dig remote missing")
local encoded=buffer.tostring(game:GetService("EncodingService"):Base64Encode(data))
local result={base64=encoded,bytes=buffer.len(data),scripts=scripts,descendants=#restored:GetDescendants()}
root:Destroy()
restored:Destroy()
return result
