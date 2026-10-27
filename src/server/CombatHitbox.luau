--!strict
-- RIFTBOUND Combat Overhaul 2.0 / server-only melee target resolution.
-- No client positions, damage values, or hit confirmations are accepted.
-- A short swept arc avoids single-frame misses; each Model is returned once.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Resolver = {}
local DEGREE_OFFSETS = {-0.19, 0, 0.19}
local MAX_SWING_TARGETS = 12

-- Accessory handles, weapons and layered rig parts can belong to nested Models.
-- Walk UP until a Humanoid+HumanoidRootPart pair belongs to the SAME model.
local function characterOf(part)
	local node = part
	while node and node ~= Workspace do
		if node:IsA("Model") then
			local humanoid = node:FindFirstChildOfClass("Humanoid")
			local root = node:FindFirstChild("HumanoidRootPart")
			if humanoid and root and root:IsA("BasePart") then
				return node, humanoid, root
			end
		end
		node = node.Parent
	end
	return nil
end

local function safeTarget(attacker, victim)
	if victim == attacker or victim:GetAttribute("RiftSafeZone") == true then return false end
	if attacker:GetAttribute("RiftSafeZone") == true then
		-- Dummy training on a protected ground still works. PvP does not.
		return Players:GetPlayerFromCharacter(victim) == nil
	end
	return true
end

function Resolver.Scan(attacker, attackerRoot, range, width, height, options)
	if not attacker or not attacker.Parent or not attackerRoot then return {} end
	options = options or {}
	local maxRange = math.clamp(tonumber(range) or 6, 1, 24)
	local boxWidth = math.clamp(tonumber(width) or 5, 1, 25)
	local boxHeight = math.clamp(tonumber(height) or 5, 1, 15)
	local minimumDot = math.clamp(tonumber(options.FrontDot) or -0.07, -0.5, 1)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {attacker}
	params.MaxParts = 0 -- unlimited overlap candidates; cap UNIQUE humanoid targets below
	local results, seen = {}, {}
	local facing = attackerRoot.CFrame.LookVector
	-- 3 box orientations sample the swing arc AT the server hit time. This
	-- tolerates sidesteps without turning the attack into a 360-degree AoE.
	for _, angle in DEGREE_OFFSETS do
		local arc = attackerRoot.CFrame * CFrame.Angles(0, angle, 0)
		local center = arc * CFrame.new(0, 0, -maxRange/2)
		for _, part in Workspace:GetPartBoundsInBox(center,
			Vector3.new(boxWidth, boxHeight, maxRange), params) do
			local victim, hum, root = characterOf(part)
			if victim and not seen[victim] then
				seen[victim] = true
				if hum.Health > 0 and safeTarget(attacker, victim) then
					local delta = root.Position - attackerRoot.Position
					local horizontal = Vector3.new(delta.X, 0, delta.Z)
					local distance = horizontal.Magnitude
					local toward = distance > 0.01 and facing:Dot(horizontal.Unit) or 1
					local maxDistance = maxRange + math.max(1.5, boxWidth * 0.35)
					if distance <= maxDistance and toward >= minimumDot
						and math.abs(delta.Y) <= boxHeight/2 + 4 then
						table.insert(results, {
							model = victim,
							humanoid = hum,
							root = root,
							distance = distance,
						})
						if #results >= MAX_SWING_TARGETS then return results end
					end
				end
			end
		end
	end
	return results
end

-- Attributes are shared across combat systems, so skill casts, NPC AI and
-- future abilities can honor stun without sharing private Lua state tables.
function Resolver.IsStunned(character)
	return character and (character:GetAttribute("RiftHitstunUntil") or 0)
		> Workspace:GetServerTimeNow() or false
end

function Resolver.Stagger(character, seconds)
	if not character or not character.Parent then return false end
	if character:GetAttribute("RiftTrainingDummy") == true then return false end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	local duration = math.clamp(tonumber(seconds) or 0, 0, 3)
	if duration <= 0 then return false end
	local untilTime = Workspace:GetServerTimeNow() + duration
	character:SetAttribute("RiftHitstunUntil",
		math.max(character:GetAttribute("RiftHitstunUntil") or 0, untilTime))
	if character:GetAttribute("RiftNPC") == true then
		character:SetAttribute("RiftNPCStunnedUntil",
			math.max(character:GetAttribute("RiftNPCStunnedUntil") or 0, os.clock() + duration))
	end
	return true
end

return Resolver
