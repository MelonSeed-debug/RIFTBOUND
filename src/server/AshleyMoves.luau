--!strict
-- Ashley's remaining rough-draft skills. All targeting, damage and cooldowns are server controlled.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local config = require(ReplicatedStorage.Riftbound.Shared.AshleySimmonsSpec)
local combat = require(ReplicatedStorage.Riftbound.Shared.CombatConfig)
local shield = require(script.Parent.PillShield)
local fx = ReplicatedStorage.Riftbound.Remotes.SpecFX
local Moves = {}
local states = {}
local rng = Random.new()
local effects = {"Drowsiness", "Confusion", "Overdose", "Euphoria", "Nausea"}

local function now()
	return Workspace:GetServerTimeNow()
end

local function live(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then return nil end
	return character, humanoid, root
end

local function state(player)
	if not states[player] then states[player] = {ready = {}, rush = 0} end
	return states[player]
end

local function ready(player, key, cooldown)
	local s = state(player)
	local t = now()
	if t < (s.ready[key] or 0) then return false end
	s.ready[key] = t + cooldown
	player:SetAttribute("Ashley" .. key .. "ReadyAt", s.ready[key])
	return true
end

local function pulse(position, radius, color, duration)
	local ball = Instance.new("Part")
	ball.Name = "AshleyImpact"
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Size = Vector3.new(0.8, 0.8, 0.8)
	ball.Transparency = 0.5
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanTouch = false
	ball.CanQuery = false
	ball.Position = position
	ball.Parent = Workspace
	TweenService:Create(ball, TweenInfo.new(duration), {
		Size = Vector3.new(radius * 2, radius * 2, radius * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ball, duration + 0.1)
end

local function launch(character, goal, travel, color, onImpact)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local start = root.Position + Vector3.new(0, 2.5, 0)
	local capsule = Instance.new("Part")
	capsule.Name = "AshleyCapsule"
	capsule.Size = Vector3.new(0.75, 1.25, 0.75)
	capsule.Shape = Enum.PartType.Ball
	capsule.Color = color
	capsule.Material = Enum.Material.Neon
	capsule.Anchored = true
	capsule.CanCollide = false
	capsule.CanTouch = false
	capsule.CanQuery = false
	capsule.Position = start
	capsule.Parent = Workspace
	Debris:AddItem(capsule, travel + 1)
	local elapsed = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.clamp(elapsed / travel, 0, 1)
		capsule.Position = start:Lerp(goal, alpha) + Vector3.new(0, math.sin(math.pi * alpha) * 4, 0)
		if alpha >= 1 then
			connection:Disconnect()
			capsule:Destroy()
			onImpact(goal)
		end
	end)
end

local function aimPoint(character, root, range)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true
	local start = root.Position + Vector3.new(0, 1, 0)
	local ray = Workspace:Raycast(start, root.CFrame.LookVector * range, params)
	local point = ray and ray.Position or (start + root.CFrame.LookVector * range)
	-- Euphoria from the passive temporarily throws off projectile aim.
	if (character:GetAttribute("Pill_Euphoria") or 0) > os.clock() then
		point += Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
	end
	return point
end

local function targets(center, radius, exclude)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {exclude}
	local found = {}
	local result = {}
	for _, part in Workspace:GetPartBoundsInRadius(center, radius, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model ~= exclude and not found[model] then
			found[model] = true
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 and (root.Position - center).Magnitude <= radius + 2 then
				table.insert(result, {model = model, humanoid = humanoid})
			end
		end
	end
	return result
end

local function temporarySlow(model, humanoid, key, duration, fraction)
	local expires = now() + duration
	local previous = humanoid.WalkSpeed
	model:SetAttribute(key, expires)
	if (model:GetAttribute("RaveRushEnds") or 0) <= now() then
		humanoid.WalkSpeed = math.max(5, previous * (1 - fraction))
	end
	task.delay(duration, function()
		if humanoid.Parent and model:GetAttribute(key) == expires then
			model:SetAttribute(key, nil)
			if (model:GetAttribute("RaveRushEnds") or 0) <= now() then
				humanoid.WalkSpeed = model:GetAttribute("RiftBlocking") and combat.Block.WalkSpeed or combat.BaseWalkSpeed
			end
		end
	end)
end

local function status(player, model, humanoid, effect, position, radius)
	local data = config.Ultimate.Effects[effect]
	if effect == "Drowsiness" then
		temporarySlow(model, humanoid, "FrenzyDrowsinessEnds", data.Duration, 0.35)
	elseif effect == "Confusion" then
		local expires = now() + data.Duration
		model:SetAttribute("FrenzyConfusionEnds", expires)
		task.delay(data.Duration, function()
			if model.Parent and model:GetAttribute("FrenzyConfusionEnds") == expires then
				model:SetAttribute("FrenzyConfusionEnds", 0)
			end
		end)
	elseif effect == "Overdose" then
		for i = 1, data.Duration do
			task.delay(i, function()
				if humanoid.Parent and humanoid.Health > 0 then
					shield.Damage(model, humanoid, data.DamagePerSecond, player)
				end
			end)
		end
	elseif effect == "Euphoria" then
		-- A short-lived field refreshes the weakening status while enemies remain inside.
		local zoneEnd = now() + data.Duration
		local zone = Instance.new("Part")
		zone.Name = "FrenzyEuphoriaZone"
		zone.Shape = Enum.PartType.Ball
		zone.Material = Enum.Material.ForceField
		zone.Color = Color3.fromRGB(155, 90, 250)
		zone.Size = Vector3.new(radius * 2, 1, radius * 2)
		zone.Transparency = 0.7
		zone.Anchored = true
		zone.CanCollide = false
		zone.CanTouch = false
		zone.CanQuery = false
		zone.Position = position
		zone.Parent = Workspace
		Debris:AddItem(zone, data.Duration + 0.1)
		task.spawn(function()
			while now() < zoneEnd and zone.Parent do
				for _, victim in targets(position, radius, player.Character) do
					victim.model:SetAttribute("FrenzyEuphoriaEnds", math.min(zoneEnd, now() + 0.6))
				end
				task.wait(0.2)
			end
			if zone.Parent then zone:Destroy() end
		end)
	elseif effect == "Nausea" then
		model:SetAttribute("FrenzyNausea", true)
	end
end

function Moves.Cast(player, key)
	if player:GetAttribute("EquippedSpec") ~= "AshleySimmons" then return false end
	if player.Character and player.Character:GetAttribute("RiftBlocking") == true then return false end
	local character, humanoid, root = live(player)
	if not character then return false end
	if key == "C" then
		local data = config.Abilities.C
		if not ready(player, key, data.Cooldown) then return false end
		local s = state(player)
		s.rush += 1
		local token = s.rush
		local expires = now() + data.Duration
		character:SetAttribute("Pill_ChillPill", nil)
		character:SetAttribute("FrenzyDrowsinessEnds", 0)
		character:SetAttribute("RaveRushEnds", expires)
		humanoid.WalkSpeed = combat.BaseWalkSpeed * data.MoveSpeedMultiplier
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "RaveRushTrail"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 85, 230), Color3.fromRGB(70, 240, 245))
		emitter.LightEmission = 0.8
		emitter.Rate = 35
		emitter.Lifetime = NumberRange.new(0.2, 0.5)
		emitter.Speed = NumberRange.new(0.5, 2)
		emitter.Size = NumberSequence.new(0.7)
		emitter.Parent = root
		Debris:AddItem(emitter, data.Duration + 1)
		task.delay(data.Duration, function()
			emitter.Enabled = false
			if character.Parent and s.rush == token then
				character:SetAttribute("RaveRushEnds", 0)
				if humanoid.Health > 0 then
					humanoid.WalkSpeed = character:GetAttribute("RiftBlocking") and combat.Block.WalkSpeed or combat.BaseWalkSpeed
				end
			end
		end)
		fx:FireAllClients("RaveRush", character)
		return true
	elseif key == "V" then
		local data = config.Abilities.V
		if not ready(player, key, data.Cooldown) then return false end
		local goal = aimPoint(character, root, 19)
		launch(character, goal, 0.48, Color3.fromRGB(210, 90, 245), function(position)
			if player.Character ~= character or player:GetAttribute("EquippedSpec") ~= "AshleySimmons" then return end
			pulse(position, 7, Color3.fromRGB(185, 70, 240), 0.35)
			fx:FireAllClients("TrippyExplosion", position)
			for _, victim in targets(position, 7, character) do
				shield.Damage(victim.model, victim.humanoid, data.Damage, player)
				victim.model:SetAttribute("TrippyVisionEnds", now() + data.BlindDuration)
			end
		end)
		return true
	elseif key == "G" then
		local data = config.Ultimate
		if not ready(player, key, data.Cooldown) then return false end
		local center = aimPoint(character, root, 22)
		local colors = {
			Color3.fromRGB(100, 210, 255),
			Color3.fromRGB(245, 110, 235),
			Color3.fromRGB(255, 160, 75),
			Color3.fromRGB(135, 240, 145),
			Color3.fromRGB(170, 125, 255),
		}
		for shot = 1, data.ProjectileCount do
			task.delay((shot - 1) * 0.2, function()
				if player.Character ~= character or player:GetAttribute("EquippedSpec") ~= "AshleySimmons" then return end
				local offset = Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
				local effect = effects[rng:NextInteger(1, #effects)]
				launch(character, center + offset, 0.4, colors[shot], function(position)
					if player.Character ~= character or player:GetAttribute("EquippedSpec") ~= "AshleySimmons" then return end
					pulse(position, 5.5, colors[shot], 0.32)
					fx:FireAllClients("FrenzyExplosion", position, effect)
					local hit = targets(position, 5.5, character)
					for _, victim in hit do
						shield.Damage(victim.model, victim.humanoid, data.DamagePerProjectile, player)
						if effect ~= "Euphoria" then
							status(player, victim.model, victim.humanoid, effect, position, 5.5)
						end
					end
					if effect == "Euphoria" then
						status(player, character, humanoid, effect, position, 5.5)
					end
				end)
			end)
		end
		fx:FireAllClients("FrenzyCast", character)
		return true
	end
	return false
end

-- Clear only the outgoing Ashley movement buff when switching Specs.
-- Enemy-inflicted debuffs are intentionally left alone.
function Moves.StopPlayerBuffs(player)
	local character = player.Character
	if not character then return end
	local s = state(player)
	local hadRush = (character:GetAttribute("RaveRushEnds") or 0) > now()
	s.rush += 1 -- Invalidate the active Rave Rush timeout.
	character:SetAttribute("RaveRushEnds", 0)
	local root = character:FindFirstChild("HumanoidRootPart")
	local emitter = root and root:FindFirstChild("RaveRushTrail")
	if emitter then emitter:Destroy() end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if hadRush and humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = character:GetAttribute("RiftBlocking") == true and combat.Block.WalkSpeed or combat.BaseWalkSpeed
	end
end

function Moves.ResetPlayer(player)
	states[player] = nil
	for _, key in {"C", "V", "G"} do
		player:SetAttribute("Ashley" .. key .. "ReadyAt", 0)
	end
end

function Moves.ClearCharacter(character)
	if not character then return end
	character:SetAttribute("RaveRushEnds", 0)
	character:SetAttribute("TrippyVisionEnds", 0)
	character:SetAttribute("FrenzyConfusionEnds", 0)
	character:SetAttribute("FrenzyEuphoriaEnds", 0)
	character:SetAttribute("FrenzyDrowsinessEnds", 0)
	character:SetAttribute("FrenzyNausea", nil)
end

Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
return Moves
