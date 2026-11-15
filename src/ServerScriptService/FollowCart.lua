local Run=game:GetService('RunService')
local C=require(game.ReplicatedStorage.UpgradeConfig)
local Cart={}
function Cart.Create(config)
 local owner=config.owner
 local model,state,level,label,load
 local elapsed=0;local closed=false
 local manual
 local function character()
  local ch=owner.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local r=ch and ch:FindFirstChild('HumanoidRootPart')
  if h and r and h.Health>0 then return r,h,ch end
 end
 local function loadState()
  if not model or not state then return end
  local capacity=C.CartCapacity(state);local scale=model:GetScale();local height=(.04+1.1*math.clamp(state.CartCells/math.max(1,capacity),0,1))*scale
  load.Size=Vector3.new(2.9*scale,height,2.45*scale);load.Transparency=state.CartCells==0 and 1 or 0
  load.CFrame=model.PrimaryPart.CFrame*CFrame.new(model:GetAttribute('LoadBottom')*scale+Vector3.new(0,height/2,0))*model:GetAttribute('LoadRotation')
  label.Text=string.format('ПЕСОК %d / %d\n%s',state.CartCells,capacity,model:GetAttribute('Pushing')and 'ВЕЗЁТЕ ТАЧКУ' or model:GetAttribute('ManualParked')and 'ПРИПАРКОВАНА · Q — ВЗЯТЬ' or state.CartEnabled and 'ТАЧКА С ВАМИ' or 'ПРИПАРКОВАНА')
  model:SetAttribute('CartCells',state.CartCells);model:SetAttribute('CartCapacity',capacity);model:SetAttribute('CartEnabled',state.CartEnabled)
 end
 local function build()
  local previous=model and model:GetPivot();if manual then manual.Destroy()manual=nil end;if model then model:Destroy()end
  model=require(game.ReplicatedStorage.SandPrototypeCartAppearance).Build();model.Name='FollowWheelbarrow';model:SetAttribute('OwnerUserId',owner.UserId);model:SetAttribute('FollowCart',true);model:SetAttribute('MovementVersion',12)
  if state.CartLevel==2 then model:ScaleTo(1.25);for _,p in model:GetChildren()do if p:IsA('BasePart')and string.find(p.Name,'Tray')then p.Color=Color3.fromRGB(34,117,130)end end end
  for _,p in model:GetDescendants()do if p:IsA('BasePart')then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end end
  load=model.SandLoad
  local gui=Instance.new('BillboardGui');gui.Name='CartInventory';gui.Size=UDim2.fromOffset(210,44);gui.StudsOffset=Vector3.new(0,2,0);gui.MaxDistance=35;gui.Parent=model.PrimaryPart
  label=Instance.new('TextLabel');label.Name='LoadLabel';label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(21,36,43);label.BackgroundTransparency=.15;label.TextColor3=Color3.fromRGB(239,230,204);label.Font=Enum.Font.GothamMedium;label.TextSize=12;label.Parent=gui;local cr=Instance.new('UICorner');cr.CornerRadius=UDim.new(0,8);cr.Parent=label
  local pad=config.station.WheelbarrowPad
  local point=previous and previous.Position or pad.Position+Vector3.new(4,0,0)
  local params=RaycastParams.new();params.RespectCanCollide=true;params.FilterType=Enum.RaycastFilterType.Exclude
  local excluded={model};for _,p in game.Players:GetPlayers()do if p.Character then table.insert(excluded,p.Character)end end;params.FilterDescendantsInstances=excluded
  local ground=workspace:Raycast(point+Vector3.new(0,8,0),Vector3.new(0,-30,0),params)
  local y=ground and ground.Position.Y or pad.Position.Y+pad.Size.Y/2
  local look=previous and previous.LookVector or Vector3.new(0,0,-1)
  local rotation=CFrame.lookAt(Vector3.zero,Vector3.new(look.X,0,look.Z).Unit)
  local cf=CFrame.new(point.X,y+(model:GetAttribute('GripHeight')or 2.65)*model:GetScale(),point.Z)*rotation
  model:SetAttribute('ManualParked',true)
  model:PivotTo(cf);model.Parent=config.station.Parent;level=state.CartLevel;loadState()
  manual=require(script.Parent.ManualCart).Create(owner,model,config.canMutate)
 end
 local api={}
 function api.Update(a)state=a;if closed or a.CartLevel<1 then return end;if not model or level~=a.CartLevel then build()else loadState()end end
 function api.CanLoad()local r=character();return model~=nil and r~=nil and state and state.CartEnabled and(r.Position-model.PrimaryPart.Position).Magnitude<=24 end
 function api.CanSell(pad)return model~=nil and(model.PrimaryPart.Position-pad.Position).Magnitude<=16 end
 local heartbeat=Run.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<1/30 then return end;local step=elapsed;elapsed=0
  if closed or not model or not state then return end
  if manual then manual.Update(step,state.CartEnabled)end
  loadState()
  local f=owner:FindFirstChild('SandPrototypeState');if f then f:SetAttribute('CartNearby',api.CanLoad())end
 end)
 function api.Destroy()closed=true;heartbeat:Disconnect();if manual then manual.Destroy()end;if model then model:Destroy()end end
 return api
end
return Cart

