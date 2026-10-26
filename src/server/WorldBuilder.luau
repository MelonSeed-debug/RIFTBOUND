--!strict
-- RIFTBOUND World v2: permanent/editable island recreation of the approved concept.
-- Can be generated during Play, or baked in Studio EDIT MODE via:
-- require(game.ServerScriptService.RiftboundServer.WorldBuilder).Bake()
-- Save the place after baking. This folder is not managed/deleted by Rojo.
-- Runtime wiring attaches fast travel to both generated and saved maps.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local World = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)
local Visuals = require(script.Parent.WorldVisuals)

local Builder = {}
local started = false
local origin = Vector3.zero
local groundY = 0
local builtFolder
local boundPrompts = setmetatable({}, {__mode="k"})
local COLORS = {
	ocean = Color3.fromRGB(17, 45, 73),
	cliff = Color3.fromRGB(42, 51, 70),
	haven = Color3.fromRGB(57, 72, 105),
	quarter = Color3.fromRGB(67, 77, 79),
	iron = Color3.fromRGB(69, 59, 60),
	rift = Color3.fromRGB(58, 44, 89),
	stone = Color3.fromRGB(36, 47, 66),
	blue = Color3.fromRGB(89, 189, 255),
}

local function P(x,y,z)
	return Vector3.new(origin.X+x,groundY+y,origin.Z+z)
end
local function part(parent,name,worldPosition,size,tint,material,collide)
	local object=Instance.new("Part")
	object.Name=name
	object.Anchored=true
	object.Size=size
	object.Position=worldPosition
	object.Color=tint
	object.Material=material or Enum.Material.Concrete
	object.TopSurface=Enum.SurfaceType.Smooth
	object.BottomSurface=Enum.SurfaceType.Smooth
	object.CanCollide=collide~=false
	object.CanTouch=false
	object.CanQuery=collide~=false
	object.Parent=parent
	return object
end
local function neon(parent,name,worldPosition,size,tint)
	return part(parent,name,worldPosition,size,tint,Enum.Material.Neon,false)
end
local function group(parent,name)
	local f=Instance.new("Folder")
	f.Name=name
	f.Parent=parent
	return f
end
local function light(obj,tint,range,brightness)
	local p=Instance.new("PointLight")
	p.Name="District Glow"
	p.Color=tint
	p.Range=range or 18
	p.Brightness=brightness or 1.3
	p.Shadows=false
	p.Parent=obj
	return p
end
local function sign(target,message,width,height,tint)
	local board=Instance.new("BillboardGui")
	board.Name="District Sign"
	board.Adornee=target
	board.AlwaysOnTop=true
	board.MaxDistance=205
	board.Size=UDim2.fromOffset(width or 260,height or 55)
	board.StudsOffsetWorldSpace=Vector3.new(0,target.Size.Y/2+3,0)
	board.Parent=target
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(1,1)
	label.Text=message
	label.TextColor3=tint or Color3.new(1,1,1)
	label.BackgroundColor3=Color3.fromRGB(14,19,35)
	label.BackgroundTransparency=0.14
	label.BorderSizePixel=0
	label.Font=Enum.Font.GothamBold
	label.TextStrokeTransparency=0.45
	label.TextWrapped=true
	label.TextScaled=true
	label.Parent=board
	local round=Instance.new("UICorner")
	round.CornerRadius=UDim.new(0,8)
	round.Parent=label
	return board
end
local function path(parent,name,a,b,width,accent,baseMaterial,baseTint)
	-- Roads run from a to b on the common island surface with no invisible walls.
	local start=P(a.X,0.95,a.Z)
	local finish=P(b.X,0.95,b.Z)
	local length=(finish-start).Magnitude
	if length<0.5 then return end
	local direction=(finish-start).Unit
	local midpoint=(start+finish)/2
	local frame=CFrame.lookAt(midpoint,midpoint+direction)
	local road=part(parent,name,midpoint,Vector3.new(width,0.37,length+2),
		baseTint or Color3.fromRGB(40,49,66),baseMaterial or Enum.Material.Asphalt)
	road.CFrame=frame
	for _,side in {-1,1} do
		local stripe=neon(parent,name.." / Edge Glow",
			midpoint,Vector3.new(0.23,0.08,length),accent)
		stripe.CFrame=frame*CFrame.new(side*(width/2-1),0.25,0)
	end
	for z=-length/2+8,length/2-6,12 do
		local marking=neon(parent,name.." / Road Marker",
			midpoint,Vector3.new(0.37,0.08,4),Color3.fromRGB(200,203,218))
		marking.CFrame=frame*CFrame.new(0,0.24,z)
	end
	return road
end
local function bridge(parent,data)
	local a,b=data.From,data.To
	local start=P(a.X,0.85,a.Z)
	local finish=P(b.X,0.85,b.Z)
	local direction=(finish-start).Unit
	local length=(finish-start).Magnitude
	local center=(start+finish)/2
	local cf=CFrame.lookAt(center,center+direction)
	local road=part(parent,data.Name.." / Driveable Bridge",center,
		Vector3.new(data.Width,0.9,length+2),
		Color3.fromRGB(46,52,65),Enum.Material.Metal)
	road.CFrame=cf
	road:SetAttribute("RiftBridge",true)
	for _,side in {-1,1} do
		local sideStripe=neon(parent,data.Name.." / Edge Lighting",center,
			Vector3.new(0.55,0.18,length),data.Accent)
		sideStripe.CFrame=cf*CFrame.new(side*(data.Width/2-1),0.59,0)
		local railing=part(parent,data.Name.." / Bridge Rail",center,
			Vector3.new(0.65,2.6,length),
			Color3.fromRGB(81,93,113),Enum.Material.Metal)
		railing.CFrame=cf*CFrame.new(side*(data.Width/2+0.25),1.85,0)
		for z=-length/2+6,length/2-5,18 do
			local support=part(parent,data.Name.." / Rail Post",center,
				Vector3.new(0.9,3.4,0.9),
				Color3.fromRGB(106,113,125),Enum.Material.Metal)
			support.CFrame=cf*CFrame.new(side*(data.Width/2+0.25),1.9,z)
		end
	end
	for z=-length/2+8,length/2-6,15 do
		local segment=neon(parent,data.Name.." / Center Line",center,
			Vector3.new(0.47,0.08,5),data.Accent)
		segment.CFrame=cf*CFrame.new(0,0.55,z)
	end
	local plaque=neon(parent,data.Name.." / Wayfinding",center+Vector3.new(0,0.9,0),
		Vector3.new(0.25,0.2,0.25),data.Accent)
	sign(plaque,data.Name,280,48,data.Accent)
	return road
end

local function island(parent,id,center,radius,tint,seed)
	-- Wide circular solid rock slab, with irregular cliff chunks near the coast.
	-- Gameplay terrain is solid and continuous under every marked NPC encounter.
	local region=group(parent,id)
	local main=part(region,id.." / Playable Ground",
		P(center.X,-9.25,center.Z),
		Vector3.new(20,radius*2,radius*2),tint,Enum.Material.Slate)
	main.Shape=Enum.PartType.Cylinder
	main.CFrame=main.CFrame*CFrame.Angles(0,0,math.rad(90))
	local rng=Random.new(seed)
	for index=1,24 do
		local theta=2*math.pi*(index/24)
		local radial=radius*rng:NextNumber(0.89,1.04)
		local x=center.X+math.cos(theta)*radial
		local z=center.Z+math.sin(theta)*radial
		local chunk=part(region,id.." / Coastline Rock",
			P(x,-5+rng:NextNumber(-4,3),z),
			Vector3.new(rng:NextNumber(15,27),rng:NextNumber(15,28),rng:NextNumber(13,24)),
			COLORS.cliff,Enum.Material.Slate,false)
		chunk.Shape=Enum.PartType.Ball
	end
	local trim=neon(region,id.." / Island Beacon",P(center.X,1.3,center.Z),
		Vector3.new(2,0.4,2),tint)
	light(trim,tint,12,0.4)
	return region
end

local function ocean(parent)
	local sea=part(parent,"DARK WATER / DEEP OCEAN",P(75,World.WaterLevel,-195),
		Vector3.new(1350,1.5,1050),COLORS.ocean,Enum.Material.Glass)
	sea.Transparency=0.31
	sea.Reflectance=0.16
	-- Shallow stone bed prevents accidentally falling forever if a player drops off.
	part(parent,"Drowned Bedrock",P(75,World.WaterLevel-11,-195),
		Vector3.new(1350,2,1050),Color3.fromRGB(18,26,39),Enum.Material.Slate)
end

local function getSpawn()
	-- Existing spawn establishes stable shared coordinates across the modules.
	local spawn=Workspace:FindFirstChildWhichIsA("SpawnLocation",true)
	return spawn
end
local function readOrigin(existing)
	if existing then
		groundY=existing:GetAttribute("GroundY") or 0
		origin=Vector3.new(existing:GetAttribute("SpawnX") or 0,groundY,
			existing:GetAttribute("SpawnZ") or 0)
		return
	end
	local spawn=getSpawn()
	origin=spawn and spawn.Position or Vector3.zero
	local samples=RaycastParams.new()
	samples.FilterType=Enum.RaycastFilterType.Exclude
	if spawn then samples.FilterDescendantsInstances={spawn} end
	local sample=Workspace:Raycast(origin+Vector3.new(25,75,23),Vector3.new(0,-210,0),samples)
	groundY=sample and sample.Position.Y or (spawn and spawn.Position.Y-spawn.Size.Y/2 or 0)
end

local function hideBaseplate()
	if not World.HideDefaultBaseplate then return end
	local baseplate=Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart")
		and baseplate.Size.X>=200 and baseplate.Size.Z>=200 then
		baseplate.Transparency=1
		baseplate.CanCollide=false
		baseplate.CanQuery=false
		baseplate:SetAttribute("RiftWorldHiddenBaseplate",true)
	end
end

local function createTravelPad(parent,id,label,place,destination,required,tint)
	local platform=part(parent,id.." / Travel Platform",
		P(place.X,1.05,place.Z),Vector3.new(9,0.6,9),
		Color3.fromRGB(35,45,65),Enum.Material.Metal)
	platform:SetAttribute("RiftTravelDestination",destination)
	platform:SetAttribute("RiftTravelLabel",label)
	platform:SetAttribute("RiftTravelLevel",required)
	local centerLight=neon(parent,id.." / Travel Rune",
		P(place.X,1.39,place.Z),Vector3.new(6.8,0.15,6.8),tint)
	light(centerLight,tint,16,1)
	local tower=neon(parent,id.." / Gateway Sign",
		P(place.X,3.2,place.Z),Vector3.new(0.5,3,0.5),tint)
	tower.CanCollide=false
	sign(tower,label.."\nLEVEL "..required.."+",210,55,tint)
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name="Travel"
	prompt.ActionText="Fast Travel"
	prompt.ObjectText=label
	prompt.KeyboardKeyCode=Enum.KeyCode.E
	prompt.HoldDuration=0.15
	prompt.MaxActivationDistance=12
	prompt.RequiresLineOfSight=false
	prompt.Parent=platform
	return platform
end

local function buildTravel(parent)
	local hubPlaces={
		Vector3.new(-22,0,-32),
		Vector3.new(0,0,-42),
		Vector3.new(22,0,-32),
	}
	for index,entry in World.Travel do
		local tint=World.Zones[index].Color
		createTravelPad(parent,"Haven to "..entry.Id,entry.Name,
			hubPlaces[index],entry.Destination,entry.RequiredLevel,tint)
		createTravelPad(parent,entry.Id.." to Haven","RETURN TO HAVEN",
			entry.ReturnPad,Vector3.new(0,0,-8),1,COLORS.blue)
	end
end

local function createGeometry()
	-- This can run in Studio Edit Mode without starting the game.
	-- Save the place once, then Studio and published servers reuse these parts.
	readOrigin(nil)
	hideBaseplate()
	local existing=Workspace:FindFirstChild(World.WorldName)
	if existing then
		if (existing:GetAttribute("Version") or 0)>=World.Version then
			builtFolder=existing
			readOrigin(existing)
			return existing,false
		end
		warn("[RIFTBOUND World] Replacing older generated World v" ..
			tostring(existing:GetAttribute("Version")) .. " with concept v" .. World.Version)
		existing:Destroy()
	end
	local root=group(Workspace,World.WorldName)
	root:SetAttribute("Version",World.Version)
	root:SetAttribute("GroundY",groundY)
	root:SetAttribute("SpawnX",origin.X)
	root:SetAttribute("SpawnZ",origin.Z)
	root:SetAttribute("RiftWorldBaked",true)
	root:SetAttribute("WorldStyle","Four island concept / neon fantasy")
	local sea=group(root,"00 SEA & ISLAND CLIFFS")
	ocean(sea)
	island(sea,"Haven Island",World.Hub.Center,World.Hub.Radius,COLORS.haven,1337)
	for index,zone in World.Zones do
		local shade=({COLORS.quarter,COLORS.iron,COLORS.rift})[index]
		island(sea,zone.Name.." Island",zone.Center,zone.Radius,shade,1000+index*77)
	end
	local routes=group(root,"00 BRIDGES & PRIMARY PATHS")
	for _,data in World.Bridges do bridge(routes,data) end
	local api={P=P,Part=part,Neon=neon,Group=group,Sign=sign,Light=light,Path=path}
	Visuals.Build(api,root)
	local travel=group(root,"05 FAST TRAVEL / LEVEL-GATED")
	buildTravel(travel)
	builtFolder=root
	print("[RIFTBOUND World] CONCEPT MAP v"..World.Version..
		" created: 4 islands, 4 bridges, Haven nexus, city, foundries, Rift citadel.")
	return root,true
end

local function notify(player,message)
	player:SetAttribute("RiftWorldMessage",message)
	player:SetAttribute("RiftWorldMessageId",(player:GetAttribute("RiftWorldMessageId") or 0)+1)
end

local function wireFastTravel()
	if not builtFolder then return end
	for _,descendant in builtFolder:GetDescendants() do
		if descendant:IsA("BasePart") then
			local destination=descendant:GetAttribute("RiftTravelDestination")
			local prompt=descendant:FindFirstChild("Travel")
			if typeof(destination)=="Vector3" and prompt and prompt:IsA("ProximityPrompt")
				and not boundPrompts[prompt] then
				boundPrompts[prompt]=true
				prompt.Triggered:Connect(function(player)
					local required=descendant:GetAttribute("RiftTravelLevel") or 1
					if player:GetAttribute("ProgressLoaded")~=true then
						notify(player,"Progress loading. Try again shortly.")
						return
					end
					if (player:GetAttribute("Level") or 1)<required then
						notify(player,"Requires Level "..required..".")
						return
					end
					local char=player.Character
					local hum=char and char:FindFirstChildOfClass("Humanoid")
					local root=char and char:FindFirstChild("HumanoidRootPart")
					if not hum or hum.Health<=0 or not root then return end
					local landing=P(destination.X,5,destination.Z)
					char:PivotTo(CFrame.lookAt(landing,landing+Vector3.new(0,0,-1)))
					root.AssemblyLinearVelocity=Vector3.zero
					notify(player,"Arrived: "..tostring(descendant:GetAttribute("RiftTravelLabel")))
				end)
			end
		end
	end
end

local function trackLocations()
	local function update(player)
		local char=player.Character
		local root=char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local localPoint=root.Position-Vector3.new(origin.X,groundY,origin.Z)
		local zoneId,safe=World.GetZoneAt(localPoint)
		if char:GetAttribute("RiftSafeZone")~=safe then
			char:SetAttribute("RiftSafeZone",safe)
		end
		if player:GetAttribute("RiftZone")~=zoneId then
			player:SetAttribute("RiftZone",zoneId)
		end
	end
	local function setupPlayer(player)
		player.CharacterAdded:Connect(function()
			task.defer(update,player)
		end)
		update(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	for _,player in Players:GetPlayers() do setupPlayer(player) end
	task.spawn(function()
		while builtFolder and builtFolder.Parent do
			for _,player in Players:GetPlayers() do update(player) end
			task.wait(0.25)
		end
	end)
end

local function atmosphere()
	Lighting.ClockTime=19.1
	Lighting.Brightness=2.25
	Lighting.Ambient=Color3.fromRGB(100,99,145)
	Lighting.OutdoorAmbient=Color3.fromRGB(78,94,138)
	Lighting.FogColor=Color3.fromRGB(34,30,64)
	Lighting.FogEnd=940
	Lighting.FogStart=260
	Lighting.EnvironmentDiffuseScale=0.48
	Lighting.EnvironmentSpecularScale=0.54
	local tint=Lighting:FindFirstChild("RiftboundWorldGrade")
	if not tint then
		tint=Instance.new("ColorCorrectionEffect")
		tint.Name="RiftboundWorldGrade"
		tint.Parent=Lighting
	end
	tint.Saturation=0.12
	tint.Contrast=0.17
	tint.Brightness=-0.025
	tint.TintColor=Color3.fromRGB(216,222,255)
end

-- Run from command bar in Studio *Edit Mode*, then File > Save.
-- Once baked the map is real, editable Workspace geometry (and can be moved).
function Builder.Bake()
	local root,created=createGeometry()
	atmosphere()
	return root,created
end

function Builder.Start()
	if started then return end
	started=true
	local root=Workspace:FindFirstChild(World.WorldName)
	if root and (root:GetAttribute("Version") or 0)>=World.Version then
		builtFolder=root
		readOrigin(root)
	elseif World.GenerateIfMissing then
		local ok,result=pcall(createGeometry)
		if ok then
			builtFolder=result
		else
			warn("[RIFTBOUND World] World build failed; existing combat remains intact:",result)
			return
		end
	else
		warn("[RIFTBOUND World] World was not baked and generation is disabled.")
		return
	end
	atmosphere()
	hideBaseplate()
	wireFastTravel()
	trackLocations()
	print("[RIFTBOUND World] " .. World.WorldName ..
		" v" .. World.Version .. " loaded. B opens World Guide; E uses travel pads.")
end

return Builder
