--!strict
-- RIFTBOUND Spec #3: Abyssal Covenant Great Sword.
-- Server owns damage, hitboxes, cooldowns, damage reduction and sword equipment.
-- Real .rbxm sword is used when imported; a simple visible model is the fallback.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local config = require(ReplicatedStorage.Riftbound.Shared.GreatSwordSpec)
local Shield = require(script.Parent.PillShield)
local fx = ReplicatedStorage.Riftbound.Remotes.SpecFX

local Sword = {}
local states = setmetatable({}, {__mode = "k"})
local started = false
local activeCharacters = setmetatable({}, {__mode = "k"})
local GOLD = Color3.fromRGB(249, 183, 87)

local function now()
	return Workspace:GetServerTimeNow()
end

local function live(player)
	if player:GetAttribute("EquippedSpec") ~= "GreatSword" then return nil end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 or char:GetAttribute("RiftBlocking") then
		return nil
	end
	return char, hum, root
end

local function validCast(player, char)
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return player.Character == char
		and player:GetAttribute("EquippedSpec") == "GreatSword"
		and char.Parent ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local function ready(player, key)
	local s = states[player]
	if not s then s = {ready = {}} states[player] = s end
	local current = now()
	if (s.ready[key] or 0) > current then return false end
	local deadline = current + config.Abilities[key].Cooldown
	s.ready[key] = deadline
	player:SetAttribute("Sword" .. key .. "ReadyAt", deadline)
	return true
end

local function hitTargets(player, character, position, size, damage, knockback, vertical)
	if not validCast(player, character) then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	local seen = {}
	for _, part in Workspace:GetPartBoundsInBox(position, size, params) do
		local target = part:FindFirstAncestorOfClass("Model")
		if target and not seen[target] then
			seen[target] = true
			local hum = target:FindFirstChildOfClass("Humanoid")
			local targetRoot = target:FindFirstChild("HumanoidRootPart")
			if hum and targetRoot and hum.Health > 0 and
				target:GetAttribute("RiftSafeZone") ~= true and
				(targetRoot.Position - root.Position).Magnitude <= 25 then
				local dealt = Shield.Damage(target, hum, damage, player)
				if dealt > 0 and not targetRoot.Anchored and knockback and knockback > 0 then
					targetRoot.AssemblyLinearVelocity =
						root.CFrame.LookVector * knockback + Vector3.new(0, vertical or 0, 0)
				end
			end
		end
	end
end

local function burst(position, radius, color)
	local ring = Instance.new("Part")
	ring.Name = "Covenant Impact"
	ring.Shape = Enum.PartType.Ball
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.65
	ring.Size = Vector3.one
	ring.Position = position
	ring.Parent = Workspace
	TweenService:Create(ring, TweenInfo.new(0.32), {
		Size = Vector3.new(radius * 2, radius * 2, radius * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.42)
end

local function fallbackModel()
	local model = Instance.new("Model")
	model.Name = "Abyssal Covenant"
	local handle = Instance.new("Part")
	handle.Name = "Main"
	handle.Size = Vector3.new(0.36, 1.7, 0.36)
	handle.Color = Color3.fromRGB(24, 23, 35)
	handle.Material = Enum.Material.Metal
	handle.Parent = model
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(1.1, 5.1, 0.32)
	blade.Color = Color3.fromRGB(125, 82, 179)
	blade.Material = Enum.Material.Metal
	blade.CFrame = handle.CFrame * CFrame.new(0, 3.25, 0)
	blade.Parent = model
	local guard = Instance.new("Part")
	guard.Name = "Crossguard"
	guard.Size = Vector3.new(2.9, 0.4, 0.54)
	guard.Color = GOLD
	guard.Material = Enum.Material.Metal
	guard.CFrame = handle.CFrame * CFrame.new(0, 0.86, 0)
	guard.Parent = model
	model.PrimaryPart = handle
	return model
end

local function templateSword()
	local assets = ReplicatedStorage:FindFirstChild("RIFTBOUND Weapon Assets")
	local imported = assets and assets:FindFirstChild("GreatSword")
	if imported and imported:IsA("Model") then return imported end
	-- If the original pack is in Studio already, use its actual mesh directly.
	for _, location in {ReplicatedStorage, Workspace} do
		local family = location:FindFirstChild("Great Sword Animations", true)
		local original = family and family:FindFirstChild("Abyssal Covenant")
		if original and original:IsA("Model") then return original end
	end
	return nil
end

local function clearSword(character)
	if not character then return end
	local old = character:FindFirstChild("RIFTBOUND Equipped Sword")
	if old then old:Destroy() end
	character:SetAttribute("RiftSwordEquipped", false)
end

local function attach(character)
	if not character or not character.Parent then return end
	if character:GetAttribute("RiftSwordEquipped") then return end
	local hand = character:FindFirstChild("RightHand")
	if not hand or not hand:IsA("BasePart") then
		warn("[RIFTBOUND Sword] R15 RightHand missing. Check Game Settings > Avatar.")
		return
	end
	clearSword(character)
	local source = templateSword()
	local model = source and source:Clone() or fallbackModel()
	model.Name = "RIFTBOUND Equipped Sword"
	local grip = model:FindFirstChild("Main",true)
	if not grip or not grip:IsA("BasePart") then
		warn("[RIFTBOUND Sword] Imported GreatSword has no Main grip. Using fallback.")
		model:Destroy()
		model = fallbackModel()
		model.Name = "RIFTBOUND Equipped Sword"
		grip = model:FindFirstChild("Main")
	end
	-- Remove the source dummy rig's Motor6D: it can still refer to the
	-- original mannequin's limbs, which would break real player equipment.
	for _, obj in model:GetDescendants() do
		if obj:IsA("Motor6D") or obj:IsA("Script") or obj:IsA("LocalScript") then
			obj:Destroy()
		elseif obj:IsA("BasePart") then
			obj.Anchored = false
			obj.Massless = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
		end
	end
	model.Parent = character
	-- Retain source asset offsets (blade, particle attachments and guard).
	-- Grip adjustment can be tuned in this one CFrame after Studio playtest.
	local targetGrip = hand.CFrame
		* CFrame.new(0, -0.47, -0.25)
		* CFrame.Angles(math.rad(-90), 0, math.rad(90))
	local originalPivot = model:GetPivot()
	model:PivotTo(targetGrip * grip.CFrame:ToObjectSpace(originalPivot))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= grip then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = grip
			weld.Part1 = part
			weld.Parent = grip
		end
	end
	local joint = Instance.new("WeldConstraint")
	joint.Name = "RiftSwordGrip"
	joint.Part0 = hand
	joint.Part1 = grip
	joint.Parent = hand
	character:SetAttribute("RiftSwordEquipped", true)
	if not source then
		warn("[RIFTBOUND Sword] Using visible fallback sword; import the original pack " ..
			"or run INSTALL_GREAT_SWORD.lua in Studio for Abyssal Covenant mesh.")
	end
end

function Sword.Refresh(player)
	local character = player.Character
	if not character then return end
	if player:GetAttribute("EquippedSpec") == config.Id then
		attach(character)
	else
		clearSword(character)
	end
end

function Sword.Cast(player, key)
	if not config.Abilities[key] then return false end
	local character, humanoid, root = live(player)
	if not character then return false end
	if not ready(player, key) then return false end
	local move = config.Abilities[key]
	fx:FireAllClients("SwordAbility", character, key)

	if key == "Z" then
		local endTime = now() + move.Duration
		character:SetAttribute("RiftDefenseBuffEnds", endTime)
		character:SetAttribute("RiftDefenseBuffMultiplier", move.DamageMultiplier)
		task.delay(move.Duration, function()
			if character.Parent and character:GetAttribute("RiftDefenseBuffEnds") == endTime then
				character:SetAttribute("RiftDefenseBuffEnds", 0)
				character:SetAttribute("RiftDefenseBuffMultiplier", 1)
				fx:FireAllClients("SwordGuardEnd", character)
			end
		end)
		return true
	end

	local rootAtCast = root
	local facingAtCast = root.CFrame.LookVector
	if key == "X" then
		task.delay(move.Windup, function()
			if not validCast(player, character) then return end
			local currentRoot = character:FindFirstChild("HumanoidRootPart")
			if currentRoot ~= rootAtCast then return end
			local direction = Vector3.new(facingAtCast.X,0,facingAtCast.Z)
			if direction.Magnitude < 0.01 then return end
			direction = direction.Unit
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {character}
			local ray = Workspace:Raycast(currentRoot.Position,
				direction * move.Travel, rayParams)
			local distance = ray and math.max(0, ray.Distance - 3) or move.Travel
			if distance >= 1 then
				character:PivotTo(character:GetPivot() + direction * distance)
			end
			burst(currentRoot.Position + direction * 4, 5, GOLD)
			hitTargets(player, character, currentRoot.CFrame * CFrame.new(0,0,-move.Range/2),
				Vector3.new(move.Width, 7, move.Range), move.Damage, 18, 7)
		end)
		return true
	elseif key == "C" then
		task.delay(move.Windup, function()
			if not validCast(player, character) then return end
			local currentRoot = character:FindFirstChild("HumanoidRootPart")
			if not currentRoot then return end
			local origin = currentRoot.CFrame * CFrame.new(0,0,-move.Range/2)
			burst(currentRoot.Position + currentRoot.CFrame.LookVector*5, 6, GOLD)
			hitTargets(player, character, origin,
				Vector3.new(move.Width, 10, move.Range), move.Damage, 11, move.Launch)
		end)
		return true
	elseif key == "V" then
		task.delay(move.Windup, function()
			if not validCast(player, character) then return end
			local currentRoot = character:FindFirstChild("HumanoidRootPart")
			if not currentRoot then return end
			local origin = currentRoot.Position
			burst(origin, move.Radius, Color3.fromRGB(156, 102, 231))
			hitTargets(player, character, CFrame.new(origin),
				Vector3.new(move.Radius*2, 8, move.Radius*2),
				move.Damage, move.Knockback, 15)
		end)
		return true
	elseif key == "G" then
		task.delay(move.Windup, function()
			if not validCast(player, character) then return end
			local currentRoot = character:FindFirstChild("HumanoidRootPart")
			if not currentRoot then return end
			local center = currentRoot.CFrame * CFrame.new(0,0,-move.Range/2)
			burst(center.Position, 10, Color3.fromRGB(179, 87, 255))
			hitTargets(player, character, center,
				Vector3.new(move.Width, 10, move.Range), move.Damage, move.Knockback, 19)
		end)
		return true
	end
	return false
end

function Sword.StopPlayerBuffs(player)
	local character = player.Character
	if character then
		character:SetAttribute("RiftDefenseBuffEnds", 0)
		character:SetAttribute("RiftDefenseBuffMultiplier", 1)
		-- Switching Specs also stops a lingering sword guard stance.
		fx:FireAllClients("SwordGuardEnd", character)
	end
end

function Sword.ResetPlayer(player)
	states[player] = nil
	for key in config.Abilities do
		player:SetAttribute("Sword" .. key .. "ReadyAt", 0)
	end
end

function Sword.ClearCharacter(character)
	if not character then return end
	clearSword(character)
	character:SetAttribute("RiftDefenseBuffEnds", 0)
	character:SetAttribute("RiftDefenseBuffMultiplier", 1)
end

function Sword.Start()
	if started then return end
	started = true
	local function watch(player)
		local previous = activeCharacters[player]
		if previous then return end
		activeCharacters[player] = true
		player:GetAttributeChangedSignal("EquippedSpec"):Connect(function()
			Sword.Refresh(player)
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("RightHand", 5)
			if player.Character == character then Sword.Refresh(player) end
		end)
		if player.Character then task.defer(Sword.Refresh,player) end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		activeCharacters[player] = nil
	end)
	print("[RIFTBOUND Sword] Great Sword equipment and ability system ready.")
end

return Sword
