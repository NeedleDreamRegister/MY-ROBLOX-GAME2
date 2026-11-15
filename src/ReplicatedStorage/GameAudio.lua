local Audio={}
local S=game:GetService('SoundService')
local Debris=game:GetService('Debris')
local group=S:FindFirstChild('DTMEffects')or Instance.new('SoundGroup');group.Name='DTMEffects';group.Parent=S
local click='rbxassetid://88442833509532';local coin='rbxassetid://135483737426662'
local last={}
local profiles={click={click,.22,1.05},open={click,.3,.8},close={click,.2,.65},equip={click,.3,1.35},toggle={click,.3,1.2},buy={coin,.32,1.15},upgrade={coin,.34,1.38},sale={coin,.38,.95},delivery={coin,.3,1.25},build={click,.45,.65},load={click,.36,.8},denied={click,.28,.48}}
function Audio.Play(kind)
 local data=profiles[kind]or profiles.click;local now=os.clock();if now-(last[kind]or -100)<.12 then return end;last[kind]=now
 local s=Instance.new('Sound');s.Name='DTM_'..kind;s.SoundId=data[1];s.Volume=data[2];s.PlaybackSpeed=data[3];s.SoundGroup=group;s.Parent=S;s:Play();Debris:AddItem(s,3)
 if kind=='upgrade'or kind=='build'then task.delay(.12,function()local n=s:Clone();n.PlaybackSpeed=data[3]*1.2;n.Parent=S;n:Play();Debris:AddItem(n,2)end)end
end
local digPools={
 sand={'rbxassetid://180163752','rbxassetid://180163754'},
 stone={'rbxassetid://9119071703'},metal={click},
}
local function materialKind(material)
 if material==Enum.Material.Metal or material==Enum.Material.DiamondPlate or material==Enum.Material.CorrodedMetal then return 'metal'end
 if material==Enum.Material.Rock or material==Enum.Material.Slate or material==Enum.Material.Basalt or material==Enum.Material.Limestone or material==Enum.Material.Sandstone or material==Enum.Material.Concrete then return 'stone'end
 return 'sand'
end
local function impact(position,kind,material,contact)
 if kind=='conveyor'then return end
 local surface=materialKind(material);local pool=digPools[surface]
 local a=Instance.new('Part');a.Name='DTMDigAudio';a.Size=Vector3.new(.1,.1,.1);a.Position=position;a.Anchored=true;a.Transparency=1;a.CanCollide=false;a.CanTouch=false;a.CanQuery=false;a:SetAttribute('SurfaceSound',surface);a.Parent=workspace
 local s=Instance.new('Sound');s.Name='MaterialImpact';s.SoundId=pool[math.random(1,#pool)];s.Volume=contact and .16 or .26
 s.PlaybackSpeed=(surface=='stone'and 1.6 or surface=='metal'and .68 or kind=='lava'and .78 or 1)+(math.random()-.5)*.14
 s.RollOffMinDistance=6;s.RollOffMaxDistance=48;s.SoundGroup=group;s.Parent=a;s:Play()
 if surface=='stone'then task.delay(.32,function()if s.Parent then game:GetService('TweenService'):Create(s,TweenInfo.new(.15),{Volume=0}):Play()end end)end
 Debris:AddItem(a,1.8)
end
function Audio.Dig(position,kind,material)impact(position,kind,material or Enum.Material.Sand,false)end
function Audio.Contact(position,material)
 local now=os.clock();if now-(last.contact or -100)<.25 then return end;last.contact=now
 impact(position,'shovel',material,true)
end
return Audio
