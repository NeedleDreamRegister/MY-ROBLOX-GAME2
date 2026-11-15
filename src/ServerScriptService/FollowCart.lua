local Run=game:GetService('RunService')
local C=require(game.ReplicatedStorage.UpgradeConfig)
local Pose=require(game.ReplicatedStorage.CartPose)
local Cart={}
function Cart.Create(config)
 local owner=config.owner
 local model,state,level,label,load
 local elapsed=0;local closed=false
 local function character()
  local ch=owner.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local r=ch and ch:FindFirstChild('HumanoidRootPart')
  if h and r and h.Health>0 then return r,h,ch end
 end
 local function loadState()
  if not model or not state then return end
  local capacity=C.CartCapacity(state);local scale=model:GetScale();local height=(.04+1.1*math.clamp(state.CartCells/math.max(1,capacity),0,1))*scale
  load.Size=Vector3.new(2.9*scale,height,2.45*scale);load.Transparency=state.CartCells==0 and 1 or 0
  load.CFrame=model.PrimaryPart.CFrame*CFrame.new(model:GetAttribute('LoadBottom')*scale+Vector3.new(0,height/2,0))*model:GetAttribute('LoadRotation')
  label.Text=string.format('ПЕСОК %d / %d\n%s',state.CartCells,capacity,state.CartEnabled and 'ТАЧКА С ВАМИ' or 'ПРИПАРКОВАНА')
  model:SetAttribute('CartCells',state.CartCells);model:SetAttribute('CartCapacity',capacity);model:SetAttribute('CartEnabled',state.CartEnabled)
 end
 local function build()
  local previous=model and model:GetPivot();if model then model:Destroy()end
  model=require(game.ReplicatedStorage.SandPrototypeCartAppearance).Build();model.Name='FollowWheelbarrow';model:SetAttribute('OwnerUserId',owner.UserId);model:SetAttribute('FollowCart',true);model:SetAttribute('MovementVersion',12)
  if state.CartLevel==2 then model:ScaleTo(1.25);for _,p in model:GetChildren()do if p:IsA('BasePart')and string.find(p.Name,'Tray')then p.Color=Color3.fromRGB(34,117,130)end end end
  for _,p in model:GetDescendants()do if p:IsA('BasePart')then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end end
  load=model.SandLoad
  local gui=Instance.new('BillboardGui');gui.Name='CartInventory';gui.Size=UDim2.fromOffset(210,44);gui.StudsOffset=Vector3.new(0,2,0);gui.MaxDistance=35;gui.Parent=model.PrimaryPart
  label=Instance.new('TextLabel');label.Name='LoadLabel';label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(21,36,43);label.BackgroundTransparency=.15;label.TextColor3=Color3.fromRGB(239,230,204);label.Font=Enum.Font.GothamMedium;label.TextSize=12;label.Parent=gui;local cr=Instance.new('UICorner');cr.CornerRadius=UDim.new(0,8);cr.Parent=label
  local r,h,ch=character();local cf=r and Pose.Get(r,h,model,ch)or previous or CFrame.new(config.station.WheelbarrowPad.Position+Vector3.new(4,2,0))
  model:PivotTo(cf);model.Parent=config.station.Parent;level=state.CartLevel;loadState()
 end
 local api={}
 function api.Update(a)state=a;if closed or a.CartLevel<1 then return end;if not model or level~=a.CartLevel then build()else loadState()end end
 function api.CanLoad()local r=character();return model~=nil and r~=nil and state and state.CartEnabled and(r.Position-model.PrimaryPart.Position).Magnitude<=24 end
 function api.CanSell(pad)return model~=nil and(model.PrimaryPart.Position-pad.Position).Magnitude<=16 end
 local heartbeat=Run.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
  if closed or not model or not state then return end
  local r,h,ch=character()
  if r and state.CartEnabled and config.canMutate()then model:PivotTo(Pose.Get(r,h,model,ch));loadState()end
  local f=owner:FindFirstChild('SandPrototypeState');if f then f:SetAttribute('CartNearby',api.CanLoad())end
 end)
 function api.Destroy()closed=true;heartbeat:Disconnect();if model then model:Destroy()end end
 return api
end
return Cart

