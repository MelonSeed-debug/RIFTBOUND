-- RIFTBOUND / Enemy AI 2.0 — read-only Studio smoke checks.
-- Run from the SERVER Command Bar while a Server & Clients test is playing.
-- Does NOT teleport, damage NPCs, mutate saves, or alter the game world.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local rift = ReplicatedStorage:FindFirstChild("Riftbound")
assert(rift and rift:FindFirstChild("Shared"),
	"Missing Riftbound/Shared. Confirm Rojo server is connected.")
local world = require(rift.Shared.WorldConfig)
local combat = require(rift.Shared.CombatConfig)
assert(world.Mode == "OpenWorld",
	"Expected OpenWorld. Replace local src and restart Rojo.")
assert(combat.NPC.Enabled == true,
	"Curated PvE NPCs are disabled in CombatConfig.")

local server = ServerScriptService:FindFirstChild("RiftboundServer")
assert(server and server:FindFirstChild("NPCNavigation"),
	"NPCNavigation.luau not synced; replace the entire src folder.")
assert(server:FindFirstChild("CombatNPCs"), "CombatNPCs.luau missing.")

local folder = Workspace:FindFirstChild("RIFTBOUND Enemies")
assert(folder, "Enemy folder missing. Check Server Output for startup failures.")

local counts = {
	Idle = 0, Fight = 0, Chase = 0, Return = 0,
	Stunned = 0, Spawning = 0, Other = 0,
}
local total = 0
local failures = 0
for _, npc in folder:GetChildren() do
	if npc:IsA("Model") and npc:GetAttribute("RiftNPC") then
		total += 1
		local state = npc:GetAttribute("RiftNPCState")
		local archetype = npc:GetAttribute("RiftNPCArchetype")
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		local root = npc:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			failures += 1
			warn("[AI CHECK] Malformed R15 NPC:", npc.Name)
		end
		if state and counts[state] ~= nil then
			counts[state] += 1
		else
			counts.Other += 1
		end
		if archetype ~= "Skirmisher" and archetype ~= "Guardian" then
			warn("[AI CHECK] Unknown/default archetype:", npc.Name, archetype)
		end
	end
end

local haven, protected = world.GetZoneAt(Vector3.zero)
assert(haven == world.Hub.Id and protected == true,
	"Haven is not safe according to WorldConfig.GetZoneAt.")
for _, zone in world.Zones do
	local actual, safe = world.GetZoneAt(zone.Center)
	assert(actual == zone.Id and safe == false,
		"World zone ID mismatch: "..zone.Id)
end

print("=== RIFTBOUND ENEMY AI 2.0 CHECK ===")
print("Hostile NPCs:", total, "/ configured", #world.EnemySpawns)
print("AI states:","Idle",counts.Idle,"Chase",counts.Chase,"Fight",counts.Fight,
	"Return",counts.Return,"Stunned",counts.Stunned,
	"Spawning",counts.Spawning,"Other",counts.Other)
print("Malformed NPC rigs:", failures)
print("Vertical detection threshold:",combat.NPC.VerticalDetectRange or 20)
print("Detection range:",combat.NPC.DetectRange,
	"Leash range:",combat.NPC.LeashRange)
print("AI is SERVER-owned; no client reports hit positions or destinations.")

if total < #world.EnemySpawns then
	warn("Some NPCs are still generating or failed. Wait for R15 avatar loading, then rerun.")
end
print("LIVE TEST STILL REQUIRED: lure a hostile around a rock, enter Haven, parry")
print("an attack mid-windup, break line of sight, then watch its Return/Idle states.")
