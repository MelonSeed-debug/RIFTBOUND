--!strict
-- RIFTBOUND prototype enemies: R15 Street Brawler + Street Guard.
-- Spawned for Studio tests; standalone module started safely from init.server.luau.
-- No client-driven NPC damage, positions or cooldowns.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local combat = require(ReplicatedStorage.Riftbound.Shared.CombatConfig)
local cfg = combat.NPC
local combatFX = ReplicatedStorage.Riftbound.Remotes.CombatFX
local random = Random.new()
local NPCs = {}
local started = false

local TYPES = {
	{ Name = "Street Brawler", Offset = Vector3.new(-12, 0, -24), Color = Color3.fromRGB(236, 112, 87), GuardChance = 0.13, Health = cfg.Health },
	{ Name = "Street Guard", Offset = Vector3.new(12, 0, -24), Color = Color3.fromRGB(89, 159, 238), GuardChance = 0.58, Health = cfg.Health + 40 },
}

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

local function nearestPlayer(root, home)
	local bestPlayer, bestChar, bestHumanoid, bestRoot, bestDistance
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and targetRoot and humanoid.Health > 0 then
			local distance = (targetRoot.Position - root.Position).Magnitude
			local homeDistance = (targetRoot.Position - home).Magnitude
			if distance <= cfg.DetectRange and homeDistance <= cfg.LeashRange
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
		local speed = cfg.WalkSpeed
		if (model:GetAttribute("Pill_ChillPill") or 0) > os.clock() then speed *= 0.75 end
		if (model:GetAttribute("FrenzyDrowsinessEnds") or 0) > Workspace:GetServerTimeNow() then speed *= 0.65 end
		humanoid.WalkSpeed = speed
	end
end

local function telegraph(model)
	local glow = Instance.new("Highlight")
	glow.Name = "IncomingNPCAttack"
	glow.FillColor = Color3.fromRGB(255, 126, 77)
	glow.OutlineColor = Color3.fromRGB(255, 223, 143)
	glow.FillTransparency = 0.35
	glow.OutlineTransparency = 0.1
	glow.Parent = model
	task.delay(cfg.AttackWindup + 0.12, function()
		if glow.Parent then glow:Destroy() end
	end)
	combatFX:FireAllClients("NPCWindup", model)
end

local function attemptAttack(model, humanoid, root, player, targetCharacter, targetHumanoid, targetRoot, hooks)
	telegraph(model)
	task.delay(cfg.AttackWindup, function()
		if not model.Parent or humanoid.Health <= 0 or (model:GetAttribute("RiftNPCStunnedUntil") or 0) > os.clock() then return end
		if player.Character ~= targetCharacter or not targetRoot.Parent or targetHumanoid.Health <= 0 then return end
		local difference = targetRoot.Position - root.Position
		if difference.Magnitude > cfg.AttackRange + 0.75 or difference.Magnitude < 0.1 then return end

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
				combatFX:FireAllClients("Parry", targetCharacter)
			else
				combatFX:FireAllClients("BlockedHit", targetCharacter)
			end
			return
		end
		local amount = cfg.AttackDamage
		if (model:GetAttribute("Pill_AdrenalineRush") or 0) > os.clock() then amount *= 1.2 end
		if (model:GetAttribute("Pill_AntiInflammatory") or 0) > os.clock() then amount *= 0.95 end
		if (model:GetAttribute("FrenzyEuphoriaEnds") or 0) > Workspace:GetServerTimeNow() then amount *= 0.9 end

		local damage = hooks.DealDamage(targetCharacter, targetHumanoid, amount)
		if damage > 0 then
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
		while model.Parent and humanoid.Health > 0 do
			local current = os.clock()
			local stunned = (model:GetAttribute("RiftNPCStunnedUntil") or 0) > current
			local confused = (model:GetAttribute("FrenzyConfusionEnds") or 0) > Workspace:GetServerTimeNow()
			local player, targetCharacter, targetHumanoid, targetRoot, distance = nearestPlayer(root, home)
			if stunned or confused then
				setGuard(model, humanoid, false)
				humanoid:MoveTo(root.Position)
			elseif player and distance then
				if model:GetAttribute("RiftBlocking") ~= true then guardUntil = 0 end
				if current >= nextDecision and distance <= 9 and definition.GuardChance > 0 then
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
				if distance > cfg.AttackRange - 1 then
					humanoid:MoveTo(targetRoot.Position)
				else
					humanoid:MoveTo(root.Position)
					local flat = Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z)
					if (flat - root.Position).Magnitude > 0.05 then
						root.CFrame = CFrame.lookAt(root.Position, flat)
					end
					if current >= nextAttack and model:GetAttribute("RiftBlocking") ~= true then
						nextAttack = current + cfg.AttackCooldown
						attemptAttack(model, humanoid, root, player, targetCharacter, targetHumanoid, targetRoot, hooks)
					end
				end
			else
				setGuard(model, humanoid, false)
				guardUntil = 0
				if (root.Position - home).Magnitude > 3 then
					humanoid:MoveTo(home)
				else
					humanoid:MoveTo(root.Position)
				end
			end
			task.wait(cfg.ThinkInterval)
		end
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
	local y = floorPosition(pos.X, pos.Z, center.Y, folder)
	local spawnPosition = Vector3.new(pos.X, y + math.max(humanoid.HipHeight + root.Size.Y / 2, 3), pos.Z)
	model.Name = definition.Name
	model:SetAttribute("RiftNPC", true)
	model:SetAttribute("RiftBlocking", false)
	model:SetAttribute("RiftNPCStunnedUntil", 0)
	humanoid.MaxHealth = definition.Health
	humanoid.Health = definition.Health
	humanoid.WalkSpeed = cfg.WalkSpeed
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
	healthBar(model, humanoid, definition.Color, definition.Name)

	local respawnQueued = false
	humanoid.Died:Connect(function()
		if respawnQueued then return end
		respawnQueued = true
		model:SetAttribute("RiftBlocking", false)
		task.delay(3, function()
			if model.Parent then model:Destroy() end
		end)
		task.delay(cfg.RespawnDelay, function()
			if not folder.Parent then return end
			local ok, err = pcall(spawnOne, folder, center, definition, hooks)
			if not ok then warn("[RIFTBOUND NPC] Respawn failed:", err) end
		end)
	end)
	runAI(model, humanoid, root, spawnPosition, definition, hooks)
end

function NPCs.Start(hooks)
	if started or not cfg or cfg.Enabled == false then return end
	if cfg.StudioOnly and not RunService:IsStudio() then return end
	started = true

	local folder = Workspace:FindFirstChild("RIFTBOUND Enemies")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RIFTBOUND Enemies"
		folder.Parent = Workspace
	end
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local center = spawn and spawn.Position or Vector3.new(0, 0, 0)
	for _, definition in TYPES do
		task.spawn(function()
			local ok, err = pcall(spawnOne, folder, center, definition, hooks)
			if not ok then warn("[RIFTBOUND NPC] Spawn failed for", definition.Name, err) end
		end)
	end
	print("[RIFTBOUND NPC] Starting two Studio enemies near spawn.")
end

return NPCs
