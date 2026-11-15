local P=game.Players.LocalPlayer
local S=game:GetService('SoundService')
local Input=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local Audio=require(game.ReplicatedStorage:WaitForChild('GameAudio'))
for _,v in S:GetChildren()do if v:IsA('Sound')and(v.Name:find('Ambient_')or v.Name=='DTMBackgroundMusic')then v:Destroy()end end
local old=S:FindFirstChild('Ambient');if old then old.Volume=0 end
local musicGroup=S:FindFirstChild('DTMMusic')or Instance.new('SoundGroup');musicGroup.Name='DTMMusic';musicGroup.Parent=S
local music=Instance.new('Sound');music.Name='DTMBackgroundMusic';music.SoundId='rbxassetid://125032085440264';music.Looped=true;music.Volume=0;music.SoundGroup=musicGroup;music.Parent=S;music:Play();Tween:Create(music,TweenInfo.new(3),{Volume=.11}):Play()
local gui=Instance.new('ScreenGui');gui.Name='DTMAudioControls';gui.ResetOnSpawn=false;gui.DisplayOrder=21;gui.Parent=P:WaitForChild('PlayerGui')
local function toggle(label,x,group,attribute)
 local b=Instance.new('TextButton');b.Name=attribute;b.Size=UDim2.fromOffset(58,44);b.Position=UDim2.new(1,x,0,58);b.BackgroundColor3=Color3.fromRGB(23,49,53);b.TextColor3=Color3.fromRGB(222,233,217);b.Font=Enum.Font.GothamMedium;b.TextSize=10;b.Parent=gui;local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,10);c.Parent=b
 local enabled=true
 local function update()group.Volume=enabled and 1 or 0;P:SetAttribute(attribute,enabled);b.Text=label..'\n'..(enabled and 'ВКЛ' or 'ВЫКЛ')end
 local function change()enabled=not enabled;update()end
 b.Activated:Connect(change);update();return change
end
local change=toggle('МУЗЫКА',-132,musicGroup,'MusicEnabled')
toggle('ЗВУКИ',-70,S:WaitForChild('DTMEffects'),'EffectsEnabled')
Input.InputBegan:Connect(function(i,processed)if not processed and i.KeyCode==Enum.KeyCode.M then change()end end)
local state=P:WaitForChild('SandPrototypeState')
local oldCoins=state:GetAttribute('Coins')or 0
local oldInventory=state:GetAttribute('InventoryCells')or 0
local oldCargo=state:GetAttribute('ConveyorSand')or 0
local pending=false
state.AttributeChanged:Connect(function()
 if pending then return end;pending=true;task.defer(function()
  pending=false;local coins=state:GetAttribute('Coins')or 0;local inventory=state:GetAttribute('InventoryCells')or 0;local cargo=state:GetAttribute('ConveyorSand')or 0
  if coins>oldCoins then if inventory<oldInventory then Audio.Play('sale')elseif oldCargo>0 and cargo==0 then Audio.Play('delivery')end elseif cargo>oldCargo and inventory<oldInventory then Audio.Play('load')end
  oldCoins=coins;oldInventory=inventory;oldCargo=cargo
 end)
end)
local previous
game.ReplicatedStorage:WaitForChild('DTMUpgradeRemote').OnClientEvent:Connect(function(m)
 if type(m)~='table'or m.Kind~='state'then return end
 local a=m.Account
 if m.Open then Audio.Play('open')elseif m.Message then
  local sounds={['Инструмент куплен']='buy',['Улучшение куплено']='upgrade',['Тачка куплена']='buy',['Тачка усилена']='upgrade',['Секция построена']='build',['Конвейер улучшен']='upgrade',['Инструмент выбран']='equip',['Тачка включена']='toggle',['Тачка отключена']='toggle'}
  Audio.Play(sounds[m.Message]or 'denied')
 end
 previous=a
end)
