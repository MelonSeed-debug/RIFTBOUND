--!strict
-- RIFTBOUND Open World / Enemy AI 2.0.
-- Curated R15 PvE enemies with guarded attacks and obstacle-aware pursuit.
-- Started from init.server.luau; custom dungeon spawns remain supported.
-- No client-driven NPC damage, positions or cooldowns.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Navigation = require(script.Parent.NPCNavigation)

local combat = require(ReplicatedStorage.Riftbound.Shared.CombatConfig)
local world = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)
local cfg = combat.NPC
local combatFX = ReplicatedStorage.Riftbound.Remotes.CombatFX
local random = Random.new()
local NPCs = {}
local started = false
local activeHooks = nil

local TYPES = {}
for _, template in world.EnemySpawns do
	table.insert(TYPES, {
		Name = template.Name,
		Id = template.Id,
		Offset = template.Offset,
		Color = template.Color,
		GuardChance = template.GuardChance,
		Health = template.Health,
		AttackDamage = template.Damage,
		AttackCooldown = template.Cooldown,
		WalkSpeed = template.WalkSpeed,
		RecommendedLevel = template.RecommendedLevel,
		Archetype = template.Archetype or "Guardian",
	})
end

local function floorPosition(x, z, fallbackY, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore and {ignore} or {}
	local hit = Workspace:Raycast(Vector3.new(x, fallbackY + 100, z), Vector3.new(0, -300, 0), params)
	return hit and hit.Position.Y or fallbackY
end

local function buildFallbackR15()
	-- Only used if Roblox's automatic R15 character generation is unavailable.
	local model = Instance.new("Model")
	local pieces = {}
	local data = {
		{"HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0)},
		{"LowerTorso", Vector3.new(2, 1, 1), Vector3.new(0, -0.55, 0)},
		{"UpperTorso", Vector3.new(2, 1.25, 1), Vector3.new(0, 0.55, 0)},
		{"Head", Vector3.new(1.2, 1.15, 1.2), Vector3.new(0, 1.75, 0)},
		{"LeftUpperArm", Vector3.new(0.8, 1.05, 0.8), Vector3.new(-1.4, 0.50, 0)},
		{"LeftLowerArm", Vector3.new(0.75, 0.95, 0.75), Vector3.new(-1.4, -0.49, 0)},
		{"LeftHand", Vector3.new(0.7, 0.45, 0.7), Vector3.new(-1.4, -1.16, 0)},
		{"RightUpperArm", Vector3.new(0.8, 1.05, 0.8), Vector3.new(1.4, 0.50, 0)},
		{"RightLowerArm", Vector3.new(0.75, 0.95, 0.75), Vector3.new(1.4, -0.49, 0)},
		{"RightHand", Vector3.new(0.7, 0.45, 0.7), Vector3.new(1.4, -1.16, 0)},
		{"LeftUpperLeg", Vector3.new(0.85, 1.05, 0.85), Vector3.new(-0.5, -1.45, 0)},
		{"LeftLowerLeg", Vector3.new(0.8, 1, 0.8), Vector3.new(-0.5, -2.5, 0)},
		{"LeftFoot", Vector3.new(0.9, 0.4, 1.1), Vector3.new(-0.5, -3.2, -0.22)},
		{"RightUpperLeg", Vector3.new(0.85, 1.05, 0.85), Vector3.new(0.5, -1.45, 0)},
		{"RightLowerLeg", Vector3.new(0.8, 1, 0.8), Vector3.new(0.5, -2.5, 0)},
		{"RightFoot", Vector3.new(0.9, 0.4, 1.1), Vector3.new(0.5, -3.2, -0.22)},
	}
	for _, item in data do
		local part = Instance.new("Part")
		part.Name = item[1]
		part.Size = item[2]
		part.CFrame = CFrame.new(item[3])
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.CanTouch = false
		part.Massless = item[1] ~= "HumanoidRootPart"
		if item[1] == "HumanoidRootPart" then part.Transparency = 1 end
		part.Parent = model
		pieces[part.Name] = part
	end
	local joints = {
		{"Root", "HumanoidRootPart", "LowerTorso"},
		{"Waist", "LowerTorso", "UpperTorso"},
		{"Neck", "UpperTorso", "Head"},
		{"LeftShoulder", "UpperTorso", "LeftUpperArm"},
		{"LeftElbow", "LeftUpperArm", "LeftLowerArm"},
		{"LeftWrist", "LeftLowerArm", "LeftHand"},
		{"RightShoulder", "UpperTorso", "RightUpperArm"},
		{"RightElbow", "RightUpperArm", "RightLowerArm"},
		{"RightWrist", "RightLowerArm", "RightHand"},
		{"LeftHip", "LowerTorso", "LeftUpperLeg"},
		{"LeftKnee", "LeftUpperLeg", "LeftLowerLeg"},
		{"LeftAnkle", "LeftLowerLeg", "LeftFoot"},
		{"RightHip", "LowerTorso", "RightUpperLeg"},
		{"RightKnee", "RightUpperLeg", "RightLowerLeg"},
		{"RightAnkle", "RightLowerLeg", "RightFoot"},
	}
	for _, item in joints do
		local parent = pieces[item[2]]
		local child = pieces[item[3]]
		local joint = Instance.new("Motor6D")
		joint.Name = item[1]
		joint.Part0 = parent
		joint.Part1 = child
		joint.C0 = parent.CFrame:ToObjectSpace(child.CFrame)
		joint.Parent = parent
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 2
	humanoid.Parent = model
	model.PrimaryPart = pieces.HumanoidRootPart
	return model
end

local function makeRig()
	local description = Instance.new("HumanoidDescription")
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	description:Destroy()
	if ok and model and model:IsA("Model") then return model end
	warn("[RIFTBOUND NPC] R15 avatar generation unavailable; using basic fallback rig:", model)
	return buildFallbackR15()
end

local function healthBar(model, humanoid, color, displayName)
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if not head then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NPCHealthBar"
	billboard.Size = UDim2.fromOffset(180, 52)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	billboard.MaxDistance = 100
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = head

	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.54)
	name.BackgroundTransparency = 1
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextStrokeTransparency = 0.22
	name.Font = Enum.Font.GothamBold
	name.TextSize = 15
	name.Text = displayName
	name.Parent = billboard

	local back = Instance.new("Frame")
	back.Size = UDim2.new(0.9, 0, 0, 11)
	back.Position = UDim2.new(0.05, 0, 0.62, 0)
	back.BorderSizePixel = 0
	back.BackgroundColor3 = Color3.fromRGB(25, 18, 32)
	back.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "HealthFill"
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = color
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = back

	humanoid.HealthChanged:Connect(function(health)
		if fill.Parent then
			fill.Size = UDim2.fromScale(math.clamp(health / math.max(1, humanoid.MaxHealth), 0, 1), 1)
		end
	end)
end

-- The zone tracker updates every ~0.45s. Re-check Haven locally before
-- selecting a target AND before committing damage at the end of a windup.
local function inSafeZone(character, targetRoot)
	if character:GetAttribute("RiftSafeZone") == true then return true end
	if world.GetZoneAt then
		local generated = Workspace:FindFirstChild(world.WorldName)
		if generated then
			local offset = Vector3.new(
				targetRoot.Position.X - (generated:GetAttribute("SpawnX") or 0), 0,
				targetRoot.Position.Z - (generated:GetAttribute("SpawnZ") or 0))
			local _, safe = world.GetZoneAt(offset)
			return safe == true
		end
	end
	return false
end

local function nearestPlayer(root, home)
	local bestPlayer, bestChar, bestHumanoid, bestRoot, bestDistance
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and targetRoot and humanoid.Health > 0
			and not inSafeZone(character, targetRoot) then
			local distance = (targetRoot.Position - root.Position).Magnitude
			local homeDistance = (targetRoot.Position - home).Magnitude
			if distance <= cfg.DetectRange and homeDistance <= cfg.LeashRange
				and math.abs(targetRoot.Position.Y - root.Position.Y)
					<= (cfg.VerticalDetectRange or 20)
				and (not bestDistance or distance < bestDistance) then
				bestDistance = distance
				bestPlayer, bestChar, bestHumanoid, bestRoot = player, character, humanoid, targetRoot
			end
		end
	end
	return bestPlayer, bestChar, bestHumanoid, bestRoot, bestDistance
end

local function setGuard(model, humanoid, active)
	if model:GetAttribute("RiftBlocking") == active then return end
	model:SetAttribute("RiftBlocking", active)
	if active then
		humanoid.WalkSpeed = cfg.GuardWalkSpeed
	else
		local speed = model:GetAttribute("RiftNPCWalkSpeed") or cfg.WalkSpeed
		if (model:GetAttribute("Pill_ChillPill") or 0) > os.clock() then speed *= 0.75 end
		if (model:GetAttribute("FrenzyDrowsinessEnds") or 0) > Workspace:GetServerTimeNow() then speed *= 0.65 end
		humanoid.WalkSpeed = speed
	end
end

local function telegraph(model, windup)
	local glow = Instance.new("Highlight")
	glow.Name = "IncomingNPCAttack"
	glow.FillColor = Color3.fromRGB(255, 126, 77)
	glow.OutlineColor = Color3.fromRGB(255, 223, 143)
	glow.FillTransparency = 0.35
	glow.OutlineTransparency = 0.1
	glow.Parent = model
	task.delay(windup + 0.12, function()
		if glow.Parent then glow:Destroy() end
	end)
	combatFX:FireAllClients("NPCWindup", model)
end

local function attemptAttack(model, humanoid, root, player, targetCharacter, targetHumanoid, targetRoot, hooks)
	local windup = model:GetAttribute("RiftNPCAttackWindup") or cfg.AttackWindup
	local reach = model:GetAttribute("RiftNPCAttackRange") or cfg.AttackRange
	telegraph(model, windup)
	task.delay(windup, function()
		if not model.Parent or humanoid.Health <= 0 or (model:GetAttribute("RiftNPCStunnedUntil") or 0) > os.clock() then return end
		if player.Character ~= targetCharacter or not targetRoot.Parent or targetHumanoid.Health <= 0 then return end
		if inSafeZone(targetCharacter, targetRoot) then return end
		if (model:GetAttribute("RiftHitstunUntil") or 0) > Workspace:GetServerTimeNow() then return end
		local difference = targetRoot.Position - root.Position
		if difference.Magnitude > reach + 0.75 or difference.Magnitude < 0.1 then return end
		-- Walls and solid obstacles interrupt attacks; the server decides hit validity.
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {model}
		local obstacle = Workspace:Raycast(root.Position, difference, rayParams)
		if obstacle and not obstacle.Instance:IsDescendantOf(targetCharacter) then return end

		if model:GetAttribute("FrenzyNausea") == true then
			model:SetAttribute("FrenzyNausea", nil)
			combatFX:FireAllClients("NauseaMiss", model)
			return
		end

		local incomingDirection = (root.Position - targetRoot.Position).Unit
		local guarded = targetCharacter:GetAttribute("RiftBlocking") == true
			and targetRoot.CFrame.LookVector:Dot(incomingDirection) >= combat.Block.FrontDot
		if guarded then
			if hooks.IsParrying and hooks.IsParrying(player) then
				model:SetAttribute("RiftNPCStunnedUntil", os.clock() + combat.Block.ParryStun)
				if hooks.RewardParry then hooks.RewardParry(player) end
				combatFX:FireAllClients("Parry", targetCharacter)
			else
				combatFX:FireAllClients("BlockedHit", targetCharacter)
			end
			return
		end
		local amount = model:GetAttribute("RiftNPCAttackDamage") or cfg.AttackDamage
		if (model:GetAttribute("Pill_AdrenalineRush") or 0) > os.clock() then amount *= 1.2 end
		if (model:GetAttribute("Pill_AntiInflammatory") or 0) > os.clock() then amount *= 0.95 end
		if (model:GetAttribute("FrenzyEuphoriaEnds") or 0) > Workspace:GetServerTimeNow() then amount *= 0.9 end

		local damage = hooks.DealDamage(targetCharacter, targetHumanoid, amount)
		if damage > 0 then
			if hooks.ApplyHitstun then
				hooks.ApplyHitstun(targetCharacter, 0.23)
			end
			combatFX:FireAllClients("Hit", targetCharacter, 0, math.round(damage * 10) / 10)
		else
			combatFX:FireAllClients("BlockedHit", targetCharacter)
		end
	end)
end

local function runAI(model, humanoid, root, home, definition, hooks)
	task.spawn(function()
		local nextAttack = 0
		local nextDecision = 0
		local guardUntil = 0
		local nextSidestep = 0
		local strafeTarget = nil
		local strafeUntil = 0
		local archetype = definition.Archetype or "Guardian"
		local reach = model:GetAttribute("RiftNPCAttackRange") or cfg.AttackRange
		local lastMode = ""
		while model.Parent and humanoid.Health > 0 do
			local current = os.clock()
			local stunned = (model:GetAttribute("RiftNPCStunnedUntil") or 0) > current
				or (model:GetAttribute("RiftHitstunUntil") or 0) > Workspace:GetServerTimeNow()
			local confused = (model:GetAttribute("FrenzyConfusionEnds") or 0) > Workspace:GetServerTimeNow()
			local player, targetCharacter, targetHumanoid, targetRoot, distance = nearestPlayer(root, home)
			local fromHome = (root.Position - home).Magnitude
			local outsideLeash = fromHome >= cfg.LeashRange + 6

			if stunned or confused then
				if lastMode ~= "Stunned" then Navigation.Stop(model, humanoid, root) end
				lastMode = "Stunned"
				setGuard(model, humanoid, false)
				strafeTarget = nil
			elseif outsideLeash or not player or not distance then
				lastMode = "Return"
				strafeTarget = nil
				guardUntil = 0
				setGuard(model, humanoid, false)
				if fromHome > 3.5 then
					Navigation.GoTo(model, humanoid, root, home, {
						Mode = "Return",
						ArriveDistance = 3.5,
					})
				else
					Navigation.Stop(model, humanoid, root)
					lastMode = "Idle"
				end
			else
				if lastMode ~= "Chase" and lastMode ~= "Fight" then
					model:SetAttribute("RiftNPCEngaged", true)
				end
				-- Guardians favor timed blocking; faster Skirmishers try to
				-- reposition between telegraphed attacks.
				if distance > 12 then
					setGuard(model, humanoid, false)
					guardUntil = 0
				elseif current >= nextDecision and distance <= 9
					and (definition.GuardChance or 0) > 0 then
					nextDecision = current + cfg.DecisionInterval
					if random:NextNumber() < definition.GuardChance then
						guardUntil = current + cfg.GuardDuration
						setGuard(model, humanoid, true)
					end
				end
				if guardUntil > 0 and current >= guardUntil then
					setGuard(model, humanoid, false)
					guardUntil = 0
				end
				if distance > reach - 1 then
					lastMode = "Chase"
					strafeTarget = nil
					Navigation.GoTo(model, humanoid, root, targetRoot.Position, {
						Mode = "Pursue",
						TargetCharacter = targetCharacter,
						ArriveDistance = math.max(2.5, reach - 1.5),
					})
				else
					lastMode = "Fight"
					if archetype == "Skirmisher" and current >= nextSidestep
						and distance > 2.4 and distance < 10 then
						nextSidestep = current + random:NextNumber(1.5, 2.8)
						local side = random:NextNumber() > 0.5 and 1 or -1
						local goal = root.Position + root.CFrame.RightVector * (6 * side)
						if (goal - home).Magnitude < cfg.LeashRange - 11 then
							strafeTarget = goal
							strafeUntil = current + 0.75
						end
					end
					if strafeTarget and current < strafeUntil then
						Navigation.GoTo(model, humanoid, root, strafeTarget, {
							Mode = "Strafe", ArriveDistance = 1.8,
						})
					else
						strafeTarget = nil
						Navigation.Stop(model, humanoid, root)
					end
					local flat = Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z)
					if (flat - root.Position).Magnitude > 0.05 then
						root.CFrame = CFrame.lookAt(root.Position, flat)
					end
					if current >= nextAttack and model:GetAttribute("RiftBlocking") ~= true then
						nextAttack = current + (definition.AttackCooldown or cfg.AttackCooldown)
						attemptAttack(model, humanoid, root, player,
							targetCharacter, targetHumanoid, targetRoot, hooks)
					end
				end
			end
			if lastMode == "Return" or lastMode == "Idle" then
				if model:GetAttribute("RiftNPCEngaged") then
					model:SetAttribute("RiftNPCEngaged", false)
	model:SetAttribute("RiftNPCState", "Spawning")
				end
			end
			-- Replicate state changes only when they transition. This makes
			-- Studio debugging possible without per-frame RemoteEvents.
			if model:GetAttribute("RiftNPCState") ~= lastMode then
				model:SetAttribute("RiftNPCState", lastMode)
			end
			task.wait(cfg.ThinkInterval)
		end
		Navigation.Clear(model)
	end)
end

local function spawnOne(folder, center, definition, hooks)
	local model = makeRig()
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		warn("[RIFTBOUND NPC] Failed to create rig for", definition.Name)
		model:Destroy()
		return
	end

	local pos = center + definition.Offset
	local y = definition.Id == "Dungeon" and center.Y
		or floorPosition(pos.X, pos.Z, center.Y, folder)
	local spawnPosition = Vector3.new(pos.X, y + math.max(humanoid.HipHeight + root.Size.Y / 2, 3), pos.Z)
	model.Name = definition.Name
	model:SetAttribute("RiftNPC", true)
	model:SetAttribute("RiftBlocking", false)
	model:SetAttribute("RiftNPCEngaged", false)
	model:SetAttribute("RiftNPCStunnedUntil", 0)
	humanoid.MaxHealth = definition.Health
	humanoid.Health = definition.Health
	humanoid.WalkSpeed = definition.WalkSpeed or cfg.WalkSpeed
	model:SetAttribute("RiftNPCAttackDamage", definition.AttackDamage or cfg.AttackDamage)
	model:SetAttribute("RiftNPCArchetype", definition.Archetype or "Guardian")
	model:SetAttribute("RiftNPCAttackRange", definition.AttackRange or cfg.AttackRange)
	model:SetAttribute("RiftNPCAttackWindup",
		definition.Archetype == "Skirmisher" and 0.43 or
		(definition.Archetype == "Guardian" and 0.7 or cfg.AttackWindup))
	model:SetAttribute("RiftNPCWalkSpeed", definition.WalkSpeed or cfg.WalkSpeed)
	model:SetAttribute("RiftNPCZone", definition.Id)
	model:SetAttribute("RiftNPCRecommendedLevel", definition.RecommendedLevel)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.AutoRotate = true
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") and child ~= root then
			child.Color = definition.Color
		end
	end
	model.Parent = folder
	model:PivotTo(CFrame.new(spawnPosition))
	pcall(function() root:SetNetworkOwner(nil) end)
	healthBar(model, humanoid, definition.Color,
		definition.Name .. " | LV " .. tostring(definition.RecommendedLevel) .. "+")

	local respawnQueued = false
	humanoid.Died:Connect(function()
		if respawnQueued then return end
		respawnQueued = true
		Navigation.Clear(model)
		model:SetAttribute("RiftBlocking", false)
		-- NPC defeats reward only the last server-validated player who damaged
		-- this particular enemy, within 12 seconds of its death.
		local userId = model:GetAttribute("RiftLastAttackerId")
		local hitTime = model:GetAttribute("RiftLastHitAt")
		if typeof(userId) == "number" and typeof(hitTime) == "number"
			and Workspace:GetServerTimeNow() - hitTime <= 12 then
			local killer = Players:GetPlayerByUserId(userId)
			if killer and hooks.AwardDefeat then
				local paid, err = pcall(hooks.AwardDefeat, killer, definition.Name)
				if not paid then warn("[RIFTBOUND NPC] Failed to award defeat:", err) end
			end
			if killer and definition.OnDefeat then
				local ok,err = pcall(definition.OnDefeat,killer,model)
				if not ok then warn("[RIFTBOUND NPC] Boss defeated callback failed:",err) end
			end
		end
		task.delay(3, function()
			if model.Parent then model:Destroy() end
		end)
		if not definition.NoRespawn then
			task.delay(cfg.RespawnDelay, function()
				if not folder.Parent then return end
				local ok, err = pcall(spawnOne, folder, center, definition, hooks)
				if not ok then warn("[RIFTBOUND NPC] Respawn failed:", err) end
			end)
		end
	end)
	runAI(model, humanoid, root, spawnPosition, definition, hooks)
	return model
end

function NPCs.Start(hooks)
	if started or not cfg then return end
	if cfg.StudioOnly and not RunService:IsStudio() then return end
	started = true
	activeHooks = hooks

	-- Keep server-controlled challenge/boss spawning functional while removing
	-- the repetitive ambient bandits and enemies from the flat field.
	if cfg.Enabled == false or world.EnableWorldEnemies == false then
		local previous = Workspace:FindFirstChild("RIFTBOUND Enemies")
		if previous then previous:Destroy() end
		print("[RIFTBOUND NPC] Roaming enemies disabled; scripted boss encounters available.")
		return
	end

	local folder = Workspace:FindFirstChild("RIFTBOUND Enemies")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RIFTBOUND Enemies"
		folder.Parent = Workspace
	end
	-- Baked v3 test NPCs may still live in the generated enemy folder.
	-- Remove only tagged RIFTBOUND NPC rigs to avoid duplication while
	-- preserving any user-built models that are not our generated enemies.
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("RiftNPC") == true then
			child:Destroy()
		end
	end
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local generated = Workspace:FindFirstChild(world.WorldName)
	local center = generated and Vector3.new(
		generated:GetAttribute("SpawnX") or 0,
		generated:GetAttribute("GroundY") or 0,
		generated:GetAttribute("SpawnZ") or 0)
		or (spawn and spawn.Position or Vector3.zero)
	for _, definition in TYPES do
		task.spawn(function()
			local ok, err = pcall(spawnOne, folder, center, definition, hooks)
			if not ok then warn("[RIFTBOUND NPC] Spawn failed for", definition.Name, err) end
		end)
	end
	print("[RIFTBOUND NPC] Starting " .. tostring(#TYPES) ..
		" curated enemies across the four open-world biomes.")
end

-- DungeonService can spawn a one-shot encounter with the existing rig and
-- combat AI. It never permits a client to supply spawn positions or damage.
function NPCs.SpawnCustom(folder, position, definition)
	if not activeHooks or not folder or not folder.Parent then return nil end
	local d = table.clone(definition)
	d.Offset = Vector3.zero
	d.Id = d.Id or "Dungeon"
	d.RecommendedLevel = d.RecommendedLevel or 25
	d.Color = d.Color or Color3.fromRGB(186, 104, 239)
	d.GuardChance = d.GuardChance or 0.3
	d.Health = d.Health or 500
	d.NoRespawn = true
	return spawnOne(folder, position, d, activeHooks)
end

return NPCs
