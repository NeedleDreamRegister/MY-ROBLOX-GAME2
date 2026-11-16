-- Mouse, hold, touch and gamepad share one request path. The server owns mining and money.
local Players=game:GetService('Players');local R=game.ReplicatedStorage;local Input=game:GetService('UserInputService');local Run=game:GetService('RunService')
local P=Players.LocalPlayer;local mouse=P:GetMouse();local Context=require(R:WaitForChild('SandPrototypeClientContext'));local mountain=Context.GetMountain(P);local cells=mountain:WaitForChild('Cells');local remote=R:WaitForChild('SandPrototypeDig')
local bound={}
local function bind(tool)
 if not tool:IsA('Tool')or not tool:GetAttribute('SandPrototypeTool')or bound[tool]then return end;bound[tool]=true
 local connections={};local held=false;local heldInput;local last=-math.huge;local lastHint=-math.huge;local closed=false;local rest=tool.Grip;local cancelSequence=0;local strokeIndex=0
 local gui=Instance.new('ScreenGui');gui.Name='DTM_MobileDig';gui.ResetOnSpawn=false;gui.Parent=P.PlayerGui
 local button=Instance.new('TextButton');button.Name='DigButton';button.Size=UDim2.fromOffset(122,66);button.AnchorPoint=Vector2.new(1,1);button.Position=UDim2.new(1,-24,1,-150);button.Text='КОПАТЬ';button.TextSize=19;button.Font=Enum.Font.GothamBold;button.TextColor3=Color3.fromRGB(248,236,207);button.BackgroundColor3=Color3.fromRGB(36,109,120);button.Parent=gui;local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,18);corner.Parent=button
 local function connect(event,fn)local c=event:Connect(fn);table.insert(connections,c);return c end
 local function equipped()return not closed and tool.Parent==P.Character end
 local function touch()return Input.PreferredInput==Enum.PreferredInput.Touch end
 local function hint(text)if os.clock()-lastHint<1 then return end;lastHint=os.clock();local f=P.PlayerGui:FindFirstChild('SandPrototypeFeedback');local e=f and f:FindFirstChild('ActionHint');if e then e:Fire(text)end end
 local function shopOpen()local ui=P.PlayerGui:FindFirstChild('UpgradeUI');return ui and ui:FindFirstChild('Modal')and ui.Modal.Visible end
 local function cancel()held=false;heldInput=nil;cancelSequence+=1;tool:SetAttribute('DigActiveUntil',0);tool.Grip=rest end
 local function stroke(hit,target)
  local point=hit.Position
  -- Scoop the reachable lower part of a selected face, staying in that cell.
  -- Top surfaces retain their actual point; the ray verifies any lower contact.
  local root=P.Character and P.Character:FindFirstChild('HumanoidRootPart')
  if target and root and (tool:GetAttribute('UpgradeToolId')=='shovel'or tool:GetAttribute('UpgradeToolId')=='turbo')then
   local candidate=point
   if hit.Normal.Y<.5 then
    candidate=Vector3.new(point.X,math.clamp(root.Position.Y-1.5,target.Position.Y-1.8,math.max(point.Y,target.Position.Y-1.8)),point.Z)
   else
    -- On a smooth slope, contact the nearer part of the same selected area.
    -- A far downhill click can otherwise require the hands to stretch through
    -- the legs, even while the player is standing directly on the sand.
    local toward=root.Position-point
    local tangent=toward-hit.Normal*toward:Dot(hit.Normal)
    if tangent.Magnitude>.01 then candidate+=tangent.Unit*math.min(2,tangent.Magnitude)end
   end
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={P.Character}
   local surface=workspace:Raycast(candidate+hit.Normal*2,-hit.Normal*4,params)
   if surface and surface.Instance==hit.Instance and surface.Material==hit.Material and(surface.Position-point).Magnitude<2.5
    and(surface.Position-target.Position).Magnitude<=5 then point=surface.Position end
  end
  strokeIndex+=1;tool:SetAttribute('DigStrokeIndex',strokeIndex)
  tool:SetAttribute('DigStrokeAt',os.clock());tool:SetAttribute('DigAimPosition',point)
  tool:SetAttribute('DigCellPosition',target and target.Position or nil)
  local physical=Context.DigReach(P:FindFirstChild('SandPrototypeState'))<24
  tool:SetAttribute('DigActiveUntil',os.clock()+(physical and .24 or target and .5 or .3))
 end
 local function afterWindup(callback)
  if Context.DigReach(P:FindFirstChild('SandPrototypeState'))>=24 then callback();return end
  local sequence=cancelSequence
  task.delay(.08,function()
   local state=P:FindFirstChild('SandPrototypeState')
   if not equipped()or sequence~=cancelSequence or shopOpen()or(P.Character and P.Character:GetAttribute('MountainSliding'))or(state and state:GetAttribute('PushingCart'))then return end
   callback()
  end)
 end
 local function aim(position)
  local ray=Context.AimRay(mouse,position);if not ray then return end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={P.Character}
  local hit=workspace:Raycast(ray.Origin,ray.Direction*220,params)
  return Context.ResolveHit(P,hit,cells),hit
 end
 local function dig(position)
  if not equipped()or(P.Character and P.Character:GetAttribute('MountainSliding'))or not tool.Enabled or shopOpen()or os.clock()-last<.16 then return end
  local state=P:FindFirstChild('SandPrototypeState');if not state then return end
  if state:GetAttribute('PushingCart')then return end
  local status=mountain:GetAttribute('PersistenceStatus');if status~='SessionOnly'and status~='Saved'and status~='Dirty'and status~='Saving'then hint('Дождитесь загрузки прогресса');return end
  if state:GetAttribute('CartEnabled')and state:GetAttribute('CartNearby')==false then hint('Подкатите тачку ближе к месту копания');return end
  if Context.FreeCapacity(state)<=(state:GetAttribute('PendingCells')or 0)then hint('Контейнер заполнен — продайте песок');return end
  local target,hit=aim(position);if not target or not Context.CanTarget(P,target,cells)then
   local root=P.Character and P.Character:FindFirstChild('HumanoidRootPart')
   if hit and hit.Material~=Enum.Material.Sand and root and(root.Position-hit.Position).Magnitude<=math.min(10,Context.DigReach(state))and os.clock()-last>.28 then
    last=os.clock();stroke(hit);afterWindup(function()require(R.GameAudio).Contact(hit.Position,hit.Material)end)
   end
   return
  end
  local root=P.Character:FindFirstChild('HumanoidRootPart');local reach=Context.DigReach(state)
  local point=reach<24 and hit.Position or target.Position
  if not root or(root.Position-point).Magnitude>reach then hint('Подойдите ближе — лопата не достаёт');return end
  last=os.clock();stroke(hit,target);local request=Context.Request(target);afterWindup(function()remote:FireServer(request)end)
 end
 local function update()cancel();gui.Enabled=equipped()and touch();tool.ManualActivationOnly=touch();if touch()and not(P.Character and P.Character:GetAttribute('MountainSliding'))and tool.Parent==P:FindFirstChildOfClass('Backpack')then task.defer(function()local h=P.Character and P.Character:FindFirstChildOfClass('Humanoid');if h and not P.Character:GetAttribute('MountainSliding')and tool.Parent==P:FindFirstChildOfClass('Backpack')then h:EquipTool(tool)end end)end end
 local function hold(input)if equipped()and not shopOpen()then held=true;heldInput=input;dig()end end
 connect(tool.Equipped,update);connect(tool.Unequipped,function()cancel();gui.Enabled=false end)
 connect(tool.Activated,function()if not touch()and not Context.TouchBlocked(P.PlayerGui,Input:GetMouseLocation())then hold()end end);connect(tool.Deactivated,function()held=false;heldInput=nil end)
 connect(button.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then hold(input)end end)
 connect(Input.InputEnded,function(input)if input==heldInput or input.UserInputType==Enum.UserInputType.MouseButton1 then held=false;heldInput=nil end end)
 connect(Input.TouchTapInWorld,function(position,processed)if touch()and not processed and equipped()and not Context.TouchBlocked(P.PlayerGui,position)then dig(position)end end)
 connect(Input:GetPropertyChangedSignal('PreferredInput'),update);connect(Input.WindowFocusReleased,cancel);connect(P.CharacterRemoving,cancel)
 connect(Run.Heartbeat,function()if held then dig()end end)
 connect(tool.Destroying,function()cancel();closed=true;gui:Destroy();bound[tool]=nil;for _,c in connections do c:Disconnect()end end)
 update()
 task.defer(function()if touch()and not(P.Character and P.Character:GetAttribute('MountainSliding'))and tool.Parent==P:FindFirstChildOfClass('Backpack')then local h=P.Character and P.Character:FindFirstChildOfClass('Humanoid');if h then h:EquipTool(tool)end end end)
end
local function watch(container)for _,t in container:GetChildren()do bind(t)end;container.ChildAdded:Connect(bind)end
P.ChildAdded:Connect(function(c)if c:IsA('Backpack')then watch(c)end end);watch(P:WaitForChild('Backpack'))
P.CharacterAdded:Connect(watch);if P.Character then watch(P.Character)end



