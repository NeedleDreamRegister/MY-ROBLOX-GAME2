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