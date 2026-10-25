--!strict
-- Ashley Simmons: automatic passive prototype. Server-side effect authority.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cfg = require(ReplicatedStorage.Riftbound.Shared.AshleySimmonsSpec).Passive
local fx = ReplicatedStorage.Riftbound.Remotes.SpecFX
local Passive = {}
local magazines = {}
local rng = Random.new()
local names = {"ChillPill","Euphoria","AdrenalineRush","AntiInflammatory","MoodStabilizer"}

local function ammoState(player)
	if not magazines[player] then magazines[player] = {ammo=cfg.Ammo, next=0, reloading=false} end
	return magazines[player]
end

function Passive.Reset(player)
	magazines[player] = nil
	player:SetAttribute("PillAmmo", cfg.Ammo)
end

function Passive.OnHit(player, target)
	if player:GetAttribute("EquippedSpec") ~= "AshleySimmons" then return end
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	local root = target:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return end
	local st = ammoState(player)
	local now = os.clock()
	if st.reloading or now < st.next then return end
	st.next = now + cfg.TriggerCooldown
	st.ammo -= 1
	player:SetAttribute("PillAmmo", st.ammo)
	local name = names[rng:NextInteger(1, #names)]
	local effect = cfg.Effects[name]
	local expires = now + effect.Duration
	local key = "Pill_" .. name
	target:SetAttribute(key, expires)
	-- Never override a longer instance of the same status.
	fx:FireAllClients("PillImpact", target, name)
	humanoid:TakeDamage(cfg.Damage)
	if name == "ChillPill" then
		local old = humanoid.WalkSpeed
		humanoid.WalkSpeed = math.max(6, old * (1 - effect.Amount))
		task.delay(effect.Duration, function()
			if humanoid.Parent and target:GetAttribute(key) == expires then
				humanoid.WalkSpeed = old
				target:SetAttribute(key, nil)
			end
		end)
	elseif name == "MoodStabilizer" then
		-- Heal exactly 5% of max health over three seconds.
		for i=1,3 do
			task.delay(i, function()
				if humanoid.Parent and humanoid.Health > 0 then
					humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + humanoid.MaxHealth * effect.HealMaxHealthFraction / 3)
				end
			end)
		end
	else
		task.delay(effect.Duration, function()
			if target.Parent and target:GetAttribute(key) == expires then target:SetAttribute(key,nil) end
		end)
	end
	if st.ammo <= 0 then
		st.reloading = true
		task.delay(cfg.ReloadSeconds, function()
			if magazines[player] ~= st then return end
			st.ammo = cfg.Ammo
			st.reloading = false
			player:SetAttribute("PillAmmo", st.ammo)
		end)
	end
end

Players.PlayerRemoving:Connect(function(player) magazines[player] = nil end)
return Passive
