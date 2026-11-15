-- Standalone park shuttle. Does not read or write any mining/economy system.
local RunService=game:GetService('RunService')
local Players=game:GetService('Players')
local Lighting=game:GetService('Lighting')
local RouteDefinition=require(script.Parent.Route)
return function(cart,garden,offset)
local Route=RouteDefinition.WithOffset(offset or Vector3.zero)
local connections={}
local function connect(signal,callback) local c=signal:Connect(callback) table.insert(connections,c) return c end
local root=cart.PrimaryPart
local seats=cart.PassengerSeats:GetChildren()
table.sort(seats,function(a,b)return a.Name<b.Name end)
local landing=garden.FrontGardenLink.BoardingPlace.SafeExit
local landingFrame=landing.CFrame
local exitRequest=game.ReplicatedStorage.QuarryTransitRequests.ExitRide
local align=root.RoutePosition
local orient=root.RouteOrientation
-- Track the chassis attachment, so passenger mass cannot lower the wheel plane.
align.ApplyAtCenterOfMass=false
local travel,speed,spin=0,0,0
local smoothAcceleration,steering,bodyPitch,bodyRoll,bodyLift,elapsed=0,0,0,0,0,0
local state='Arriving'
local dwell,stable,lap,stopCount=0,0,0,0
local publishing=0
local riders,pending={},{}
local wheelMotors={}
for _,motor in cart.Wheels:GetDescendants() do if motor:IsA('Motor6D') then wheelMotors[motor]={Base=motor.C0,Steers=motor:GetAttribute('SteeringAxle')==true} end end
local suspension=cart:FindFirstChild('SuspensionMotor',true)
local steeringMotor=cart:FindFirstChild('SteeringMotor',true)
local steeringBase=steeringMotor and steeringMotor.C0
local speedDisplay=cart:FindFirstChild('DriverDisplay',true)
speedDisplay=speedDisplay and speedDisplay.InstrumentDisplay.Speed
local lamps=cart.Coachwork.Lighting:GetChildren()
local function riderCount() local n=0 for _ in riders do n+=1 end return n end
cart.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
local function own()
 if root.Parent and root:CanSetNetworkOwnership() then root:SetNetworkOwner(nil) end
end
local function isDocked()
 return state=='Docked' and root.AssemblyLinearVelocity.Magnitude<.3 and (root.Position-Route.Frame(0).Position).Magnitude<.35
end
local function setPrompts()
 local docked=isDocked()
 cart:SetAttribute('Docked',docked)
 root.ExitPrompt.Enabled=docked
 for _,seat in seats do
  local available=docked and seat.Occupant==nil
  seat:SetAttribute('AvailableForBoarding',available)
  seat.BoardPrompt.Enabled=available
 end
 cart:SetAttribute('RiderCount',riderCount())
 cart:SetAttribute('FreeSeats',#seats-riderCount())
end
local function restore(humanoid,data)
 if not data or data.Restored then return end
 data.Restored=true
 if humanoid.Parent then
  humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,data.Jumping)
  humanoid.AutoRotate=data.AutoRotate
 end
 for part,collide in data.Collisions do if part.Parent then part.CanCollide=collide end end
end
local function prepare(humanoid,seat)
 local character=humanoid.Parent
 local data={Seat=seat,Character=character,Collisions={},Jumping=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping),AutoRotate=humanoid.AutoRotate}
 for _,part in character:GetDescendants() do if part:IsA('BasePart') then data.Collisions[part]=part.CanCollide part.CanCollide=false end end
 humanoid.AutoRotate=false
 humanoid.Jump=false
 humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
 return data
end
local function disembark(humanoid,immediate)
 local data=riders[humanoid] or pending[humanoid]
 if not data or data.Exiting then return end
 data.Exiting=true
 riders[humanoid]=nil pending[humanoid]=nil
 local seat=data.Seat
 local character=data.Character
 local exitFrame=landingFrame*CFrame.new(((seat:GetAttribute('SeatIndex') or 1)%2-.5)*2,0,((seat:GetAttribute('SeatIndex') or 1)-3)*2.7)
 if immediate and not isDocked() then
  local distance=Route.DistanceAtTravel(travel)
  local p,n,tangent=Route.RoadAt(distance)
  local index=seat:GetAttribute('SeatIndex') or 1
  local position=p+n*(7.2+(index%2)*.6)+tangent*((index-3)*1.5)+Vector3.new(0,3.25,0)
  exitFrame=CFrame.lookAt(position,position+tangent)
 end
 -- Native SeatWeld is removed before placing the passenger on the landing.
 for _,weld in seat:GetChildren() do if weld:IsA('Weld') and weld.Name=='SeatWeld' and weld.Part1 and weld.Part1:IsDescendantOf(character) then weld:Destroy() end end
 humanoid.Sit=false
 local exitRoot=character:FindFirstChild('HumanoidRootPart')
 if exitRoot and exitRoot:CanSetNetworkOwnership() then exitRoot:SetNetworkOwner(nil) end
 task.spawn(function()
  RunService.Heartbeat:Wait()
  RunService.Heartbeat:Wait()
  if character.Parent and humanoid.Health>0 then
   local cf=exitFrame
   character:PivotTo(cf)
   local hrp=character:FindFirstChild('HumanoidRootPart')
   if hrp then hrp.AssemblyLinearVelocity=Vector3.zero hrp.AssemblyAngularVelocity=Vector3.zero end
   humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
   local player=Players:GetPlayerFromCharacter(character)
   if player then exitRequest:FireClient(player,character,cf) end
   task.delay(.4,function()
    if hrp and hrp.Parent and humanoid.Parent and not humanoid.SeatPart and hrp:CanSetNetworkOwnership() then hrp:SetNetworkOwnershipAuto() end
   end)
  end
  restore(humanoid,data)
  own() setPrompts()
 end)
end
local function exitPlayer(player,action)
 local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 local data=h and riders[h]
 if not data or data.Exiting then return end
 if action=='JumpExit' then disembark(h,true)
 elseif isDocked() then disembark(h)
 elseif action=='ToggleExit' then
  data.ExitRequested=not data.ExitRequested
  exitRequest:FireClient(player,'QueueStatus',data.ExitRequested)
 end
end
connect(root.ExitPrompt.Triggered,exitPlayer)
connect(exitRequest.OnServerEvent,exitPlayer)
for _,seat in seats do
 local previous=nil
 seat.CanTouch=false
 connect(seat.BoardPrompt.Triggered,function(player)
  if not isDocked() or seat.Occupant then return end
  local character=player.Character
  local h=character and character:FindFirstChildOfClass('Humanoid')
  local hrp=character and character:FindFirstChild('HumanoidRootPart')
  if not h or not hrp or h.Health<=0 or h.SeatPart or riders[h] or pending[h] or (hrp.Position-seat.Position).Magnitude>12 then return end
  local data=prepare(h,seat) pending[h]=data
  seat:Sit(h)
  task.delay(.65,function()
   if pending[h]==data then pending[h]=nil restore(h,data) end
  end)
 end)
 connect(seat:GetPropertyChangedSignal('Occupant'),function()
  local h=seat.Occupant
  if previous and previous~=h then
   local old=previous
   if riders[old] then disembark(old) end
  end
  previous=h
  if h then
   local data=pending[h]
   if not data then
    -- Only an explicit boarding request at the landing may create a rider.
    h.Sit=false
   else
    pending[h]=nil riders[h]=data
    own()
    task.defer(own)
   end
  end
  setPrompts()
 end)
end
connect(Players.PlayerRemoving,function(player)
 local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if h then disembark(h) end
end)
for _,part in cart:GetDescendants() do if part:IsA('BasePart') then part.Anchored=false end end
own()
align.Position=Route.Frame(0).Position
orient.CFrame=Route.Frame(0).Rotation
cart:SetAttribute('LapCount',0)
cart:SetAttribute('StopCount',0)
cart:SetAttribute('RouteLength',Route.TravelLength)
cart:SetAttribute('MaxRouteError',0)
local maxError=0
connect(RunService.PreSimulation,function(delta)
 if not root.Parent then return end
 local dt=math.min(delta,.1)
 elapsed+=dt
 local target
 local requestedSteering=0
 if state=='Driving' then
  local remaining=Route.TravelLength-travel
  local cruise=math.clamp(tonumber(cart:GetAttribute('CruiseSpeed')) or 12,4,18)
  local brake=math.clamp(tonumber(cart:GetAttribute('Braking')) or 4.5,2,8)
  local acceleration=math.clamp(tonumber(cart:GetAttribute('Acceleration')) or 3.5,1,6)
  local now=Route.TravelFrame(travel)
  local ahead=Route.TravelFrame(travel+12)
  local bend=math.acos(math.clamp(now.LookVector:Dot(ahead.LookVector),-1,1))/12
  local signedBend=math.atan2(now.LookVector:Cross(ahead.LookVector).Y,math.clamp(now.LookVector:Dot(ahead.LookVector),-1,1))/12
  local farther=Route.TravelFrame(travel+26)
  bend=math.max(bend,.7*math.acos(math.clamp(ahead.LookVector:Dot(farther.LookVector),-1,1))/14)
  requestedSteering=math.clamp(math.atan((cart:GetAttribute('Wheelbase') or 11.1)*signedBend),math.rad(-26),math.rad(26))
  local gentleLimit=cruise*(1-.22*math.clamp(bend/.022,0,1))
  local turnLimit=math.clamp(math.min(gentleLimit,math.sqrt(4.8/math.max(.001,bend))),math.min(7.5,cruise),cruise)
  local desired=math.min(cruise,turnLimit,math.sqrt(2*brake*.65*math.max(0,remaining-.035)))
  local oldSpeed=speed
  local wantedAcceleration=math.clamp((desired-speed)/.55,-brake,acceleration)
  local jerk=math.clamp(cart:GetAttribute('JerkLimit') or 6,2,12)
  smoothAcceleration+=math.clamp(wantedAcceleration-smoothAcceleration,-jerk*dt,jerk*dt)
  speed=math.clamp(speed+smoothAcceleration*dt,0,cruise)
  local advance=math.min(remaining,(oldSpeed+speed)*.5*dt)
  travel+=advance spin+=advance
  if remaining<.06 and speed<.2 then
   travel=0 speed=0 smoothAcceleration=0 lap+=1 state='Arriving' stable=0
   cart:SetAttribute('LapCount',lap)
  end
  target=Route.TravelFrame(travel)
 elseif state=='Arriving' then
  target=Route.Frame(0)
  if (root.Position-target.Position).Magnitude<.14 and root.AssemblyLinearVelocity.Magnitude<.12 and root.CFrame.LookVector:Dot(target.LookVector)>.999 then stable+=dt else stable=0 end
  if stable>=.25 then
   state='Docked' dwell=0 stopCount+=1
   cart:SetAttribute('StopCount',stopCount)
   cart:SetAttribute('LastDockTime',workspace:GetServerTimeNow())
   setPrompts()
   for humanoid,data in riders do if data.ExitRequested then task.defer(disembark,humanoid) end end
  end
 elseif state=='Docked' then
  target=Route.Frame(0)
  dwell+=dt
  local seconds=math.clamp(tonumber(cart:GetAttribute('StopSeconds')) or 4,1,30)
  if dwell>=seconds and next(pending)==nil then
   cart:SetAttribute('LastDwellSeconds',dwell)
   state='Driving' travel=0 speed=0 smoothAcceleration=0
   setPrompts()
  end
 end
 align.Position=target.Position
 orient.CFrame=target.Rotation
 steering+=(requestedSteering-steering)*(1-math.exp(-6*dt))
 local rollTarget=-steering*.045*math.min(1,speed/12)
 local pitchTarget=math.clamp(smoothAcceleration*.0025,-.012,.012)
 local liftTarget=.015*math.sin(spin*.9)*math.min(1,speed/12)
 local blend=1-math.exp(-5*dt)
 bodyPitch+=(pitchTarget-bodyPitch)*blend bodyRoll+=(rollTarget-bodyRoll)*blend bodyLift+=(liftTarget-bodyLift)*blend
 if suspension then suspension.C0=CFrame.new(0,bodyLift,0)*CFrame.Angles(bodyPitch,0,bodyRoll) end
 if steeringMotor then steeringMotor.C0=steeringBase*CFrame.Angles(0,0,steering*2.2) end
 for motor,data in wheelMotors do motor.C0=data.Base*CFrame.Angles(0,data.Steers and steering or 0,0)*CFrame.Angles(-(spin/(cart:GetAttribute('WheelRadius') or 1.1))%(math.pi*2),0,0) end
 local error=(root.Position-target.Position).Magnitude
 maxError=math.max(maxError,error)
 publishing+=dt
 if publishing>=.1 then
  publishing=0
  cart:SetAttribute('CurrentState',state)
  cart:SetAttribute('CurrentSpeed',speed)
  cart:SetAttribute('CurrentAcceleration',smoothAcceleration)
  cart:SetAttribute('SteeringAngle',math.deg(steering))
  cart:SetAttribute('Travel',travel)
  cart:SetAttribute('DwellRemaining',state=='Docked' and math.max(0,(cart:GetAttribute('StopSeconds') or 4)-dwell) or 0)
  cart:SetAttribute('RouteError',error)
  cart:SetAttribute('MaxRouteError',maxError)
  if speedDisplay then speedDisplay.Text=string.format('%02d',math.floor(speed+.5)) end
  local night=Lighting.ClockTime<6 or Lighting.ClockTime>18
  local braking=state~='Driving' or smoothAcceleration<-.35
  local signalSide=math.abs(steering)>math.rad(3) and (steering>0 and -1 or 1) or 0
  local blink=math.floor(elapsed/.45)%2==0
  for _,lamp in lamps do
   local beam=lamp:FindFirstChild('NightBeam') if beam then beam.Enabled=night end
   local courtesy=lamp:FindFirstChild('CourtesyLight') if courtesy then courtesy.Enabled=night end
   if lamp.Name=='BrakeLamp' then
    lamp.Color=braking and Color3.fromRGB(255,70,44) or Color3.fromRGB(135,40,29)
    local glow=lamp:FindFirstChild('BrakeGlow') if glow then glow.Enabled=night or braking glow.Brightness=braking and .65 or .15 end
   elseif string.find(lamp.Name,'Indicator',1,true) then
    local side=string.find(lamp.Name,'Left',1,true) and -1 or 1
    local on=signalSide==side and blink and speed>.2
    lamp.Color=on and Color3.fromRGB(255,176,65) or Color3.fromRGB(107,76,36)
    lamp.Material=on and Enum.Material.Neon or Enum.Material.SmoothPlastic
   end
  end
 end
end)
return function()
 for _,connection in connections do connection:Disconnect() end
 local leaving={} for humanoid in riders do table.insert(leaving,humanoid) end
 for humanoid in pending do table.insert(leaving,humanoid) end
 for _,humanoid in leaving do disembark(humanoid) end
end
end

