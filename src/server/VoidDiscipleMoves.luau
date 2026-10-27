--!strict
-- Void Disciple rough-draft moveset. Entire combat calculation is server-owned.
-- Exists independently of Ashley so a Void skill failure cannot disable core combat.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local config = require(ReplicatedStorage.Riftbound.Shared.VoidDiscipleSpec)
local shield = require(script.Parent.PillShield)
local Hitbox = require(script.Parent.CombatHitbox)
local fx = ReplicatedStorage.Riftbound.Remotes:WaitForChild("SpecFX")
local Moves = {}

local states = setmetatable({}, {__mode = "k"})
local marks = setmetatable({}, {__mode = "k"})

local function timeNow()
	return Workspace:GetServerTimeNow()
end

local function ready(player, key)
	local state = states[player]
	if not state then
		state = {ready = {}}
		states[player] = state
	end
	local now = timeNow()
	if (state.ready[key] or 0) > now then return false end
	state.ready[key] = now + config.Abilities[key].Cooldown
	player:SetAttribute("Void" .. key .. "ReadyAt", state.ready[key])
	return true
end

local function active(player)
	if player:GetAttribute("EquippedSpec") ~= config.Id then return nil end
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not hum or not root or hum.Health <= 0
		or Hitbox.IsStunned(character) then return nil end
	return character, hum, root
end

local function burst(position, color, diameter)
	local part = Instance.new("Part")
	part.Name = "VoidBurstFX"
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 0.42
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = Vector3.one
	part.Position = position
	part.Parent = Workspace
	TweenService:Create(part, TweenInfo.new(0.38, Enum.EasingStyle.Quad), {
		Size = Vector3.new(diameter, diameter, diameter),
		Transparency = 1,
	}):Play()
	Debris:AddItem(part, 0.45)
end

local function nearby(origin, radius, character, facing, minDot, maximumDistance)
	local overlaps = OverlapParams.new()
	overlaps.FilterType = Enum.RaycastFilterType.Exclude
	overlaps.FilterDescendantsInstances = {character}
	local found = {}
	local output = {}
	for _, part in Workspace:GetPartBoundsInRadius(origin, radius, overlaps) do
		local target = part:FindFirstAncestorOfClass("Model")
		if target and not found[target] then
			found[target] = true
			local humanoid = target:FindFirstChildOfClass("Humanoid")
			local root = target:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0
				and target:GetAttribute("RiftSafeZone") ~= true then
				-- Each target needs a real Humanoid and a root near the radius center.
				local delta = root.Position - origin
				local withinRadius = delta.Magnitude <= radius + 1.5
				local validFacing = true
				if facing then
					local horiz = Vector3.new(delta.X, 0, delta.Z)
					validFacing = horiz.Magnitude < 0.15 or facing:Dot(horiz.Unit) >= (minDot or -1)
				end
				if withinRadius and validFacing and (not maximumDistance or delta.Magnitude <= maximumDistance) then
					table.insert(output, {model = target, humanoid = humanoid, root = root})
				end
			end
		end
	end
	return output
end

local function deal(player, entry, amount)
	local character = player.Character
	if not character or player:GetAttribute("EquippedSpec") ~= config.Id then return end
	local target = entry.model
	local hum = entry.humanoid
	if not target.Parent or hum.Health <= 0 then return end
	shield.Damage(target, hum, amount, player)
end

local function snare(target, hum, duration)
	if hum.Health <= 0 then return end
	local endsAt = timeNow() + duration
	local prior = hum.WalkSpeed
	target:SetAttribute("VoidSnaredUntil", endsAt)
	if target:GetAttribute("RiftNPC") == true then
		target:SetAttribute("RiftNPCStunnedUntil", os.clock() + duration)
	end
	hum.WalkSpeed = math.min(prior, 4)
	task.delay(duration, function()
		if hum.Parent and hum.Health > 0 and target:GetAttribute("VoidSnaredUntil") == endsAt then
			target:SetAttribute("VoidSnaredUntil", nil)
			if not target:GetAttribute("RiftBlocking") then
				hum.WalkSpeed = target:GetAttribute("RiftNPC") == true and 12 or 16
			end
		end
	end)
end

function Moves.OnHit(player, target)
	if player:GetAttribute("EquippedSpec") ~= config.Id then return end
	local hum = target and target:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	local old = marks[target]
	local currentTime = timeNow()
	local count = 1
	if old and old.attacker == player and old.untilTime > currentTime then count = old.count + 1 end
	if count < config.Passive.HitsToBurst then
		marks[target] = {attacker = player, count = count, untilTime = currentTime + config.Passive.MarkDuration}
		target:SetAttribute("VoidMarkStacks", count)
		fx:FireAllClients("VoidMark", target, count)
	else
		marks[target] = nil
		target:SetAttribute("VoidMarkStacks", 0)
		local entry = {model = target, humanoid = hum}
		deal(player, entry, config.Passive.BurstDamage)
		local char, ownHum = active(player)
		if char and ownHum then
			ownHum.Health = math.min(ownHum.MaxHealth, ownHum.Health + config.Passive.SelfHeal)
		end
		fx:FireAllClients("VoidBurst", target, config.Passive.BurstDamage)
		local root = target:FindFirstChild("HumanoidRootPart")
		if root then burst(root.Position, Color3.fromRGB(172, 90, 245), 6) end
	end
end

function Moves.Cast(player, key)
	if typeof(key) ~= "string" or not config.Abilities[key] then return false end
	local character, hum, root = active(player)
	if not character then return false end
	if character:GetAttribute("RiftBlocking") == true then return false end
	local ability = config.Abilities[key]
	if not ready(player, key) then return false end

	if key == "Z" then
		shield.Clear(character)
		character:SetAttribute("PillShieldHP", ability.ShieldHP)
		character:SetAttribute("PillShieldEnds", timeNow() + ability.Duration)
		character:SetAttribute("VoidGuardEnds", timeNow() + ability.Duration)
		burst(root.Position, Color3.fromRGB(106, 95, 254), 7)
		fx:FireAllClients("VoidGuard", character)
		local endsAt = character:GetAttribute("VoidGuardEnds")
		task.delay(ability.Duration, function()
			if character.Parent and character:GetAttribute("VoidGuardEnds") == endsAt then
				shield.Clear(character)
				character:SetAttribute("VoidGuardEnds", 0)
			end
		end)
	elseif key == "X" then
		local origin = root.Position
		local forward = root.CFrame.LookVector
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {character}
		local ray = Workspace:Raycast(origin + Vector3.new(0, 1.2, 0), forward * ability.Distance, rayParams)
		local distance = ray and math.max(0, (ray.Position - (origin + Vector3.new(0, 1.2, 0))).Magnitude - 3) or ability.Distance
		if distance > 0.5 then
			character:PivotTo(character:GetPivot() + forward * distance)
		end
		burst(origin, Color3.fromRGB(91, 179, 255), 4)
		burst(root.Position, Color3.fromRGB(91, 179, 255), 4)
		fx:FireAllClients("VoidStep", character)
	elseif key == "C" then
		local forward = root.CFrame.LookVector
		local center = root.Position + forward * 9
		burst(center, Color3.fromRGB(145, 94, 255), ability.Radius * 2)
		for _, target in nearby(center, ability.Radius, character) do
			local toTarget = target.root.Position - root.Position
			if toTarget.Magnitude <= ability.Range + 2 and toTarget.Magnitude > 0.01
				and forward:Dot(toTarget.Unit) >= 0.16 then
				deal(player, target, ability.Damage)
				snare(target.model, target.humanoid, ability.SnareDuration)
				fx:FireAllClients("VoidGrasp", target.model)
			end
		end
	elseif key == "V" then
		local forward = root.CFrame.LookVector
		local center = root.Position + forward * 7
		burst(center, Color3.fromRGB(180, 70, 255), ability.Radius * 2)
		for _, target in nearby(center, ability.Radius, character) do
			local difference = target.root.Position - root.Position
			if difference.Magnitude > 0.01 and difference.Magnitude <= ability.Range + 1
				and forward:Dot(difference.Unit) >= 0.1 then
				deal(player, target, ability.Damage)
				fx:FireAllClients("VoidCleave", target.model)
			end
		end
	elseif key == "G" then
		fx:FireAllClients("VoidNova", character)
		for pulse = 1, ability.Pulses do
			task.delay((pulse - 1) * ability.PulseInterval, function()
				if player.Character ~= character or player:GetAttribute("EquippedSpec") ~= config.Id
					or hum.Health <= 0 then return end
				local center = root.Position
				burst(center, Color3.fromRGB(115 + pulse * 24, 62, 255), ability.Radius * 2)
				for _, target in nearby(center, ability.Radius, character) do
					deal(player, target, ability.DamagePerPulse)
					if pulse == ability.Pulses then
						snare(target.model, target.humanoid, 1.25)
					end
				end
			end)
		end
	end
	return true
end

function Moves.StopPlayerBuffs(player)
	local character = player.Character
	if not character then return end
	if (character:GetAttribute("VoidGuardEnds") or 0) > timeNow() then
		shield.Clear(character)
		character:SetAttribute("VoidGuardEnds", 0)
	end
end

function Moves.ClearCharacter(character)
	if character then
		character:SetAttribute("VoidGuardEnds", 0)
	end
end

function Moves.ResetPlayer(player)
	states[player] = nil
	for key in config.Abilities do
		player:SetAttribute("Void" .. key .. "ReadyAt", 0)
	end
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

return Moves
