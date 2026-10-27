-- RIFTBOUND Open World 1.0 / read-only Studio verification.
-- Run in Roblox Studio Command Bar DURING PLAY on the SERVER.
-- Nothing here edits the place or changes player saves.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:FindFirstChild("Riftbound")
assert(shared and shared:FindFirstChild("Shared"),
	"Riftbound/Shared missing. Start rojo serve and reconnect Studio.")
local World = require(shared.Shared.WorldConfig)
assert(World.Version >= 4 and World.Mode == "OpenWorld",
	"Old WorldConfig still synced. Replace full src and restart Rojo.")

local map = Workspace:FindFirstChild(World.WorldName)
assert(map,"Generated world folder missing! Check [RIFTBOUND World] in Server Output.")
local version = map:GetAttribute("Version")
assert(version == World.Version,
	"World v"..tostring(version).." is incomplete/outdated. Restart Play and inspect Server Output.")
assert(map:GetAttribute("WorldStyle") == "Contiguous Open World",
	"World folder is the old testing field, not the open-world generator.")

local biomes = map:FindFirstChild("Terrain / Biomes")
assert(biomes, "Biome terrain folder missing. WorldBuilder may have raised an error.")
local roads = map:FindFirstChild("Roads / Continuous Travel")
assert(roads, "Continuous roads are missing.")

local spawnedEnemies = Workspace:FindFirstChild("RIFTBOUND Enemies")
local enemyCount = spawnedEnemies and #spawnedEnemies:GetChildren() or 0
local pending = #World.EnemySpawns - enemyCount

print("=== RIFTBOUND OPEN WORLD CHECK ===")
print("Version:",version, "| World:",World.Mode, "| Size:",World.FieldSize)
print("Biomes configured:",#World.Zones,"| Roads:",#World.Roads,
	"| Arena foundations:",#World.BossSites)
print("Enemy spawns configured:",#World.EnemySpawns,
	"| Currently instantiated:",enemyCount)
if pending > 0 then
	warn("Enemy rigs missing:",pending,
		"(may still be generating R15 appearances, or the NPC service failed)")
end

for _, player in Players:GetPlayers() do
	local character=player.Character
	print("Player:",player.Name,
		"Zone:",player:GetAttribute("RiftZone"),
		"Safe:",character and character:GetAttribute("RiftSafeZone"),
		"Progress:",player:GetAttribute("ProgressLoadState"),
		"EquippedSpec:",player:GetAttribute("EquippedSpec"))
end

print("NO dialogue actors or boss AI are required for this foundation.")
print("Pass: world geometry present. Next check travel, quests and combat in Play.")
