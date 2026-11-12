-- Play-only cosmetic stress. Sends confirmed-event shapes without changing sand.
-- Run only in a labelled private SessionOnly session; inspect the client peaks.
return function()
 local p=assert(game.Players:GetPlayers()[1])
 local plot=workspace.SandPlots["Plot_"..p.UserId]
 assert(plot.SandPrototype:GetAttribute("PersistenceStatus")=="SessionOnly")
 local event=game.ReplicatedStorage.SandPrototypeDig
 local api={}
 function api.Burst()
  local point=p.Character.HumanoidRootPart.Position+Vector3.new(0,6,-4)
  local color=Color3.fromRGB(225,199,140)
  local motions={}
  for i=1,8 do motions[i]={from=point+Vector3.new(i*0.1,0,0),to=point+Vector3.new(i*0.1,-4,0),size=Vector3.new(4,4,4),color=color}end
  for i=1,40 do event:FireClient(p,point,color,0,false,motions,i>8)end
 end
 function api.Far()
  local point=p.Character.HumanoidRootPart.Position+Vector3.new(2000,0,0)
  local color=Color3.fromRGB(225,199,140)
  event:FireClient(p,point,color,0,false,{{from=point,to=point-Vector3.new(0,4,0),size=Vector3.new(4,4,4),color=color}},false)
 end
 return api
end
