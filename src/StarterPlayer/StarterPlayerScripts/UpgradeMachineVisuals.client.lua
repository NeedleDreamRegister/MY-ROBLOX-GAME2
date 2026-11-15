local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local R=game.ReplicatedStorage
local P=Players.LocalPlayer
local C=require(R:WaitForChild('UpgradeConfig'))
local Art=require(R:WaitForChild('UpgradeToolAppearance'))
local entries={}
local function sample(e,id)
 if e.sample then e.sample:Destroy()end
 local tool=Art.Build(id);local model=Instance.new('Model');model.Name='SelectedShowpiece'
 for _,child in tool:GetChildren()do child.Parent=model end;tool:Destroy()
 for _,v in model:GetDescendants()do if v:IsA('WeldConstraint')then v:Destroy()end end
 local cf,size=model:GetBoundingBox();local scale=math.min(3.3/math.max(size.Y,.1),1.9/math.max(.1,math.sqrt(size.X^2+size.Z^2)),.9)
 e.parts={};for _,part in model:GetDescendants()do if part:IsA('BasePart')then
  part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Size*=scale
  e.parts[part]=CFrame.new((part.Position-cf.Position)*scale)*part.CFrame.Rotation
 end end
 e.id=id;e.sample=model;model:SetAttribute('DisplayedTool',id);model.Parent=e.machine
end
local function watch(m)
 if not m:IsA('Model')or m.Name~='UpgradeMachine'or entries[m]then return end
 local e={machine=m};entries[m]=e
 task.defer(function()
  local screen=m:WaitForChild('Touchscreen',8);if not screen then entries[m]=nil;return end
  local original=m:FindFirstChild('CrystalShowpiece')
  if original then for _,p in original:GetDescendants()do if p:IsA('BasePart')then p.LocalTransparencyModifier=1 end end end
  local g=screen:WaitForChild('UpgradeDisplay',5);if not g then return end
  local clone=g:Clone();clone.Name='DTMForgeDisplay';clone.Adornee=screen;clone.ResetOnSpawn=false;clone.Enabled=true;clone.Parent=P:WaitForChild('PlayerGui');g.Enabled=false
  e.gui=clone;e.body=m.PrimaryPart
  local tag=m:FindFirstChild('ShowcaseTag');local tg=tag and tag:FindFirstChild('ShowcaseLabel');e.tag=tg and tg:FindFirstChildOfClass('TextLabel')
  e.lights={};for _,p in m:GetDescendants()do if p:IsA('BasePart')and p.Material==Enum.Material.Neon and not(original and p:IsDescendantOf(original))then e.lights[p]=p.Color end end
  local button=clone:FindFirstChild('OpenWorkshop')
  if button then e.connection=button.Activated:Connect(function()
   local root=P.Character and P.Character:FindFirstChild('HumanoidRootPart');local prompt=e.body:FindFirstChild('UpgradePrompt')
   if root and prompt and(root.Position-e.body.Position).Magnitude<=prompt.MaxActivationDistance then prompt:InputHoldBegin();task.delay(prompt.HoldDuration+.08,function()if prompt.Parent then prompt:InputHoldEnd()end end)end
  end)end
  sample(e,'shovel')
 end)
end
for _,v in workspace:GetDescendants()do watch(v)end;workspace.DescendantAdded:Connect(watch)
local elapsed,clock=0,0
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;clock+=dt;if elapsed<1/30 then return end;elapsed=0
 local root=P.Character and P.Character:FindFirstChild('HumanoidRootPart')
 for m,e in entries do
  if not m.Parent then if e.connection then e.connection:Disconnect()end;if e.gui then e.gui:Destroy()end;if e.sample then e.sample:Destroy()end;entries[m]=nil
  elseif e.body and root and(root.Position-e.body.Position).Magnitude<100 then
   local plot=m.Parent and m.Parent.Parent;local owner=plot and Players:GetPlayerByUserId(plot:GetAttribute('OwnerUserId')or 0);local state=owner and owner:FindFirstChild('SandPrototypeState')
   local own=owner==P;local ui=P.PlayerGui:FindFirstChild('UpgradeUI');local open=own and ui and ui:FindFirstChild('Modal')and ui.Modal.Visible
   local id=open and P:GetAttribute('ForgePreviewTool')or state and state:GetAttribute('SelectedTool')or 'shovel';if not C.Tool(id)then id='shovel'end
   if id~=e.id then sample(e,id)end
   local level=open and P:GetAttribute('ForgePreviewLevel')or state and state:GetAttribute('ToolLevel')or 1
   local serial=own and P:GetAttribute('ForgeInstallSerial')or 0
   if e.serial~=serial then if e.serial~=nil and serial and serial>0 then e.installStart=clock end;e.serial=serial end
   local age=e.installStart and clock-e.installStart or 10;local installing=age<1.3
   local pulse=installing and math.sin(age/1.3*math.pi)or 0
   local rotation=clock*.2+(installing and age*4 or 0)
   local center=e.body.Position+Vector3.new(4.4,.15+math.sin(clock*1.4)*.09+pulse*.16,0)
   local cf=CFrame.new(center)*CFrame.Angles(0,rotation,0)
   for part,relative in e.parts or{}do if part.Parent then part.CFrame=cf*relative end end
   for part,color in e.lights do if part.Parent then part.Color=color:Lerp(Color3.fromRGB(255,211,125),pulse*.8)end end
   if e.tag then e.tag.Text=C.Tool(id).Name..'\n'..(installing and 'УСТАНОВКА УЛУЧШЕНИЯ' or 'ВИТРИНА / '..(level==0 and 'НЕ КУПЛЕН' or 'УРОВЕНЬ '..level..' / 5'))end
   local g=e.gui
   if g then
    local name=g:FindFirstChild('SelectedTool');if name then name.Text=installing and 'УСТАНОВКА КОМПЛЕКТА…'or C.Tool(id).Name end
    local stats=g:FindFirstChild('ToolStats');if stats then stats.Text=installing and 'КАЛИБРОВКА  →  ГОТОВО'or string.format('УРОВЕНЬ %d / 5   •   %d ПЕСКА',level,C.Tool(id).Capacity[math.max(1,level)])end
    local scan=g:FindFirstChild('Scanline');if scan then scan.Position=UDim2.fromScale(0,(clock*(installing and 1.4 or .25))%1);scan.BackgroundTransparency=installing and .5 or .85 end
   end
  end
 end
end)
