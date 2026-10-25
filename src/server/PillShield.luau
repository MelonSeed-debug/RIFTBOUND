--!strict
-- Ashley's Pill Shield: server-authoritative absorption for RIFTBOUND combat.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function Shield.Damage(target, humanoid, amount)
	if not humanoid or humanoid.Health <= 0 or amount <= 0 then return 0 end
	local hp = target:GetAttribute("PillShieldHP")
	local expires = target:GetAttribute("PillShieldEnds")
	if typeof(hp) == "number" and hp > 0 and typeof(expires) == "number" and workspace:GetServerTimeNow() < expires then
		local absorbed = math.min(hp, amount)
		target:SetAttribute("PillShieldHP", hp - absorbed)
		if hp - absorbed <= 0 then Shield.Clear(target) end
		amount -= absorbed
	end
	if amount > 0 then humanoid:TakeDamage(amount) end
	return amount
end

function Shield.ResetPlayer(player)
	cooldowns[player] = nil
	player:SetAttribute("PillShieldReadyAt", 0)
end

return Shield
