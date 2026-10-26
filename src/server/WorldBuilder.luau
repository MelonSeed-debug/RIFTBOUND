--!strict
-- RIFTBOUND Practice Field v3: intentionally minimal flat grass.
-- Existing v2 island maps live under Workspace/RIFTBOUND World; the server
-- replaces that generated folder on Play. Bake in Studio Edit mode + Save
-- to permanently replace an old baked map.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local World = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)

local Builder = {}
local started = false
local rootFolder
local origin = Vector3.zero
local groundY = 0

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

local function hideDefaultBaseplate()
	-- Only the stock large Baseplate is hidden. Custom user scenery is intact.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart")
		and baseplate.Size.X >= 200 and baseplate.Size.Z >= 200 then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
		baseplate.CanQuery = false
		baseplate:SetAttribute("RiftWorldHiddenBaseplate", true)
	end
end

local function cleanupOldGeneratedWorld()
	local old = Workspace:FindFirstChild(World.WorldName)
	if old and (old:GetAttribute("Version") or 0) < World.Version then
		warn("[RIFTBOUND Field] Replacing generated island world v" ..
			tostring(old:GetAttribute("Version")) .. " with flat grass.")
		old:Destroy()
		-- These folders were made by server scripts for the old map. They
		-- must be rebuilt around spawn, not left at the former island coords.
		for _, name in {"RIFTBOUND Quest Hub", "RIFTBOUND Story Characters"} do
			local generated = Workspace:FindFirstChild(name)
			if generated then generated:Destroy() end
		end
	end
end

local function buildField()
	local existing = Workspace:FindFirstChild(World.WorldName)
	if existing and (existing:GetAttribute("Version") or 0) >= World.Version then
		rootFolder = existing
		resolveOrigin(existing)
		hideDefaultBaseplate()
		return rootFolder, false
	end

	resolveOrigin(existing)
	cleanupOldGeneratedWorld()
	local folder = Instance.new("Folder")
	folder.Name = World.WorldName
	folder.Parent = Workspace
	folder:SetAttribute("GroundY", groundY)
	folder:SetAttribute("SpawnX", origin.X)
	folder:SetAttribute("SpawnZ", origin.Z)
	folder:SetAttribute("WorldStyle", "Flat Grass / Combat Prototype")

	local grass = Instance.new("Part")
	grass.Name = "FLAT GRASS — EDITABLE FIELD"
	grass.Size = Vector3.new(World.FieldSize, 2, World.FieldSize)
	grass.Position = Vector3.new(origin.X, groundY - 1, origin.Z)
	grass.Anchored = true
	grass.CanCollide = true
	grass.CanTouch = false
	grass.CanQuery = true
	grass.TopSurface = Enum.SurfaceType.Smooth
	grass.BottomSurface = Enum.SurfaceType.Smooth
	grass.Material = Enum.Material.Grass
	grass.Color = World.GrassColor
	grass.Parent = folder

	if not spawnPart() then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "RIFTBOUND Spawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Material = Enum.Material.Grass
		spawn.Color = World.GrassColor
		spawn.Neutral = true
		spawn.Position = Vector3.new(origin.X, groundY + 0.5, origin.Z)
		spawn.Parent = folder
	end

	-- Mark the version only once generation is complete. This prevents an
	-- interrupted script from being mistaken for a finished baked field.
	folder:SetAttribute("Version", World.Version)
	rootFolder = folder
	hideDefaultBaseplate()
	print("[RIFTBOUND Field] Flat grass ready; no islands, bridges or map decorations.")
	return folder, true
end

local function daylight()
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(155, 155, 155)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0
	local oldGrade = Lighting:FindFirstChild("RiftboundWorldGrade")
	if oldGrade and oldGrade:IsA("PostEffect") then oldGrade:Destroy() end
end

local function trackCombatField()
	local function update(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		-- No global safe zone: players can test combat together on the grass.
		if character:GetAttribute("RiftSafeZone") ~= false then
			character:SetAttribute("RiftSafeZone", false)
		end
		if player:GetAttribute("RiftZone") ~= "PracticeField" then
			player:SetAttribute("RiftZone", "PracticeField")
		end
	end
	local function watch(player)
		player.CharacterAdded:Connect(function()
			task.defer(update, player)
		end)
		update(player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
	task.spawn(function()
		while rootFolder and rootFolder.Parent do
			for _, player in Players:GetPlayers() do update(player) end
			task.wait(0.5)
		end
	end)
end

-- Studio Edit Mode Command Bar:
-- require(game.ServerScriptService.RiftboundServer.WorldBuilder).Bake()
-- Then save/publish the place. Old generated islands will be gone permanently.
function Builder.Bake()
	local field, created = buildField()
	daylight()
	return field, created
end

function Builder.Start()
	if started then return end
	started = true
	local ok, err = pcall(buildField)
	if not ok then
		warn("[RIFTBOUND Field] Could not prepare grass:", err)
		return
	end
	daylight()
	trackCombatField()
end

return Builder
