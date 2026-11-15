local Appearance=require(game:GetService('ReplicatedStorage').UpgradeToolAppearance)
local C=require(game:GetService('ReplicatedStorage').UpgradeConfig)
local S={}
function S.Create(owner,getAccount)
 local closed=false
 local function refresh()
  if closed or not owner.Parent then return end
  local a=getAccount() if not a then return end
  local backpack=owner:FindFirstChildOfClass('Backpack') if not backpack then return end
  local selected,wasEquipped
  for _,container in {backpack,owner.Character}do
   if container then for _,tool in container:GetChildren()do
    if tool:IsA('Tool') and tool:GetAttribute('SandPrototypeTool') then
     if tool:GetAttribute('UpgradeToolId')==a.SelectedTool and not selected then selected=tool
     else wasEquipped=wasEquipped or container==owner.Character;tool:Destroy()end
    end
   end end
  end
  if not selected then selected=Appearance.Build(a.SelectedTool);selected.Parent=backpack end
  selected:SetAttribute('UpgradeLevel',a.ToolLevels[a.SelectedTool])
  selected.ToolTip=string.format('%s · уровень %d · %d песка',C.Tool(a.SelectedTool).Name,a.ToolLevels[a.SelectedTool],C.Capacity(a))
  if wasEquipped and owner.Character then local h=owner.Character:FindFirstChildOfClass('Humanoid');if h and h.Health>0 then h:EquipTool(selected)end end
 end
 local connection=owner.CharacterAdded:Connect(function()task.delay(.3,refresh)end)
 task.defer(refresh)
 return {Refresh=refresh,Destroy=function()closed=true;connection:Disconnect()end}
end
return S

