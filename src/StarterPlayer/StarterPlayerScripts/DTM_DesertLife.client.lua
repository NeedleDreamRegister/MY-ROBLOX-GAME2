-- Living desert, presentation only. Install in StarterPlayerScripts.
-- No remotes, rewards, Terrain writes, physics, audio assets, or gameplay state.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
local rng = Random.new()
local mobile = (Input.TouchEnabled and not Input.KeyboardEnabled) or script:GetAttribute("ForceMobileBudget") == true
local budget = {gusts = mobile and 2 or 4, weeds = mobile and 1 or 2,
	birds = mobile and 3 or 6, range = mobile and 230 or 330,
	airRange = mobile and 300 or 420, fps = mobile and 24 or 30}

local generations=player:WaitForChild("PlayerScripts")
local generation=(generations:GetAttribute("DTMDesertGeneration") or 0)+1
generations:SetAttribute("DTMDesertGeneration",generation)
local previous = workspace:FindFirstChild("DTM_DesertLife")
if previous then
	local stop = previous:FindFirstChild("Shutdown")
	if stop and stop:IsA("BindableEvent") then
		stop:Fire()
		RunService.Heartbeat:Wait() -- Deferred cleanup restores legacy state before recapturing it.
	end
	if previous.Parent then previous:Destroy() end
end
if generations:GetAttribute("DTMDesertGeneration")~=generation then return end
local root = Instance.new("Folder")
root.Name = "DTM_DesertLife"
root:SetAttribute("VisualOnly", true)
root:SetAttribute("Version", 2)
root:SetAttribute("MobileBudget", mobile)
root:SetAttribute("MaxGusts", budget.gusts)
root:SetAttribute("MaxTumbleweeds", budget.weeds)
root:SetAttribute("MaxBirds", budget.birds)
root:SetAttribute("GroundRange", budget.range)
root:SetAttribute("AirRange", budget.airRange)
root:SetAttribute("QATimeScale", 1)
root:SetAttribute("SpawningEnabled", true)
root.Parent = workspace
local shutdown = Instance.new("BindableEvent")
shutdown.Name = "Shutdown"; shutdown.Parent = root
local preview = Instance.new("BindableEvent")
preview.Name = "Preview"; preview.Parent = root
local connections, legacy, actors = {}, {}, {}
local sites, people = {}, {}
local alive, elapsed, refresh, tickTime = true, 0, 10, 0
local nextGust, nextWeed, nextBird = 1.5, 11, 5
local total = {gust = 0, weed = 0, bird = 0}
local assessSafety

local function connect(signal, fn)
	local c = signal:Connect(fn); table.insert(connections, c); return c
end
local function part(parent, name, size, cf, color)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
	p.CastShadow = false; p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent; return p
end
local function count(kind)
	local n = 0; for _,a in actors do if a.kind == kind then n += 1 end end; return n
end
local function diagnostic()
	root:SetAttribute("ActiveGusts", count("gust"))
	root:SetAttribute("ActiveTumbleweeds", count("weed"))
	root:SetAttribute("ActiveBirds", count("bird"))
	root:SetAttribute("TotalGusts", total.gust)
	root:SetAttribute("TotalTumbleweeds", total.weed)
	root:SetAttribute("TotalBirds", total.bird)
	root:SetAttribute("TrackedSites", #sites)
	local unsafe=0
	if assessSafety then for _,a in actors do if a.position and not assessSafety(a.position,8)then unsafe+=1 end end end
	root:SetAttribute("UnsafeActors", unsafe)
	root:SetAttribute("SafetyOK", unsafe==0)
	root:SetAttribute("BudgetOK", count("gust")<=budget.gusts and count("weed")<=budget.weeds and count("bird")<=budget.birds)
end
local function retire(i)
	local a = actors[i]; if a.model then a.model:Destroy() end
	table.remove(actors, i)
end
local function stop(skipDestroy)
	if not alive then return end; alive = false
	for _,c in connections do c:Disconnect() end
	for _,a in actors do a.model:Destroy() end; table.clear(actors)
	for emitter,enabled in legacy do
		if emitter.Parent then emitter.Enabled = enabled end
	end
	table.clear(legacy)
	if not skipDestroy and root.Parent then root:Destroy() end
end
connect(shutdown.Event, stop)
connect(script.Destroying, stop)
connect(root.Destroying, function() stop(true) end)

-- Only retire the three old broad ambient volumes locally. Music, mining FX,
-- canopy motion and every other emitter keep their existing owners.
local function suppressOld(v)
	if not v:IsA("ParticleEmitter") or v.Name ~= "WindblownSand" then return end
	local env = workspace:FindFirstChild("DTM_Environment")
	local dust = env and env:FindFirstChild("AmbientDust")
	if dust and v:IsDescendantOf(dust) and legacy[v] == nil then
		legacy[v] = v.Enabled; v.Enabled = false; v:Clear()
	end
end
local env = workspace:FindFirstChild("DTM_Environment")
if env then for _,v in env:GetDescendants() do suppressOld(v) end end
connect(workspace.DescendantAdded, suppressOld)

local function flat(p) return Vector3.new(p.X, 0, p.Z) end
local function refreshWorld()
	sites, people = {}, {}
	local plots = workspace:FindFirstChild("SandPlots")
	if plots then
		for _,plot in plots:GetChildren() do
			local spawn = plot:FindFirstChild("SpawnLocation")
			if spawn and spawn:IsA("BasePart") then
				local mountain = plot:FindFirstChild("SandPrototype")
				local origin = mountain and mountain:GetAttribute("TerrainOrigin")
				local low = mountain and mountain:GetAttribute("TerrainBoundsMin")
				local high = mountain and mountain:GetAttribute("TerrainBoundsMax")
				table.insert(sites, {offset = spawn.Position - Vector3.new(3,.5,-2),
					origin = typeof(origin) == "Vector3" and origin or nil,
					low = typeof(low) == "Vector3" and low or nil,
					high = typeof(high) == "Vector3" and high or nil})
			end
		end
	end
	if #sites == 0 then table.insert(sites, {offset = Vector3.zero}) end
	for _,p in Players:GetPlayers() do
		local ch = p.Character; local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then table.insert(people, hrp) end
	end
end
local function nearPlayer(p, margin)
	for _,hrp in people do
		if hrp.Parent and (flat(hrp.Position) - flat(p)).Magnitude < margin then return true end
	end
	return false
end
local function safeGround(p, margin)
	for _,site in sites do
		local q = p - site.offset
		-- Includes the complete original road spline, service machines, lawns,
		-- rear rest courts and tram loop, with a generous empty shoulder.
		if q.X > -288-margin and q.X < 244+margin and q.Z > -477-margin and q.Z < 76+margin then return false end
		if site.origin then
			local a = site.origin + (site.low or Vector3.new(-40,0,-40))*4
			local b = site.origin + (site.high or Vector3.new(40,40,40))*4
			if p.X > a.X-22-margin and p.X < b.X+22+margin and p.Z > a.Z-22-margin and p.Z < b.Z+22+margin then return false end
		end
	end
	return not nearPlayer(p, 20+margin)
end
assessSafety=safeGround
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function ground(p)
	local exclusions = {root}
	for _,p1 in Players:GetPlayers() do if p1.Character then table.insert(exclusions,p1.Character) end end
	rayParams.FilterDescendantsInstances = exclusions
	local hit = workspace:Raycast(p + Vector3.new(0,150,0), Vector3.new(0,-310,0), rayParams)
	if not hit or hit.Normal.Y < .89 or hit.Material ~= Enum.Material.Sand then return nil end
	return hit.Position
end
local function nearestSite(camera)
	local result, distance
	for _,site in sites do
		local d = (flat(camera) - flat(site.offset)).Magnitude
		if not distance or d < distance then result, distance = site,d end
	end
	return result
end
-- A coherent prevailing breeze changes slowly; individual gusts deviate gently.
local function wind(t)
	local a = -.32 + math.noise(t*.012, .41)*.48
	return Vector3.new(math.cos(a),0,math.sin(a))
end
local function makePath(camera, kind)
	local site = nearestSite(camera); if not site then return nil end
	local zones = {{-420,-365,-340,-45},{270,302,-325,-45},
		{-245,210,114,260},{-240,180,-640,-535}}
	local bestPath,bestScore
	local cam=workspace.CurrentCamera
	local view=cam and flat(cam.CFrame.LookVector)or Vector3.new(0,0,-1)
	if view.Magnitude>.01 then view=view.Unit else view=Vector3.new(0,0,-1)end
	for _=1,18 do
		local z = zones[rng:NextInteger(1,#zones)]
		local p = site.offset + Vector3.new(rng:NextNumber(z[1],z[2]),0,rng:NextNumber(z[3],z[4]))
		if (flat(p)-flat(camera)).Magnitude < budget.range-35 then
			local d = wind(tickTime) + Vector3.new(0,0,rng:NextNumber(-.12,.12))
			d = d.Unit
			local length = kind == "weed" and rng:NextNumber(54,88) or rng:NextNumber(32,62)
			local points, valid = {},true
			local side = Vector3.new(-d.Z,0,d.X)
			local bend = rng:NextNumber(1,3)
			for i=0,16 do
				local u = i/16
				local q = p + d*length*u + side*math.sin(u*math.pi)*bend
				if not safeGround(q,12) then valid=false;break end
				local hit = ground(q)
				if not hit or (#points>0 and math.abs(hit.Y-points[#points].Y)>2.8) then valid=false;break end
				table.insert(points,hit)
			end
			if valid then
				local delta=flat(p)-flat(camera)
				local score=delta.Magnitude+(1-delta.Unit:Dot(view))*155
				if not bestScore or score<bestScore then
					bestPath={points=points,direction=d,length=length};bestScore=score
				end
			end
		end
	end
	return bestPath
end
local function pathAt(path,u)
	local s = math.clamp(u,0,1)*(#path.points-1)
	local i = math.min(#path.points-1,math.floor(s)+1)
	return path.points[i]:Lerp(path.points[i+1],s-(i-1))
end
local function envelope(u) return math.clamp(u*5,0,1)*math.clamp((1-u)*5,0,1) end

local function emitter(parent,name,texture,color,size,transparency,lifetime)
	local e = Instance.new("ParticleEmitter")
	e.Name=name; e.Texture=texture; e.Color=ColorSequence.new(color)
	e.Size=size; e.Transparency=transparency; e.Lifetime=lifetime
	e.LightEmission=0; e.LightInfluence=1; e.Rate=0; e.Enabled=true
	e.SpreadAngle=Vector2.new(18,12); e.EmissionDirection=Enum.NormalId.Front
	e.Rotation=NumberRange.new(0,360); e.RotSpeed=NumberRange.new(-14,14)
	e.Parent=parent; return e
end
local function spawnGust(camera)
	if count("gust") >= budget.gusts then return false end
	local path = makePath(camera,"gust"); if not path then return false end
	local carrier = part(root,"SurfaceSandGust",Vector3.new(6,.12,3),CFrame.new(path.points[1]),Color3.new())
	carrier.Transparency=1
	local smoke="rbxasset://textures/particles/smoke_main.dds"
	local veil=emitter(carrier,"LowDustVeil",smoke,Color3.fromRGB(204,185,148),
		NumberSequence.new({NumberSequenceKeypoint.new(0,1.6),NumberSequenceKeypoint.new(.5,4.8),NumberSequenceKeypoint.new(1,7.3)}),
		NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.23,.88),NumberSequenceKeypoint.new(.65,.94),NumberSequenceKeypoint.new(1,1)}),NumberRange.new(1.4,2.8))
	veil.Speed=NumberRange.new(1,2.8);veil.Acceleration=path.direction*1.3+Vector3.new(0,.15,0)
	veil.Squash=NumberSequence.new(1.4)
	local ribbon=emitter(carrier,"SkimmingRibbons",smoke,Color3.fromRGB(218,197,157),
		NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(.4,1.4),NumberSequenceKeypoint.new(1,2.4)}),
		NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,.72),NumberSequenceKeypoint.new(.75,.91),NumberSequenceKeypoint.new(1,1)}),NumberRange.new(.7,1.5))
	ribbon.Speed=NumberRange.new(4,7);ribbon.Acceleration=path.direction*1.7
	ribbon.Orientation=Enum.ParticleOrientation.VelocityParallel; ribbon.Squash=NumberSequence.new(2.2)
	local grains=emitter(carrier,"SaltatingSand",smoke,Color3.fromRGB(191,162,113),
		NumberSequence.new({NumberSequenceKeypoint.new(0,.055),NumberSequenceKeypoint.new(.6,.09),NumberSequenceKeypoint.new(1,0)}),
		NumberSequence.new({NumberSequenceKeypoint.new(0,.28),NumberSequenceKeypoint.new(.65,.55),NumberSequenceKeypoint.new(1,1)}),NumberRange.new(.35,.7))
	grains.Speed=NumberRange.new(3,6);grains.Acceleration=path.direction*1.5+Vector3.new(0,-1.3,0)
	grains.SpreadAngle=Vector2.new(16,6)
	table.insert(actors,{kind="gust",model=carrier,path=path,age=0,
		position=path.points[1],duration=rng:NextNumber(7,11),tail=3,emitters={veil,ribbon,grains},strength=rng:NextNumber(.6,1)})
	total.gust+=1;return true
end

local twigColors={Color3.fromRGB(132,102,63),Color3.fromRGB(157,125,77),Color3.fromRGB(174,144,92)}
local function twig(model,a,b,width,index)
	return part(model,"DryBranch",Vector3.new(width,width,(b-a).Magnitude),
		CFrame.lookAt((a+b)/2,b),twigColors[index%#twigColors+1])
end
local function spawnWeed(camera)
	if count("weed")>=budget.weeds then return false end
	local path=makePath(camera,"weed"); if not path then return false end
	local model=Instance.new("Model");model.Name="BranchingTumbleweed"
	local radius=rng:NextNumber(1.15,1.65)
	-- Open, asymmetric branching skeleton: curved stems, forked tips, cross twigs.
	-- There is deliberately no opaque ball, sphere mesh or solid core.
	local branches=mobile and 9 or 13
	for i=1,branches do
		local y=1-2*(i-.5)/branches
		local angle=i*2.39996+rng:NextNumber(-.16,.16)
		local axis=Vector3.new(math.sqrt(1-y*y)*math.cos(angle),y,math.sqrt(1-y*y)*math.sin(angle))
		local tangent=axis:Cross(Vector3.yAxis)
		if tangent.Magnitude<.1 then tangent=Vector3.xAxis else tangent=tangent.Unit end
		local bend=tangent*rng:NextNumber(.25,.48)*radius
		local previousPoint=axis*radius*.16
		for j=1,4 do
			local u=j/4
			local tip=axis*radius*(.16+.84*u)+bend*math.sin(u*math.pi*.9)
			twig(model,previousPoint,tip,(.043-.005*j)*radius,i+j)
			if j==2 or j==3 then
				local fork=tip+tangent*radius*(j==2 and .32 or -.27)+axis*radius*.13
				twig(model,tip,fork,.024*radius,i)
				twig(model,fork,fork+axis*radius*.12-tangent*radius*.1,.017*radius,i+1)
			end
			previousPoint=tip
		end
	end
	local base={};for _,p in model:GetChildren()do if p:IsA("BasePart")then table.insert(base,{part=p,cf=p.CFrame});p.Transparency=1 end end
	model.Parent=root
	table.insert(actors,{kind="weed",model=model,path=path,parts=base,radius=radius,
		position=path.points[1],age=0,duration=path.length/rng:NextNumber(4.2,6.5),phase=rng:NextNumber(0,6.28)})
	total.weed+=1;return true
end

-- Two actual readable silhouettes: swept wings/fork tail (swift), broader
-- wings/short fan tail and pale breast (desert dove). No image asset dependency.
local function triangle(model,a,b,c,color,records,side)
	local ab,ac,bc=b-a,c-a,c-b
	if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c
	elseif ac.Magnitude>bc.Magnitude then a,b=b,a end
	ab,ac,bc=b-a,c-a,c-b
	local right=ac:Cross(ab).Unit;local up=bc:Cross(right).Unit;local back=bc.Unit
	local h=math.abs(ab:Dot(up))
	for _,v in {{math.abs(ab:Dot(back)),(a+b)/2,right},{math.abs(ac:Dot(back)),(a+c)/2,-right}}do
		if v[1]>.001 then
			local p=Instance.new("WedgePart");p.Name="FeatherSilhouette";p.Size=Vector3.new(.045,h,v[1])
			p.CFrame=CFrame.fromMatrix(v[2],v[3],up,v[3]:Cross(up));p.Color=color
			p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=model
			table.insert(records,{part=p,cf=p.CFrame,side=side})
		end
	end
end
local function birdModel(species)
	local dove=species=="dove"
	local model=Instance.new("Model");model.Name=dove and "DesertDove" or "DesertSwift"
	local records={};local color=dove and Color3.fromRGB(118,109,94) or Color3.fromRGB(64,65,61)
	local function body(name,size,position,col)
		local p=part(model,name,size,CFrame.new(position),col or color)
		local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
		table.insert(records,{part=p,cf=p.CFrame});return p
	end
	body("StreamlinedBody",Vector3.new(dove and .42 or .3,.32,dove and 1.13 or 1.02),Vector3.zero)
	body("Head",Vector3.new(.29,.29,.35),Vector3.new(0,.08,-.56))
	if dove then body("WarmPaleBreast",Vector3.new(.31,.14,.65),Vector3.new(0,-.13,-.17),Color3.fromRGB(173,157,130)) end
	local beak=part(model,"Beak",Vector3.new(.09,.08,.22),CFrame.new(0,.065,-.78),Color3.fromRGB(76,69,54))
	table.insert(records,{part=beak,cf=beak.CFrame})
	for _,side in {-1,1}do
		local width=dove and 1.65 or 1.48
		triangle(model,Vector3.new(side*.12,0,-.3),Vector3.new(side*.95,0,-.12),Vector3.new(side*.74,0,.37),color,records,side)
		triangle(model,Vector3.new(side*.74,0,.37),Vector3.new(side*.95,0,-.12),Vector3.new(side*width,0,dove and .38 or .78),color,records,side)
		triangle(model,Vector3.new(side*.04,0,.34),Vector3.new(side*(dove and .33 or .29),0,dove and .86 or 1.13),Vector3.new(side*.12,0,dove and .93 or .64),color,records,nil)
	end
	return model,records
end
local function bezier(a,b,c,d,t)
	local u=1-t;return a*u*u*u+b*3*u*u*t+c*3*u*t*t+d*t*t*t
end
local function spawnBirds(camera,species,flock)
	local room=budget.birds-count("bird");if room<=0 then return false end
	local site=nearestSite(camera);if not site then return false end
	local direction,side,a,b,c,d,bestScore
	local cameraObject=workspace.CurrentCamera
	local look=cameraObject and flat(cameraObject.CFrame.LookVector) or Vector3.new(0,0,-1)
	if look.Magnitude>.01 then look=look.Unit else look=Vector3.new(0,0,-1)end
	-- Flight lanes sit outside the same road/mining reserve as ground actors.
	-- This also avoids silhouettes intersecting the tall quarry Terrain.
	for _=1,16 do
		local lane=rng:NextInteger(1,4)
		local localCenter=({Vector3.new(-355,0,-200),Vector3.new(310,0,-200),
			Vector3.new(-20,0,145),Vector3.new(-25,0,-550)})[lane]
		local along=lane<3 and Vector3.zAxis or Vector3.xAxis
		local candidateDirection=along*(rng:NextNumber()<.5 and -1 or 1)
		local candidateSide=Vector3.new(-candidateDirection.Z,0,candidateDirection.X)
		local center=site.offset+localCenter+along*rng:NextNumber(-70,70)
		local height=site.offset.Y+rng:NextNumber(44,67)
		local span=rng:NextNumber(90,122)
		local points={center-candidateDirection*span-candidateSide*12,center-candidateDirection*span*.35+candidateSide*23,
			center+candidateDirection*span*.35+candidateSide*31,center+candidateDirection*span-candidateSide*12}
		local valid=true
		for j=0,12 do
			local q=bezier(points[1],points[2],points[3],points[4],j/12)
			if not safeGround(q,22)then valid=false;break end
			local hit=ground(q);if hit then height=math.max(height,hit.Y+28)end
		end
		local delta=flat(center)-flat(camera)
		local distance=delta.Magnitude
		local alignment=distance>.01 and delta.Unit:Dot(look)or 1
		local score=distance+(1-alignment)*180
		if valid and distance<budget.airRange-15 and (not bestScore or score<bestScore)then
			local lift=Vector3.new(0,height-center.Y,0)
			a,b,c,d=points[1]+lift,points[2]+lift+Vector3.new(0,7,0),points[3]+lift+Vector3.new(0,3,0),points[4]+lift
			direction,side,bestScore=candidateDirection,candidateSide,score
		end
	end
	if not a then return false end
	local duration=rng:NextNumber(19,25)
	local n=math.min(room,flock and 3 or 1)
	for i=1,n do
		local model,parts=birdModel(species)
		local offset=side*((i-1)*3.4)+Vector3.new(0,(i%2)*1.1,0)-direction*(i-1)*4
		for _,r in parts do r.part.Transparency=1 end
		model.Parent=root
		table.insert(actors,{kind="bird",model=model,parts=parts,age=-(i-1)*.18,duration=duration,
			position=a+offset,path={a+offset,b+offset,c+offset,d+offset},species=species,phase=rng:NextNumber(0,6.28)})
		total.bird+=1
	end
	return true
end

local function updateActor(a,dt,camera)
	a.age+=dt
	if a.age<0 then for _,r in a.parts do r.part.Transparency=1 end;return true end
	local u=a.age/a.duration
	if a.kind=="gust" then
		if a.age>a.duration+a.tail then return false end
		local p=pathAt(a.path,u)+Vector3.new(0,.18,0)
		a.position=p
		if (p-camera).Magnitude>budget.range+65 then return false end
		if not safeGround(p,8)then for _,e in a.emitters do e:Clear()end;return false end
		local gain=u<1 and envelope(u)*a.strength or 0
		a.model.CFrame=CFrame.lookAt(p,p+a.path.direction)
		local multiplier=mobile and .55 or 1
		local modulation=.72+.28*math.sin(a.age*2.3)^2
		for i,e in a.emitters do e.Rate=({7,13,27})[i]*gain*multiplier*modulation end
		return true
	elseif a.kind=="weed" then
		if u>=1 then return false end
		local p=pathAt(a.path,u)
		a.position=p
		if (p-camera).Magnitude>budget.range or not safeGround(p,8) then return false end
		local bounce=math.abs(math.sin(a.age*5.1+a.phase))*.1+math.sin(a.age*1.9)*.025
		local axis=Vector3.new(a.path.direction.Z,0,-a.path.direction.X)
		local cf=CFrame.new(p+Vector3.new(0,a.radius+bounce+.04,0))*
			CFrame.fromAxisAngle(axis,a.path.length*u/a.radius)*CFrame.Angles(.06*math.sin(a.age),a.phase,0)
		local fade=1-envelope(u)
		for _,r in a.parts do r.part.CFrame=cf*r.cf;r.part.Transparency=fade end
		return true
	end
	if u>=1 then return false end
	local path=a.path
	local p=bezier(path[1],path[2],path[3],path[4],u)
	a.position=p
	if (p-camera).Magnitude>budget.airRange+60 or not safeGround(p,8)then return false end
	local before=bezier(path[1],path[2],path[3],path[4],math.max(0,u-.012))
	local after=bezier(path[1],path[2],path[3],path[4],math.min(1,u+.012))
	local velocity=(after-before).Unit
	local nextP=bezier(path[1],path[2],path[3],path[4],math.min(1,u+.025))
	local curve=velocity:Cross((nextP-p).Magnitude>.001 and (nextP-p).Unit or velocity).Y
	local bank=math.clamp(-curve*7,-.28,.28)
	local bob=math.sin(a.age*1.6+a.phase)*.22
	local cf=CFrame.lookAt(p+Vector3.new(0,bob,0),p+velocity+Vector3.new(0,bob,0))*CFrame.Angles(0,0,bank)
	local swift=a.species=="swift"
	local cycle=a.age*(swift and 7.8 or 5.3)+a.phase
	-- Flap sequences blend into several seconds of quiet gliding.
	local flapGain=math.clamp((math.sin(a.age*.72+a.phase)+.15)*2.8,0,1)
	local flap=(math.sin(cycle)*.48+.11)*flapGain+.07*(1-flapGain)
	local fade=1-envelope(u)
	for _,r in a.parts do
		r.part.CFrame=cf*(r.side and CFrame.Angles(0,0,r.side*flap) or CFrame.identity)*r.cf
		r.part.Transparency=fade
	end
	return true
end

refreshWorld()
connect(preview.Event,function(command)
	if not alive then return end
	local camera=workspace.CurrentCamera;if not camera then return end
	refreshWorld()
	local p=camera.CFrame.Position
	local before=total.gust+total.weed+total.bird
	if command=="gust" or command=="all" then spawnGust(p) end
	if command=="weed" or command=="all" then spawnWeed(p) end
	if command=="swift" or command=="all" then spawnBirds(p,"swift",false) end
	if command=="dove" or command=="all" then spawnBirds(p,"dove",false) end
	if command=="flock" then spawnBirds(p,"swift",true) end
	if command=="clear" then for i=#actors,1,-1 do retire(i) end end
	root:SetAttribute("LastPreviewCommand",tostring(command))
	root:SetAttribute("LastPreviewAccepted",total.gust+total.weed+total.bird-before)
	diagnostic()
end)
connect(RunService.Heartbeat,function(dt)
	if not alive then return end
	local scale=math.clamp(tonumber(root:GetAttribute("QATimeScale"))or 1,.1,20)
	tickTime+=dt*scale;elapsed+=dt;refresh+=dt
	if elapsed<1/budget.fps then return end
	local step=math.min(elapsed,.2)*scale;elapsed=0
	local camera=workspace.CurrentCamera;if not camera then return end
	local cameraPos=camera.CFrame.Position
	local report=refresh>=1.5
	if report then refresh=0;refreshWorld() end
	for i=#actors,1,-1 do
		if not updateActor(actors[i],step,cameraPos) then retire(i) end
	end
	if report then diagnostic()end
	-- A single scheduler, hard caps, finite lifetimes; nothing accumulates while
	-- distant or while all safe lanes are occupied. Paused clients catch up gently.
	if root:GetAttribute("SpawningEnabled")==false then return end
	if tickTime>=nextGust then
		spawnGust(cameraPos);nextGust=tickTime+rng:NextNumber(mobile and 7 or 4.5,11)
	end
	if tickTime>=nextWeed then
		spawnWeed(cameraPos);nextWeed=tickTime+rng:NextNumber(27,52)
	end
	if tickTime>=nextBird then
		spawnBirds(cameraPos,rng:NextNumber()<.55 and "swift" or "dove",rng:NextNumber()<.17)
		nextBird=tickTime+rng:NextNumber(20,39)
	end
end)
diagnostic()