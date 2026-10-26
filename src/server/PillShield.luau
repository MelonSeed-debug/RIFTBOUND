--!strict
-- Ashley's Pill Shield: server-authoritative absorption for RIFTBOUND combat.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local cfg = require(ReplicatedStorage.Riftbound.Shared.AshleySimmonsSpec).Abilities.Z
local Shield = {}
local cooldowns = setmetatable({}, {__mode="k"})
local generations = setmetatable({}, {__mode="k"})

function Shield.Clear(character)
	if not character then return end
	generations[character] = (generations[character] or 0) + 1
	character:SetAttribute("PillShieldHP", 0)
	character:SetAttribute("PillShieldEnds", 0)
end

function Shield.Activate(player)
	if player:GetAttribute("EquippedSpec") ~= "AshleySimmons" then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	local now = workspace:GetServerTimeNow()
	if now < (cooldowns[player] or 0) then return false end
	cooldowns[player] = now + cfg.Cooldown
	Shield.Clear(character)
	local generation = generations[character]
	character:SetAttribute("PillShieldHP", cfg.ShieldHP)
	character:SetAttribute("PillShieldEnds", now + cfg.Duration)
	player:SetAttribute("PillShieldReadyAt", cooldowns[player])
	task.delay(cfg.Duration, function()
		if character.Parent and generations[character] == generation then
			Shield.Clear(character)
		end
	end)
	return true
end

function Shield.Damage(target, humanoid, amount, attacker)
	if not humanoid or humanoid.Health <= 0 or amount <= 0 then return 0 end
	-- Haven is a true player safe zone. The training dummy is intentionally
	-- still attackable, but PvP and NPC damage to players inside is disallowed.
	local victimPlayer = Players:GetPlayerFromCharacter(target)
	if victimPlayer and target:GetAttribute("RiftSafeZone") == true then return 0 end
	if victimPlayer and attacker and attacker.Character
		and attacker.Character:GetAttribute("RiftSafeZone") == true then return 0 end
	local time = workspace:GetServerTimeNow()
	-- Shared server damage calculation for Spec status effects.
	local attackerCharacter = attacker and attacker.Character
	if attackerCharacter then
		if (attackerCharacter:GetAttribute("Pill_AdrenalineRush") or 0) > os.clock() then
			amount *= 1.20
		end
		if (attackerCharacter:GetAttribute("Pill_AntiInflammatory") or 0) > os.clock() then
			amount *= 0.95
		end
		if (attackerCharacter:GetAttribute("FrenzyEuphoriaEnds") or 0) > time then
			amount *= 0.90 -- Rough-draft weakening strength.
		end
	end
	if (target:GetAttribute("Pill_AdrenalineRush") or 0) > os.clock() then
		amount *= 1.10
	end
	-- Damage resistance is calculated on the server before shield absorption.
	local resistanceEnds = target:GetAttribute("BuzzBoostEnds")
	local resistance = target:GetAttribute("BuzzBoostResistance")
	if typeof(resistanceEnds) == "number" and workspace:GetServerTimeNow() < resistanceEnds and typeof(resistance) == "number" then
		amount *= 1 - math.clamp(resistance, 0, 0.9)
	end
	local hp = target:GetAttribute("PillShieldHP")
	local expires = target:GetAttribute("PillShieldEnds")
	if typeof(hp) == "number" and hp > 0 and typeof(expires) == "number" and workspace:GetServerTimeNow() < expires then
		local absorbed = math.min(hp, amount)
		target:SetAttribute("PillShieldHP", hp - absorbed)
		if hp - absorbed <= 0 then Shield.Clear(target) end
		amount -= absorbed
	end
	if amount > 0 then
		-- Tag only real NPC health damage; shield-only hits earn no kill credit.
		-- Set attributes BEFORE TakeDamage so Humanoid.Died can identify the killer.
		if target:GetAttribute("RiftNPC") == true and attacker and attacker:IsA("Player") then
			target:SetAttribute("RiftLastAttackerId", attacker.UserId)
			target:SetAttribute("RiftLastHitAt", time)
		end
		humanoid:TakeDamage(amount)
	end
	return amount
end

function Shield.ResetPlayer(player)
	cooldowns[player] = nil
	player:SetAttribute("PillShieldReadyAt", 0)
end

return Shield
