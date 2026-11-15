-- Reuse the approved path geometry for every player plot after road generation.
local templates = script.Parent:WaitForChild("EntrancePathTemplates")
return function(garden, offset)
 if garden:GetAttribute("EntrancePathsVersion") == 1 then return end
 offset = offset or Vector3.zero
 local west = assert(garden:FindFirstChild("WestPromenade"), "West promenade missing")
 local front = assert(garden:FindFirstChild("FrontGardenLink"), "Front garden link missing")
 local boarding = assert(front:FindFirstChild("BoardingPlace"), "Boarding area missing")
 local fork = templates.NaturalEntranceFork:Clone()
 local gate = templates.ContinuousGateWalk:Clone()
 fork:PivotTo(fork:GetPivot() + offset)
 gate:PivotTo(gate:GetPivot() + offset)
 -- Replace the obsolete broad entrance mouth and its last approach facets.
 for _,part in ipairs(west:GetChildren()) do
  if part:IsA("BasePart") then
   local pos = part.Position - offset
   if part.Name == "MergedEntranceWalk" or
      (part.Name == "MeadowFacet" and part:IsA("WedgePart") and pos.X > -19) then
    part:Destroy()
   end
  elseif part.Name == "NaturalEntranceFork" or part.Name == "RefinedEntranceWalk" then
   part:Destroy()
  end
 end
 -- The gate template includes this section of promenade as one joined surface.
 for _,part in ipairs(front:GetDescendants()) do
  if part:IsA("BasePart") then
   local pos = part.Position - offset
   if part.Name == "GateApproach" or
      (part.Name == "LimestoneFootway" and pos.X >= 30 and pos.X <= 63 and pos.Z > 29 and pos.Z < 41) or
      (part.Name == "FlushPathEdge" and pos.X > 34 and pos.X < 54 and pos.Z > 30 and pos.Z < 33) then
    part:Destroy()
   end
  end
 end
 local existing = boarding:FindFirstChild("ContinuousGateWalk")
 if existing then existing:Destroy() end
 fork.Parent = west
 gate.Parent = boarding
 garden:SetAttribute("EntrancePathsVersion", 1)
end
