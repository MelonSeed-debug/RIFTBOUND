--!strict
-- RIFTBOUND Open World 1.0. Contiguous, deterministic, server-built geometry.
-- Versioned folder can be baked in Studio Edit mode; no client terrain trust.
-- This builds landscapes and *empty* boss arena sites, not story/NPC dialogue.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local World = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)

local Builder = {}
local started = false
local rootFolder
local origin = Vector3.zero
local groundY = 0
local TWO_PI = math.pi * 2

local function spawnPart()
	return Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
end

local function resolveOrigin(previous)
	local spawn = spawnPart()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if previous and typeof(previous:GetAttribute("SpawnX")) == "number"
		and typeof(previous:GetAttribute("SpawnZ")) == "number" then
		origin = Vector3.new(previous:GetAttribute("SpawnX"), 0,
			previous:GetAttribute("SpawnZ"))
	else
		origin = spawn and spawn.Position or Vector3.zero
	end
	if previous and typeof(previous:GetAttribute("GroundY")) == "number" then
		groundY = previous:GetAttribute("GroundY")
	elseif baseplate and baseplate:IsA("BasePart") then
		groundY = baseplate.Position.Y + baseplate.Size.Y / 2
	else
		groundY = spawn and spawn.Position.Y - spawn.Size.Y / 2 or 0
	end
end

local function worldAt(offset, lift)
	return Vector3.new(origin.X + offset.X,
		groundY + (lift or offset.Y), origin.Z + offset.Z)
end

local function folder(parent, name)
	local result = Instance.new("Folder")
	result.Name = name
	result.Parent = parent
	return result
end

local function part(parent, name, position, size, color, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.CanCollide = collide ~= false
	p.CanTouch = false
	p.CanQuery = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function disc(parent, name, where, radius, thickness, color, material)
	local d = part(parent, name, where, Vector3.new(thickness, radius*2, radius*2),
		color, material, true)
	d.Shape = Enum.PartType.Cylinder
	d.CFrame = CFrame.new(where) * CFrame.Angles(0, 0, math.pi / 2)
	return d
end

local function nearestOnSegment(point, a, b)
	local vector = b - a
	local denominator = vector:Dot(vector)
	if denominator < 0.001 then return (point - a).Magnitude end
	local t = math.clamp((point - a):Dot(vector) / denominator, 0, 1)
	return (point - (a + vector*t)).Magnitude
end

local function distanceToRoad(point)
	local nearest = math.huge
	for _, road in World.Roads do
		for i = 1, #road.Points-1 do
			nearest = math.min(nearest, nearestOnSegment(point,
				road.Points[i], road.Points[i+1]))
		end
	end
	return nearest
end

local function reserved(point)
	-- Decorative obstacles must never obstruct spawn, roads, challenge rings,
	-- or hand-placed server NPC locations. All calculations are local to Haven.
	local flat = Vector3.new(point.X,0,point.Z)
	if flat.Magnitude < World.SafeRadius + 20 then return true end
	if distanceToRoad(flat) < 32 then return true end
	for _, site in World.BossSites do
		if (site.Position - flat).Magnitude < site.Radius + 30 then return true end
	end
	for _, enemy in World.EnemySpawns do
		if (enemy.Offset - flat).Magnitude < 23 then return true end
	end
	return false
end

local function woodland(parent, where, rng)
	local height = rng:NextNumber(13, 23)
	local trunk = part(parent,"Ancient Trunk",worldAt(where,height/2),
		Vector3.new(height,2.5,2.5),Color3.fromRGB(72,54,45),
		Enum.Material.Wood,true)
	trunk.Shape = Enum.PartType.Cylinder
	trunk.CFrame = CFrame.new(trunk.Position) * CFrame.Angles(0,0,math.pi/2)
	local crown = part(parent,"Canopy",worldAt(where,height+3),
		Vector3.new(10+rng:NextNumber(2,7),10,11),
		Color3.fromRGB(45+rng:NextInteger(0,22),106+rng:NextInteger(0,25),69),
		Enum.Material.Grass,false)
	crown.Shape = Enum.PartType.Ball
end

local function ashland(parent, where, rng)
	local height = rng:NextNumber(5, 17)
	local rock = part(parent,"Obsidian Outcrop",worldAt(where,height/2),
		Vector3.new(rng:NextNumber(5,10),height,rng:NextNumber(4,9)),
		Color3.fromRGB(57+rng:NextInteger(0,21),50,55),
		Enum.Material.Basalt,true)
	rock.Orientation = Vector3.new(rng:NextNumber(-10,10),rng:NextNumber(0,360),rng:NextNumber(-14,14))
	if rng:NextNumber() > 0.45 then
		local ember = part(parent,"Ember Vein",worldAt(where,height+0.8),
			Vector3.new(1.4,3.1,1.4),Color3.fromRGB(255,122,73),
			Enum.Material.Neon,false)
		ember.Shape = Enum.PartType.Ball
	end
end

local function highlands(parent, where, rng)
	local height = rng:NextNumber(5, 14)
	local stone = part(parent,"Weathered Standing Stone",worldAt(where,height/2),
		Vector3.new(rng:NextNumber(3,7),height,rng:NextNumber(3,6)),
		Color3.fromRGB(112+rng:NextInteger(0,28),125,119),
		Enum.Material.Slate,true)
	stone.Orientation = Vector3.new(rng:NextNumber(-8,8),rng:NextNumber(0,360),rng:NextNumber(-8,8))
	local lichen = part(parent,"Lichen",worldAt(where,height+0.2),
		Vector3.new(4.5,0.45,4.5),Color3.fromRGB(129,169,126),
		Enum.Material.Grass,false)
	lichen.Orientation = stone.Orientation
end

local function fractured(parent, where, rng)
	local height = rng:NextNumber(8, 24)
	local crystal = part(parent,"Rift Crystal",worldAt(where,height/2),
		Vector3.new(rng:NextNumber(3,7),height,rng:NextNumber(3,7)),
		Color3.fromRGB(113+rng:NextInteger(0,55),69,170+rng:NextInteger(0,55)),
		Enum.Material.Glass,true)
	crystal.Orientation = Vector3.new(rng:NextNumber(-15,15),rng:NextNumber(0,360),
		rng:NextNumber(-18,18))
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(183,121,255)
	glow.Brightness = 0.65
	glow.Range = 16
	glow.Parent = crystal
end

local function scatterProps(zone, parent, index)
	local rng = Random.new(World.Seed + index*1277)
	local created = 0
	local attempts = 0
	while created < zone.PropCount and attempts < zone.PropCount*20 do
		attempts += 1
		local r = math.sqrt(rng:NextNumber()) * (zone.Radius-20)
		local angle = rng:NextNumber(0,TWO_PI)
		local offset = zone.Center + Vector3.new(math.cos(angle)*r,0,math.sin(angle)*r)
		if not reserved(offset) then
			if zone.Theme == "Forest" then woodland(parent,offset,rng)
			elseif zone.Theme == "Ash" then ashland(parent,offset,rng)
			elseif zone.Theme == "Highlands" then highlands(parent,offset,rng)
			elseif zone.Theme == "Rift" then fractured(parent,offset,rng) end
			created += 1
		end
	end
end

local function createRoads(parent)
	local roads = folder(parent,"Roads / Continuous Travel")
	for _, road in World.Roads do
		for i=1,#road.Points-1 do
			local startPoint = worldAt(road.Points[i],0.28)
			local endPoint = worldAt(road.Points[i+1],0.28)
			local midpoint = (startPoint+endPoint)/2
			local length = (endPoint-startPoint).Magnitude
			local slab = part(roads,road.Id.." Segment "..i,midpoint,
				Vector3.new(road.Width,0.22,length+3),
				Color3.fromRGB(132,116,94),Enum.Material.Ground,true)
			slab.CFrame = CFrame.lookAt(midpoint,endPoint)
		end
	end
end

local function marker(parent, name, point, subtext, color)
	local post = part(parent,name.." Marker",worldAt(point,4),
		Vector3.new(1.1,8,1.1),Color3.fromRGB(61,55,51),Enum.Material.Wood,true)
	local plaque = part(parent,name.." Waystone",worldAt(point,8.5),
		Vector3.new(12,5,1.2),Color3.fromRGB(42,40,52),Enum.Material.Slate,true)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Region Sign"
	billboard.Adornee = plaque
	billboard.Size = UDim2.fromOffset(260,72)
	billboard.StudsOffsetWorldSpace = Vector3.new(0,4.5,0)
	billboard.MaxDistance = 185
	billboard.AlwaysOnTop = false
	billboard.Parent = plaque
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1,1)
	label.Text = name.."\n"..subtext
	label.TextSize = 18
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.1
	label.Parent = billboard
	return post
end

local function buildHaven(parent)
	local safe = folder(parent,"Haven / Safe Origin")
	disc(safe,"Haven Stone Platform",worldAt(Vector3.zero,0.21),
		93,0.42,Color3.fromRGB(163,154,126),Enum.Material.Cobblestone)
	disc(safe,"Haven Inner Circle",worldAt(Vector3.zero,0.47),
		50,0.12,Color3.fromRGB(101,113,114),Enum.Material.Slate)
	for i=1,10 do
		local a = TWO_PI*i/10
		local localPos = Vector3.new(math.cos(a)*103,0,math.sin(a)*103)
		local pillar = part(safe,"Haven Pillar "..i,worldAt(localPos,7),
			Vector3.new(5,14,5),Color3.fromRGB(132,128,120),
			Enum.Material.Slate,true)
		if i%2 == 0 then
			part(safe,"Beacon "..i,pillar.Position+Vector3.new(0,7.5,0),
				Vector3.new(3,2,3),Color3.fromRGB(250,209,139),
				Enum.Material.Neon,false)
		end
	end
	marker(safe,"HAVEN",Vector3.new(-72,0,22),"SAFE HAVEN  /  WORLD ORIGIN",
		Color3.fromRGB(243,212,153))
end

local function buildBossSite(parent, site)
	local pad = folder(parent,site.Id.." / Arena Foundation")
	disc(pad,site.Name.." Floor",worldAt(site.Position,0.23),site.Radius,0.40,
		Color3.fromRGB(74,70,85),Enum.Material.Slate)
	disc(pad,site.Name.." Ring",worldAt(site.Position,0.48),site.Radius-9,0.06,
		Color3.fromRGB(106,98,123),Enum.Material.Rock)
	for i=1,12 do
		local a = TWO_PI*i/12
		local offset = site.Position + Vector3.new(math.cos(a)*(site.Radius+1),0,
			math.sin(a)*(site.Radius+1))
		part(pad,"Ancient Ring Pillar "..i,worldAt(offset,6),
			Vector3.new(5.5,12,5.5),Color3.fromRGB(65,59,74),
			Enum.Material.Basalt,true)
	end
	-- No bosses, kill triggers, quest flags, prompts or teleports in this stage.
	marker(pad,site.Name,site.Position+Vector3.new(0,0,-site.Radius-22),
		"CHALLENGE SITE  /  FUTURE BOSS ENCOUNTER",
		Color3.fromRGB(214,172,247))
end

local function hideDefaultBaseplate()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart")
		and baseplate.Size.X >= 200 and baseplate.Size.Z >= 200 then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
		baseplate.CanQuery = false
		baseplate:SetAttribute("RiftWorldHiddenBaseplate",true)
	end
end

-- Version 3's quest kiosks and prewritten dialogue actors were created
-- outside the versioned map folder. They can survive a baked-place upgrade.
-- Move them to ServerStorage instead of deleting users' legacy content.
local function archivePausedLegacyObjects()
	local names = {}
	if World.EnableStoryActors == false then
		table.insert(names, "RIFTBOUND Story Characters")
	end
	if World.EnableQuestStations == false then
		table.insert(names, "RIFTBOUND Quest Hub")
	end
	for _, name in names do
		local old = Workspace:FindFirstChild(name)
		if old and old:IsA("Folder") then
			local archive = ServerStorage:FindFirstChild("RIFTBOUND Archived World Objects")
			if not archive then
				archive = Instance.new("Folder")
				archive.Name = "RIFTBOUND Archived World Objects"
				archive.Parent = ServerStorage
			end
			-- Keep an existing archive instead of silently overwriting it.
			-- New legacy folders receive unique Roblox names in storage.
			old.Name = name .. " (paused from world v3)"
			old.Parent = archive
			warn("[RIFTBOUND World] Archived legacy world NPC/station folder:", name)
		end
	end
end

local function ensureSpawn(parent)
	local spawn = spawnPart()
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "RIFTBOUND Haven Spawn"
		spawn.Size = Vector3.new(9,1,9)
		spawn.Anchored = true
		spawn.Material = Enum.Material.Slate
		spawn.Color = Color3.fromRGB(147,137,119)
		spawn.Neutral = true
		spawn.Position = worldAt(Vector3.zero,1.15)
		spawn.Parent = parent
	end
end

local function buildWorld()
	local previous = Workspace:FindFirstChild(World.WorldName)
	resolveOrigin(previous)
	archivePausedLegacyObjects()
	if previous and (previous:GetAttribute("Version") or 0) >= World.Version
		and previous:GetAttribute("WorldStyle") == "Contiguous Open World" then
		rootFolder = previous
		hideDefaultBaseplate()
		return previous, false
	end

	if previous then
		warn("[RIFTBOUND World] Replacing generated world v",
			previous:GetAttribute("Version") or "unknown","with open world v",World.Version)
		previous:Destroy()
	end

	local world = folder(Workspace,World.WorldName)
	world:SetAttribute("SpawnX",origin.X)
	world:SetAttribute("SpawnZ",origin.Z)
	world:SetAttribute("GroundY",groundY)
	world:SetAttribute("WorldStyle","Building...")
	world:SetAttribute("Seed",World.Seed)
	world:SetAttribute("WorldMode",World.Mode)

	-- One collidable floor across ALL regions and roads: never teleport to
	-- transition between ordinary biomes. Tinted discs are shallow overlays.
	local landscape = folder(world,"Terrain / Biomes")
	local ground = part(landscape,"CONTIGUOUS OVERWORLD BASE",
		worldAt(Vector3.zero,-2),Vector3.new(World.FieldSize,4,World.FieldSize),
		World.GrassColor,Enum.Material.Grass,true)
	ground:SetAttribute("RiftOpenWorldBase",true)
	for index,zone in World.Zones do
		local biomeFolder = folder(landscape,zone.Name)
		disc(biomeFolder,zone.Id.." Ground",worldAt(zone.Center,0.03),
			zone.Radius,0.25,zone.Color,Enum.Material.Grass)
		scatterProps(zone,biomeFolder,index)
		marker(biomeFolder,zone.Name,zone.Center+Vector3.new(-20,0,35),
			"RECOMMENDED LEVEL "..zone.RecommendedLevel.."+",
			zone.Accent)
	end

	-- Roads render above painted biome ground; nodes are end-to-end.
	createRoads(world)
	buildHaven(world)
	local sites = folder(world,"Future Boss Grounds")
	for _,site in World.BossSites do buildBossSite(sites,site) end
	ensureSpawn(world)
	hideDefaultBaseplate()
	world:SetAttribute("WorldStyle","Contiguous Open World")
	world:SetAttribute("Version",World.Version) -- mark complete LAST
	rootFolder = world
	print("[RIFTBOUND World] OPEN WORLD READY | 4 regions, 6 roads, Haven and 3 boss sites.")
	return world, true
end

local function daylight()
	Lighting.ClockTime = 13.4
	Lighting.Brightness = 2.25
	Lighting.Ambient = Color3.fromRGB(127,137,150)
	Lighting.OutdoorAmbient = Color3.fromRGB(163,175,181)
	Lighting.FogStart = 620
	Lighting.FogEnd = 1900
	Lighting.FogColor = Color3.fromRGB(166,183,184)
end

local function trackZones()
	local function update(player)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local localPosition = Vector3.new(root.Position.X - origin.X,0,
			root.Position.Z - origin.Z)
		local zone, safe = World.GetZoneAt(localPosition)
		if char:GetAttribute("RiftSafeZone") ~= safe then
			char:SetAttribute("RiftSafeZone",safe)
		end
		if player:GetAttribute("RiftZone") ~= zone then
			player:SetAttribute("RiftZone",zone)
			local config = zone == World.Hub.Id and World.Hub or World.ZoneById(zone)
			player:SetAttribute("RiftZoneName",config and config.Name or "WILDERNESS")
			player:SetAttribute("RiftZoneEnteredAt",Workspace:GetServerTimeNow())
		end
	end
	local function watch(player)
		player.CharacterAdded:Connect(function()
			task.defer(update,player)
		end)
		update(player)
	end
	Players.PlayerAdded:Connect(watch)
	for _,player in Players:GetPlayers() do watch(player) end
	task.spawn(function()
		while rootFolder and rootFolder.Parent do
			for _,player in Players:GetPlayers() do update(player) end
			task.wait(0.45)
		end
	end)
end

-- Studio Edit Mode: require(game.ServerScriptService.RiftboundServer.WorldBuilder).Bake()
-- Save/publish afterward if the generated map should be kept in the .rbxl.
function Builder.Bake()
	local result, created = buildWorld()
	daylight()
	return result, created
end

function Builder.Start()
	if started then return end
	started = true
	local ok,err = pcall(buildWorld)
	if not ok then
		warn("[RIFTBOUND World] Overworld generation failed:",err)
		started = false
		return
	end
	daylight()
	trackZones()
end

return Builder
