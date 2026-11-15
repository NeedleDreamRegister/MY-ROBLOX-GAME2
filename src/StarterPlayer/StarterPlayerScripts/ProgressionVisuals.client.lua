local R=game.ReplicatedStorage
local C=require(R:WaitForChild('UpgradeConfig'))
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local art=Instance.new('Folder');art.Name='DTMProgressionVisuals';art.Parent=workspace
local tracks,machines={},{}
local function part(name,size,cf,color,material,shape)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.Neon;if shape then p.Shape=shape end;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=art return p
end
local function watch(v)
 if v.Name=='PersonalConveyor'and v:IsA('Model')then tracks[v]={marks={},packets={},count=-1}end
 if v.Name=='UpgradeMachine'and v:IsA('Model')then machines[v]=true end
end
for _,v in workspace:GetDescendants()do watch(v)end;workspace.DescendantAdded:Connect(watch)
local elapsed=0
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;if elapsed<.05 then return end;elapsed=0;local now=workspace:GetServerTimeNow()
 for model,e in tracks do
  if not model.Parent then for _,p in e.packets do p:Destroy()end;tracks[model]=nil
  else
   local count=model:GetAttribute('Sections')or 0
   if count~=e.count then e.count=count;e.marks={};for _,v in model:GetDescendants()do if v.Name=='Mark'and v:IsA('BasePart')then table.insert(e.marks,v)end end end
   local speed=model:GetAttribute('Speed')or 5
   for _,p in e.marks do local cf=p:GetAttribute('TrackFrame');local len=p:GetAttribute('TrackLength');if cf and p.Parent then p.CFrame=cf*CFrame.new(0,.17,len/2-(now*speed+(p:GetAttribute('Phase')or 0))%len)end end
   local cargo=model:GetAttribute('Cargo')or 0
   if cargo>0 then
    local a,b=model:GetAttribute('Start'),model:GetAttribute('Finish')
    if a and b then
     if #e.packets==0 then for i=1,5 do e.packets[i]=part('TransportedSand',Vector3.new(.8,.45,.9),CFrame.new(a),Color3.fromRGB(232,205,151),Enum.Material.Sand)end end
     for i,p in e.packets do local ratio=(now*speed/(b-a).Magnitude+i/5)%1;local pos=a:Lerp(b,ratio)+Vector3.new(0,.4,0);p.CFrame=CFrame.lookAt(pos,pos+(b-a))end
    end
   elseif #e.packets>0 then for _,p in e.packets do p:Destroy()end;e.packets={}end
  end
 end
 for m in machines do if not m.Parent then machines[m]=nil else for _,p in m:GetChildren()do if p.Name=='BlueAccent'or p.Name=='ScreenTopLight'then p.Transparency=.06+.13*(1+math.sin(now*2))/2 end end end end
end)
local live=0
R:WaitForChild('SandPrototypeDig').OnClientEvent:Connect(function(position,_,userId,found,motions,collapse,toolId)
 if collapse or userId==0 or typeof(position)~='Vector3' or live>=20 or(workspace.CurrentCamera.CFrame.Position-position).Magnitude>110 then return end
 local def=C.Tool(toolId);if not def and toolId~='conveyor'then return end
 if toolId=='shovel'then return end
 live+=1;task.delay(.8,function()live-=1 end)
 local color=def and def.Color or Color3.fromRGB(250,183,67)
 local kind=def and def.Effect or 'wave'
 local function fade(p,goal,time)
  local properties={Transparency=1};for k,v in goal do properties[k]=v end;Tween:Create(p,TweenInfo.new(time or .55,Enum.EasingStyle.Quad),properties):Play();Debris:AddItem(p,(time or .55)+.05)
 end
 if kind=='wave'then
  local p=part('EnergyWave',Vector3.new(.08,.7,.7),CFrame.new(position)*CFrame.Angles(0,0,math.pi/2),color,nil,Enum.PartType.Cylinder);p.Transparency=.3;fade(p,{Size=Vector3.new(.04,7,7)},.5)
 elseif kind=='portal'then
  local portal=part('AbyssPortal',Vector3.new(.08,3,3),CFrame.new(position)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(36,13,59),nil,Enum.PartType.Cylinder);fade(portal,{},.75)
  for i=1,5 do local p=part('AbyssFinger',Vector3.new(.23,.35,1.25),CFrame.new(position+Vector3.new((i-3)*.28,0,0)),color);fade(p,{CFrame=p.CFrame+Vector3.new(0,1.1,-.8)},.55)end
 elseif kind=='rift'then
  for i=1,3 do local colors={Color3.fromRGB(69,229,255),Color3.fromRGB(243,94,213),Color3.fromRGB(158,112,255)};local p=part('RealityRift',Vector3.new(.09,2.2,.08),CFrame.new(position)*CFrame.Angles(.2*i,0,.45*i),colors[i]);fade(p,{Size=Vector3.new(.03,4.5,.04)},.65)end
 else
  for i=1,6 do
   local angle=i/6*math.pi*2;local offset=Vector3.new(math.cos(angle),0,math.sin(angle))
   local size=kind=='crystal'and Vector3.new(.3,.8,.3)or Vector3.new(.25,.25,.25)
   local p=part('Mining_'..kind,size,CFrame.new(position+(kind=='gravity'and offset*2 or Vector3.zero)),color,kind=='gravity'and Enum.Material.Sand or Enum.Material.Neon,kind~='crystal'and Enum.PartType.Ball or nil)
   if kind=='crystal'then local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Scale=Vector3.new(.7,1.7,.7);mesh.Parent=p end
   local destination=kind=='gravity'and position or position+offset*(kind=='vortex'and 1 or 2)+Vector3.new(0,kind=='vortex'and i*.35 or 1.1,0)
   fade(p,{Position=destination},.5)
  end
 end
end)

