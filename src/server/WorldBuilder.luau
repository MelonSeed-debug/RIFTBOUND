--!strict
-- RIFTBOUND / NEW BEGINNING : deterministic, Studio-only starter world blockout.
-- All positions are relative to the current SpawnLocation so Rojo works in existing places.
-- Roads and plazas are kept open for R15 players and existing combat NPCs.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local World = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)

local Builder = {}
local started = false
local rootPosition = Vector3.zero
local floorY = 0
local hub = World.Hub
local rootFolder
local color = {
	asphalt = Color3.fromRGB(33, 37, 53),
	curb = Color3.fromRGB(71, 79, 100),
	plaza = Color3.fromRGB(52, 57, 84),
	hub = Color3.fromRGB(37, 47, 67),
	old = Color3.fromRGB(63, 57, 64),
	iron = Color3.fromRGB(58, 62, 66),
	rift = Color3.fromRGB(44, 36, 76),
	white = Color3.fromRGB(242, 223, 201),
	gold = Color3.fromRGB(255, 180, 105),
	blue = Color3.fromRGB(108, 206, 240),
	purple = Color3.fromRGB(182, 108, 255),
}

local function pos(x, y, z)
	return Vector3.new(rootPosition.X + x, floorY + y, rootPosition.Z + z)
end

local function part(parent, name, xyz, size, tint, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(xyz)
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.CanTouch = false
	p.CanQuery = collide ~= false
	p.Material = material or Enum.Material.Concrete
	p.Color = tint
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function folder(parent, name)
	local node = Instance.new("Folder")
	node.Name = name
	node.Parent = parent
	return node
end

local function sign(adornee, message, height, size, tint)
	local gui = Instance.new("BillboardGui")
	gui.Name = "WorldLandmark"
	gui.Size = UDim2.fromOffset(size or 290, height or 66)
	gui.StudsOffsetWorldSpace = Vector3.new(0, (adornee.Size.Y / 2) + 2.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 195
	gui.Adornee = adornee
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Name = "LocationLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Text = message
	label.TextColor3 = tint or color.white
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 8)
	round.Parent = label
	return gui
end

local function glow(partObj, tint, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = tint
	light.Range = range or 16
	light.Brightness = brightness or 1.2
	light.Shadows = false
	light.Parent = partObj
end

local function neon(parent, name, at, size, tint)
	return part(parent, name, at, size, tint, Enum.Material.Neon, false)
end

local function ground(parent, id, startZ, endZ, tint)
	local center = (startZ + endZ) / 2
	return part(parent, id .. " Terrain", pos(0, -0.36, center),
		Vector3.new(150, 0.8, math.abs(endZ - startZ)), tint, Enum.Material.Slate)
end

local function lane(parent)
	part(parent, "Main Boulevard", pos(0, 0.16, -192),
		Vector3.new(23, 0.25, 516), color.asphalt, Enum.Material.Asphalt)
	for _, side in {-1, 1} do
		part(parent, side < 0 and "West Sidewalk" or "East Sidewalk", pos(side*24, 0.25, -192),
			Vector3.new(13, 0.36, 516), color.curb, Enum.Material.Concrete)
		neon(parent, "Lane Edge", pos(side*10.5, 0.31, -192),
			Vector3.new(0.26, 0.08, 516), color.gold)
	end
	for z = -436, 54, 18 do
		neon(parent, "Lane Mark", pos(0, 0.33, z), Vector3.new(0.5, 0.07, 6), color.white)
	end
	for _, z in {-38, -149, -278} do
		for x = -9, 9, 3 do
			neon(parent, "Crosswalk", pos(x, 0.36, z), Vector3.new(1.25, 0.08, 6), color.white)
		end
	end
end

local function building(parent, name, x, z, width, depth, height, tint, accent, doorText)
	local side = x < 0 and 1 or -1
	local body = part(parent, name .. " Block", pos(x, height/2 + 0.2, z),
		Vector3.new(width, height, depth), tint, Enum.Material.Concrete)
	part(parent, name .. " Roof", pos(x, height + 0.5, z),
		Vector3.new(width+2, 0.65, depth+2), color.asphalt, Enum.Material.Metal)
	neon(parent, name .. " Roof Trim", pos(x + side*(width/2+0.05), height + 0.2, z),
		Vector3.new(0.32, 0.4, depth+1), accent)
	-- Neon shop windows face the open side street; collision belongs to the solid building.
	for dz = -1, 1, 2 do
		local windowX = x + side*(width/2 + 0.05)
		local windowZ = z + dz*depth*0.24
		neon(parent, name .. " Street Window", pos(windowX, math.min(height - 2.5, 6), windowZ),
			Vector3.new(0.16, 3, 3.8), accent)
	end
	if doorText then
		local labelX = x + side*(width/2 + 0.35)
		local plate = neon(parent, name .. " Entrance", pos(labelX, 4, z),
			Vector3.new(0.45, 4.8, 4.5), accent)
		sign(plate, doorText .. "\nCOMING SOON", 62, 170, color.white)
	end
	return body
end

local function streetlamp(parent, x, z, tint)
	part(parent, "Streetlamp Pole", pos(x, 7, z), Vector3.new(0.6, 14, 0.6),
		Color3.fromRGB(80, 86, 111), Enum.Material.Metal)
	local cap = neon(parent, "Streetlamp Glow", pos(x, 14.5, z),
		Vector3.new(2.5, 1, 2.5), tint)
	glow(cap, tint, 19, 1.4)
end

local function gate(parent, z, label, level, tint)
	for _, side in {-1, 1} do
		local column = part(parent, "District Gate Pillar", pos(side*19, 11, z),
			Vector3.new(3, 22, 4), color.asphalt, Enum.Material.Metal)
		neon(parent, "District Gate Light", pos(side*19, 11, z-2.1),
			Vector3.new(0.5, 16, 0.3), tint)
	end
	local beam = part(parent, "District Entry Arch", pos(0, 22.5, z),
		Vector3.new(40, 2.5, 4), color.asphalt, Enum.Material.Metal)
	neon(parent, "District Beam Light", pos(0, 21.7, z-2.2),
		Vector3.new(37, 0.4, 0.45), tint)
	sign(beam, label .. "\nRECOMMENDED LEVEL " .. level .. "+", 72, 420, tint)
end

local function wall(parent, name, x, z, size, tint)
	return part(parent, name, pos(x, size.Y/2 + 0.15, z),
		size, tint, Enum.Material.Brick)
end

local function oldQuarter(parent)
	local dark = Color3.fromRGB(80, 68, 77)
	local dark2 = Color3.fromRGB(68, 68, 83)
	for _, side in {-1, 1} do
		for i, z in {-59, -95, -131} do
			local height = (i % 2 == 0) and 25 or 18
			building(parent, "Old Quarter " .. side .. " " .. i,
				side*55, z, 24, 26, height,
				i % 2 == 0 and dark2 or dark, color.gold)
		end
		for _, z in {-55, -90, -125} do
			streetlamp(parent, side*32, z, color.gold)
		end
	end
	-- Open alleys and warm shop fronts reinforce the street-fighter zone.
	neon(parent, "Quarter Herald", pos(-32, 0.45, -80),
		Vector3.new(1.8, 0.12, 25), color.gold)
	neon(parent, "Quarter Herald", pos(32, 0.45, -115),
		Vector3.new(1.8, 0.12, 25), color.gold)
end

local function ironworks(parent)
	local iron = Color3.fromRGB(69, 77, 83)
	for _, side in {-1, 1} do
		for i, z in {-171, -210, -252} do
			building(parent, "Forge Factory " .. side .. " " .. i,
				side*58, z, 28, 32, 29 + i*4,
				iron, i % 2 == 0 and color.gold or color.blue)
		end
		for _, z in {-178, -218, -256} do
			streetlamp(parent, side*32, z, color.blue)
		end
		for _, z in {-179, -221} do
			-- Crate stacks stay beyond the 23-stud highway; no combat path obstruction.
			part(parent, "Factory Crate", pos(side*38, 2.5, z),
				Vector3.new(5, 5, 5), Color3.fromRGB(145, 96, 69), Enum.Material.Wood)
			part(parent, "Factory Crate Stack", pos(side*38, 7.5, z),
				Vector3.new(4, 5, 4), Color3.fromRGB(120, 82, 60), Enum.Material.Wood)
		end
	end
	-- A dedicated arena pad behind the Sentinel's combat lane.
	local arena = part(parent, "Sentinel Arena Floor", pos(0, 0.22, -255),
		Vector3.new(36, 0.25, 36), Color3.fromRGB(70, 45, 102), Enum.Material.Slate)
	neon(parent, "Sentinel Arena Border", pos(0, 0.38, -237),
		Vector3.new(36, 0.08, 0.8), color.purple)
	neon(parent, "Sentinel Arena Border", pos(0, 0.38, -273),
		Vector3.new(36, 0.08, 0.8), color.purple)
end

local function riftCrystal(parent, x, z, height, tint)
	local core = neon(parent, "Rift Crystal", pos(x, height/2, z),
		Vector3.new(2.4, height, 2.4), tint)
	core.CFrame = core.CFrame * CFrame.Angles(0, 0, math.rad(x < 0 and 12 or -12))
	glow(core, tint, 20, 1.7)
	part(parent, "Rift Base", pos(x, 1, z),
		Vector3.new(7, 2, 7), Color3.fromRGB(63, 52, 90), Enum.Material.Slate)
end

local function riftExpanse(parent)
	for _, side in {-1, 1} do
		for i, z in {-305, -339, -376, -425} do
			local tint = i % 2 == 0 and color.purple or Color3.fromRGB(255, 104, 204)
			riftCrystal(parent, side*(41+i%3*6), z, 12+i%3*6, tint)
			if i % 2 == 0 then
				riftCrystal(parent, side*60, z-12, 7, color.blue)
			end
		end
		-- Ruined colonnades provide silhouettes without trapping the NPC AI.
		for _, z in {-322, -365, -411} do
			wall(parent, "Ruined Wall", side*65, z,
				Vector3.new(4, 16, 14), Color3.fromRGB(68, 52, 100))
		end
	end
	local breach = neon(parent, "Veil Boundary", pos(0, 6, -444),
		Vector3.new(43, 12, 0.45), color.purple)
	breach.Transparency = 0.52
	sign(breach, "THE VEIL\nMORE WORLD COMING SOON", 62, 360, color.purple)
end

local function plaza(parent)
	part(parent, "Spawn Plaza", pos(0, 0.24, 18),
		Vector3.new(67, 0.26, 68), color.plaza, Enum.Material.Marble)
	for _, side in {-1, 1} do
		for _, z in {-20, 24} do
			building(parent, side < 0 and "Haven Apothecary" or "Haven Gear Depot",
				side*55, z, 22, 25, 22, color.hub,
				side < 0 and color.purple or color.blue,
				z == 24 and (side < 0 and "APOTHECARY" or "GEAR DEPOT") or nil)
		end
		streetlamp(parent, side*31, 35, color.blue)
		streetlamp(parent, side*31, -21, color.purple)
	end
	-- The 500-HP training dummy remains usable at (0, -12) in the hub.
	local monument = part(parent, "Riftbound Monument", pos(0, 3, 38),
		Vector3.new(3, 6, 3), color.purple, Enum.Material.Neon, false)
	glow(monument, color.purple, 25, 1.7)
	sign(monument, "RIFTBOUND\nNEW BEGINNING", 80, 310, color.white)
	-- Wayfinding signs are interactive but the other two businesses are not shops yet.
end

local function notify(player, message)
	player:SetAttribute("RiftWorldMessage", message)
	player:SetAttribute("RiftWorldMessageId", (player:GetAttribute("RiftWorldMessageId") or 0) + 1)
end

local function travelPad(parent, name, label, location, destination, minLevel, tint)
	local circle = part(parent, name .. " Platform",
		pos(location.X, 0.43, location.Z),
		Vector3.new(8, 0.55, 8), color.asphalt, Enum.Material.Metal, false)
	local light = neon(parent, name .. " Beacon",
		pos(location.X, 0.8, location.Z),
		Vector3.new(6, 0.12, 6), tint)
	glow(light, tint, 11, 0.8)
	sign(circle, label .. "\nLEVEL " .. minLevel .. "+", 58, 220, tint)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Travel"
	prompt.ActionText = "Fast Travel"
	prompt.ObjectText = label
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.15
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = circle
	prompt.Triggered:Connect(function(player)
		local level = player:GetAttribute("Level") or 1
		if player:GetAttribute("ProgressLoaded") ~= true then
			notify(player, "Progress still loading. Try again shortly.")
			return
		end
		if level < minLevel then
			notify(player, "Fast travel requires Level " .. minLevel .. ".")
			return
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not char or not root or not hum or hum.Health <= 0 then return end
		local landing = pos(destination.X, 4.5, destination.Z)
		char:PivotTo(CFrame.lookAt(landing, landing + Vector3.new(0, 0, -1)))
		root.AssemblyLinearVelocity = Vector3.zero
		notify(player, "Travelled to " .. label .. ".")
	end)
end

local function buildTravel(parent)
	local padX = {-28, 0, 28}
	for i, destination in World.Travel do
		travelPad(parent, "Hub Travel " .. destination.Id, destination.Name,
			Vector3.new(padX[i], 0, 54), destination.Destination,
			destination.RequiredLevel, World.Zones[i].Color)
		-- Return-to-hub beacon sits outside enemy spawn/quest interaction areas.
		travelPad(parent, "Return from " .. destination.Id, "RETURN TO HAVEN",
			Vector3.new(34, 0, destination.Destination.Z - 12),
			Vector3.new(0, 0, 25), 1, color.blue)
	end
end

local function trackLocations()
	local function update(player)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local x = root.Position.X - rootPosition.X
		local z = root.Position.Z - rootPosition.Z
		local safe = math.abs(x) <= hub.HalfWidth and z >= hub.StartZ and z <= hub.EndZ
		if char:GetAttribute("RiftSafeZone") ~= safe then char:SetAttribute("RiftSafeZone", safe) end
		local id = "Outskirts"
		if safe then id = hub.Id
		elseif math.abs(x) <= 78 then
			for _, zone in World.Zones do
				if z >= zone.StartZ and z < zone.EndZ then
					id = zone.Id
					break
				end
			end
		end
		if player:GetAttribute("RiftZone") ~= id then
			player:SetAttribute("RiftZone", id)
		end
	end
	local function hookPlayer(player)
		player.CharacterAdded:Connect(function()
			task.defer(update, player)
		end)
		update(player)
	end
	Players.PlayerAdded:Connect(hookPlayer)
	for _, player in Players:GetPlayers() do hookPlayer(player) end
	task.spawn(function()
		while rootFolder and rootFolder.Parent do
			for _, player in Players:GetPlayers() do update(player) end
			task.wait(0.3)
		end
	end)
end

function Builder.Start()
	if started or (World.StudioOnly and not RunService:IsStudio()) then return false end
	if Workspace:FindFirstChild(World.WorldName) then
		warn("[RIFTBOUND World] World folder already exists. Skipping duplicate blockout.")
		return false
	end
	started = true
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	rootPosition = spawn and spawn.Position or Vector3.new(0, 0, 0)

	local sample = Workspace:Raycast(rootPosition + Vector3.new(29, 80, 30),
		Vector3.new(0, -250, 0))
	floorY = sample and sample.Position.Y or
		(spawn and spawn.Position.Y - spawn.Size.Y / 2 or 0)

	rootFolder = folder(Workspace, World.WorldName)
	rootFolder:SetAttribute("Version", World.Version)
	rootFolder:SetAttribute("GroundY", floorY)
	rootFolder:SetAttribute("SpawnX", rootPosition.X)
	rootFolder:SetAttribute("SpawnZ", rootPosition.Z)

	local hubGroup = folder(rootFolder, "00 HAVEN - SAFE HUB")
	ground(hubGroup, "Haven", hub.StartZ, hub.EndZ, color.hub)
	plaza(hubGroup)

	local roadGroup = folder(rootFolder, "00 ROADS & WAYFINDING")
	lane(roadGroup)
	local quarter = folder(rootFolder, "01 OLD QUARTER (LEVEL 1-10)")
	ground(quarter, "Old Quarter", -150, -40, color.old)
	oldQuarter(quarter)
	gate(quarter, -44, "OLD QUARTER", "1-10", color.gold)
	local iron = folder(rootFolder, "02 IRONWORKS (LEVEL 10-25)")
	ground(iron, "Ironworks", -280, -150, color.iron)
	ironworks(iron)
	gate(iron, -154, "IRONWORKS", "10-25", color.blue)
	local rift = folder(rootFolder, "03 RIFT EXPANSE (LEVEL 25-50)")
	ground(rift, "Rift Expanse", -450, -280, color.rift)
	riftExpanse(rift)
	gate(rift, -284, "RIFT EXPANSE", "25-50", color.purple)
	local travel = folder(rootFolder, "FAST TRAVEL")
	buildTravel(travel)
	trackLocations()

	if RunService:IsStudio() then
		Lighting.ClockTime = 18.7
		Lighting.Brightness = 2.2
		Lighting.Ambient = Color3.fromRGB(100, 90, 142)
		Lighting.OutdoorAmbient = Color3.fromRGB(85, 98, 145)
	end
	print("[RIFTBOUND World] Haven hub, three districts, signs, roads and fast travel generated.")
	return true
end

return Builder
