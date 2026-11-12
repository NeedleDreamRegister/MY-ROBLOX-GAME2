-- Authored construction cart; no resources, prompts or movement handlers here.
local Appearance={}
function Appearance.Build()
	local model=Instance.new("Model")model.Name="Wheelbarrow"
	model:SetAttribute("VisualVersion",2)model:SetAttribute("WheelRadius",0.85)
	model:SetAttribute("BodyBoxSize",Vector3.new(3.9,1.5,3.5))
	local paint=Color3.fromRGB(222,151,39)
	local frame=Color3.fromRGB(48,57,65)
	local steel=Color3.fromRGB(179,190,195)
	local rubber=Color3.fromRGB(31,34,37)
	local function part(name,size,cf,color,material,shape)
		local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material
		p.Shape=shape or Enum.PartType.Block p.Anchored=true p.Massless=true
		p.CanCollide=false p.CanTouch=false p.CanQuery=false
		p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
		p.Reflectance=material==Enum.Material.Metal and 0.06 or 0 p.Parent=model
		return p
	end
	local function beam(name,a,b,radius,color)
		return part(name,Vector3.new((b-a).Magnitude,radius*2,radius*2),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color,Enum.Material.Metal,Enum.PartType.Cylinder)
	end
	part("TrayBottom",Vector3.new(2.85,0.16,2.8),CFrame.new(0,2.08,0.8),paint,Enum.Material.Metal)
	for _,side in {-1,1}do
		part(side==-1 and "TrayLeft"or "TrayRight",Vector3.new(0.12,0.98,3.05),CFrame.new(side*1.57,2.53,0.8)*CFrame.Angles(0,0,-side*math.rad(18)),paint,Enum.Material.Metal)
		beam("RimSide"..side,Vector3.new(side*1.74,3.0,-0.83),Vector3.new(side*1.74,3.0,2.43),0.07,steel)
		local x=side*0.78
		part(side==1 and "HandleLeft"or "HandleRight",Vector3.new(0.16,0.16,2.4),CFrame.new(x,2.65,-1.9),frame,Enum.Material.Metal)
		part("Grip"..side,Vector3.new(0.84,0.25,0.25),CFrame.new(x,2.65,-2.75)*CFrame.Angles(0,math.pi/2,0),rubber,Enum.Material.Rubber,Enum.PartType.Cylinder)
		part("GripEnd"..side,Vector3.new(0.09,0.29,0.29),CFrame.new(x,2.65,-3.17)*CFrame.Angles(0,math.pi/2,0),rubber,Enum.Material.Rubber,Enum.PartType.Cylinder)
		beam("HandleRiser"..side,Vector3.new(x,2.65,-0.7),Vector3.new(x,1.85,-0.4),0.09,frame)
		beam("Chassis"..side,Vector3.new(x,2.47,-2.65),Vector3.new(x,1.25,1.8),0.09,frame)
		beam("Fork"..side,Vector3.new(x,1.65,1.05),Vector3.new(side*0.48,0.85,2.5),0.09,frame)
		beam("Leg"..side,Vector3.new(side*0.95,1.88,-0.35),Vector3.new(side*0.95,0.17,-0.65),0.085,frame)
		part("Foot"..side,Vector3.new(0.45,0.14,0.65),CFrame.new(side*0.95,0.08,-0.65),rubber,Enum.Material.Rubber)
		for _,z in {-0.35,1.4}do
			part("TrayBolt"..side.."_"..z,Vector3.new(0.05,0.16,0.16),CFrame.new(side*1.62,2.55,z),steel,Enum.Material.Metal,Enum.PartType.Cylinder)
		end
	end
	part("TrayBack",Vector3.new(3.15,0.94,0.12),CFrame.new(0,2.52,-0.68)*CFrame.Angles(math.rad(-15),0,0),paint,Enum.Material.Metal)
	part("TrayFront",Vector3.new(3.15,0.94,0.12),CFrame.new(0,2.52,2.28)*CFrame.Angles(math.rad(18),0,0),paint,Enum.Material.Metal)
	beam("RimFront",Vector3.new(-1.74,3,2.43),Vector3.new(1.74,3,2.43),0.07,steel)
	beam("RimBack",Vector3.new(-1.74,3,-0.83),Vector3.new(1.74,3,-0.83),0.07,steel)
	beam("CrossBrace",Vector3.new(-0.78,1.79,0),Vector3.new(0.78,1.79,0),0.08,frame)
	part("Axle",Vector3.new(1.35,0.16,0.16),CFrame.new(0,0.85,2.5),steel,Enum.Material.Metal,Enum.PartType.Cylinder)
	local wheel=CFrame.new(0,0.85,2.5)
	local tire=part("WheelTire",Vector3.new(0.62,1.64,1.64),wheel,rubber,Enum.Material.Rubber,Enum.PartType.Cylinder)
	tire:SetAttribute("WheelRotates",true)
	local hub=part("WheelHub",Vector3.new(0.70,1.13,1.13),wheel,frame,Enum.Material.Metal,Enum.PartType.Cylinder)
	hub:SetAttribute("WheelRotates",true)
	for index=0,19 do
		local tread=part("Tread"..index,Vector3.new(0.66,0.1,0.20),wheel*CFrame.Angles(index*math.pi/10,0,0)*CFrame.new(0,0.8,0),rubber,Enum.Material.Rubber)
		tread:SetAttribute("WheelRotates",true)
	end
	for _,side in {-1,1}do
		local rim=part("RimDisc"..side,Vector3.new(0.035,0.96,0.96),wheel*CFrame.new(side*0.365,0,0),steel,Enum.Material.Metal,Enum.PartType.Cylinder)
		rim:SetAttribute("WheelRotates",true)
		for index=0,5 do
			local spoke=part("HubSpoke"..side.."_"..index,Vector3.new(0.04,0.10,0.39),wheel*CFrame.Angles(index*math.pi/3,0,0)*CFrame.new(side*0.392,0,0.24),frame,Enum.Material.Metal)
			spoke:SetAttribute("WheelRotates",true)
		end
		part("AxleCap"..side,Vector3.new(0.08,0.28,0.28),wheel*CFrame.new(side*0.68,0,0),steel,Enum.Material.Metal,Enum.PartType.Cylinder)
	end
	local badge=part("MakerPlate",Vector3.new(1.2,0.42,0.025),model.TrayFront.CFrame*CFrame.new(0,0,0.077),frame,Enum.Material.Metal)
	local surface=Instance.new("SurfaceGui")surface.Name="Brand"surface.Face=Enum.NormalId.Back
	surface.CanvasSize=Vector2.new(300,100)surface.LightInfluence=0.5 surface.Parent=badge
	local text=Instance.new("TextLabel")text.Size=UDim2.fromScale(1,1)text.BackgroundTransparency=1
	text.Text="DTM  •  80"text.TextColor3=Color3.fromRGB(245,236,216)text.Font=Enum.Font.GothamBold text.TextScaled=true text.Parent=surface
	local sand=part("SandLoad",Vector3.new(2.9,1.1,2.45),CFrame.new(0,2.73,0.8),Color3.fromRGB(225,199,140),Enum.Material.Sand)
	local mound=Instance.new("SpecialMesh")mound.Name="SandMound"mound.MeshType=Enum.MeshType.Sphere mound.Parent=sand
	sand.Transparency=1
	model:SetAttribute("LoadBaseY",2.18)model:SetAttribute("LoadSize",Vector3.new(2.9,1.1,2.45))
	local grip=(model.HandleLeft.Position+model.HandleRight.Position)/2
	local minimum=math.huge
	for _,p in model:GetChildren()do if p:IsA("BasePart")then
		local half=(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2
		minimum=math.min(minimum,p.Position.Y-half)
	end end
	local root=part("GripRoot",Vector3.new(0.2,0.2,0.2),CFrame.new(grip)*CFrame.Angles(0,math.pi,0),frame,Enum.Material.Metal)
	root.Transparency=1 root.CastShadow=false model.PrimaryPart=root
	for _,side in {"Left","Right"}do
		local rail=model["Handle"..side]
		local target=Instance.new("Attachment")target.Name="GripTarget"target.Position=Vector3.new(0,0,-rail.Size.Z*0.4)target.Parent=rail
	end
	model:SetAttribute("GripHeight",grip.Y-minimum)
	model:SetAttribute("LoadBottom",root.CFrame:PointToObjectSpace(Vector3.new(sand.Position.X,2.18,sand.Position.Z)))
	model:SetAttribute("LoadRotation",root.CFrame:ToObjectSpace(sand.CFrame).Rotation)
	model:SetAttribute("WheelAnchor",root.CFrame:ToObjectSpace(tire.CFrame))
	return model
end
return Appearance
