--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local rift = ReplicatedStorage:WaitForChild("Riftbound")
local config = require(rift.Shared.CombatConfig)

-- Generate the Studio world synchronously BEFORE quests and NPCs spawn.
-- The map is optional and a failure never interrupts combat.
local worldModule = script:FindFirstChild("WorldBuilder") or script:WaitForChild("WorldBuilder", 3)
if worldModule and worldModule:IsA("ModuleScript") then
	local loaded, builder = pcall(require, worldModule)
	if loaded and type(builder) == "table" and type(builder.Start) == "function" then
		local built, err = pcall(builder.Start)
		if not built then warn("[RIFTBOUND] World generation failed:", err) end
	else
		warn("[RIFTBOUND] World builder unavailable; combat remains playable:", builder)
	end
else
	warn("[RIFTBOUND] No WorldBuilder module. Existing environment retained.")
end
-- Optional progression: failure cannot disable the working combat or NPC system.
local Progression = {AwardNPCDefeat = function() return false end}
local progressionModule = script:FindFirstChild("Progression") or script:WaitForChild("Progression", 3)
if progressionModule and progressionModule:IsA("ModuleScript") then
	local loaded, result = pcall(require, progressionModule)
	if loaded and type(result) == "table" then
		Progression = result
		local started, err = pcall(Progression.Start)
		if not started then warn("[RIFTBOUND] Progression did not start:", err) end
	else
		warn("[RIFTBOUND] Progression failed to load:", result)
	end
else
	warn("[RIFTBOUND] Progression module missing; base combat remains active.")
end
-- Combat remains playable even when optional Spec files fail to sync or load.
local PillPassive = {Reset = function() end, OnHit = function() end}
local passiveModule = script:FindFirstChild("PillPassive") or script:WaitForChild("PillPassive", 3)
if passiveModule and passiveModule:IsA("ModuleScript") then
	local loaded, result = pcall(require, passiveModule)
	if loaded and type(result) == "table" then
		PillPassive = result
	else
		warn("[RIFTBOUND] Ashley passive disabled; base combat still active:", result)
	end
else
	warn("[RIFTBOUND] Missing PillPassive module; base combat still active.")
end
local Shield = {Activate = function() return false end, Damage = function(_, hum, n) hum:TakeDamage(n) end, Clear = function() end, ResetPlayer = function() end}
local shieldModule = script:FindFirstChild("PillShield") or script:WaitForChild("PillShield", 3)
if shieldModule then
	local ok, loaded = pcall(require, shieldModule)
	if ok and type(loaded) == "table" then Shield = loaded
	else warn("[RIFTBOUND] Pill Shield unavailable:", loaded) end
end
-- Optional Spec abilities must never block the core combat prototype.
local Buzz = {Activate = function() return false end, Clear = function() end, ResetPlayer = function() end}
local buzzModule = script:FindFirstChild("BuzzBoost") or script:WaitForChild("BuzzBoost", 3)
if buzzModule then
	local ok, loaded = pcall(require, buzzModule)
	if ok and type(loaded) == "table" then Buzz = loaded
	else warn("[RIFTBOUND] Buzz Boost unavailable:", loaded) end
end
-- The new skills are optional so a failed skill module never disables core combat.
local AshleyMoves = {Cast = function() return false end, ResetPlayer = function() end, ClearCharacter = function() end}
local ashleyModule = script:FindFirstChild("AshleyMoves") or script:WaitForChild("AshleyMoves", 3)
if ashleyModule then
	local ok, loaded = pcall(require, ashleyModule)
	if ok and type(loaded) == "table" then AshleyMoves = loaded
	else warn("[RIFTBOUND] Ashley moves unavailable:", loaded) end
end
-- Void Disciple skills are independent and only run for unlocked players.
local Void = {Cast = function() return false end, OnHit = function() end,
	StopPlayerBuffs = function() end, ClearCharacter = function() end, ResetPlayer = function() end}
local voidModule = script:FindFirstChild("VoidDiscipleMoves") or script:WaitForChild("VoidDiscipleMoves", 3)
if voidModule then
	local ok, loaded = pcall(require, voidModule)
	if ok and type(loaded) == "table" then Void = loaded
	else warn("[RIFTBOUND] Void Disciple unavailable:", loaded) end
end
-- Optional registry-driven selection: failure must not disable combat or the dummy.
local Selection = {Initialize = function(player) player:SetAttribute("EquippedSpec", "None") end, Request = function() return false end, Remove = function() end}
local selectionModule = script:FindFirstChild("SpecSelection") or script:WaitForChild("SpecSelection", 3)
if selectionModule and selectionModule:IsA("ModuleScript") then
	local ok, loaded = pcall(require, selectionModule)
	if ok and type(loaded) == "table" then
		Selection = loaded
	else
		warn("[RIFTBOUND] Spec selection unavailable:", loaded)
	end
else
	warn("[RIFTBOUND] Missing SpecSelection; base combat is still available.")
end
-- Quests are isolated from the combat startup path. Missing quest files
-- cannot disable existing Specs, NPCs or the training dummy.
task.defer(function()
	local questModule = script:FindFirstChild("QuestService") or script:WaitForChild("QuestService", 4)
	if not questModule or not questModule:IsA("ModuleScript") then
		warn("[RIFTBOUND] QuestService not found; combat remains available.")
		return
	end
	local ok, service = pcall(require, questModule)
	if not ok or type(service) ~= "table" or type(service.Start) ~= "function" then
		warn("[RIFTBOUND] Quest service failed to load:", service)
		return
	end
	local started, err = pcall(service.Start)
	if not started then warn("[RIFTBOUND] Quest service failed to start:", err) end
end)
local specRequest = rift.Remotes:WaitForChild("SpecRequest", 5)
if specRequest then
	specRequest.OnServerEvent:Connect(function(player, action, requestedId)
		if typeof(action) ~= "string" then return end
		if action == "EquipSpec" or action == "UnequipSpec" then
			local changed = Selection.Request(player, action, requestedId)
			if changed then
				if Progression.RecordEquip then
					Progression.RecordEquip(player, player:GetAttribute("EquippedSpec"))
				end
				local character = player.Character
				if character then
					Shield.Clear(character)
					Buzz.Clear(character)
					if AshleyMoves.StopPlayerBuffs then AshleyMoves.StopPlayerBuffs(player) end
					Void.StopPlayerBuffs(player)
				end
			end
			return
		end
		if action == "PillShield" then Shield.Activate(player)
		elseif action == "BuzzBoost" then Buzz.Activate(player)
		elseif action == "RaveRush" then AshleyMoves.Cast(player, "C")
		elseif action == "TrippyToss" then AshleyMoves.Cast(player, "V")
		elseif action == "Frenzy" then AshleyMoves.Cast(player, "G")
		elseif action == "VoidGuard" then Void.Cast(player, "Z")
		elseif action == "VoidStep" then Void.Cast(player, "X")
		elseif action == "VoidGrasp" then Void.Cast(player, "C")
		elseif action == "VoidCleave" then Void.Cast(player, "V")
		elseif action == "VoidNova" then Void.Cast(player, "G") end
	end)
end
local request = rift.Remotes.CombatRequest
local fx = rift.Remotes.CombatFX

local states = {}
local function getState(player)
	if not states[player] then
		states[player] = {combo=0,lastHit=0,nextM1=0,nextDash=0,blocking=false,attacking=false,nextHeavy=0,stunnedUntil=0,parryUntil=0,nextParry=0}
	end
	return states[player]
end

local function alive(player)
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then return nil end
	return character, humanoid, root
end

local function block(player, active)
	local s = getState(player)
	local character, humanoid = alive(player)
	if not character or (active and (s.attacking or os.clock() < s.stunnedUntil)) then return end
	if active and not s.blocking and os.clock() >= s.nextParry then
		s.parryUntil = os.clock() + config.Block.ParryWindow
		s.nextParry = os.clock() + config.Block.ParryCooldown
	end
	s.blocking = active
	character:SetAttribute("RiftBlocking", active)
	humanoid.WalkSpeed = active and config.Block.WalkSpeed or ((character:GetAttribute("RaveRushEnds") or 0) > Workspace:GetServerTimeNow() and config.BaseWalkSpeed * 1.5 or config.BaseWalkSpeed)
	fx:FireAllClients("Block", character, active)
end

local function m1(player)
	local s = getState(player)
	local character, humanoid, root = alive(player)
	if not character or s.blocking or s.attacking or os.clock() < s.stunnedUntil then return end
	local now = os.clock()
	if now < s.nextM1 then return end
	if now - s.lastHit > config.M1.ComboResetTime then s.combo = 0 end
	s.combo = s.combo % #config.M1.Damages + 1
	s.lastHit = now
	local combo = s.combo
	local slowAttack = (character:GetAttribute("Pill_MoodStabilizer") or 0) > os.clock()
	s.nextM1 = now + (combo == 4 and config.M1.FinisherCooldown or config.M1.HitCooldown) * (slowAttack and (1 / 0.97) or 1)
	s.attacking = true
	fx:FireAllClients("Swing", character, combo)
	if character:GetAttribute("FrenzyNausea") == true then
		character:SetAttribute("FrenzyNausea", nil)
		fx:FireAllClients("NauseaMiss", character)
		task.delay(config.M1.Recovery, function() s.attacking = false end)
		return
	end
	-- Resolve hit after short windup; use SERVER character position.
	task.delay(0.12, function()
		local liveChar, _, liveRoot = alive(player)
		if liveChar ~= character or not liveRoot then return end
		local box = liveRoot.CFrame * CFrame.new(0,0,-config.M1.Range / 2)
		local size = Vector3.new(config.M1.Width,config.M1.Height,config.M1.Range)
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {character}
		local touched = {}
		for _, part in Workspace:GetPartBoundsInBox(box,size,params) do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and not touched[model] then
				touched[model] = true
				local targetHum = model:FindFirstChildOfClass("Humanoid")
				local targetRoot = model:FindFirstChild("HumanoidRootPart")
				if targetHum and targetRoot and targetHum.Health > 0
					and not (Players:GetPlayerFromCharacter(model) and
						(character:GetAttribute("RiftSafeZone") == true or model:GetAttribute("RiftSafeZone") == true)) then
					local delta = targetRoot.Position - liveRoot.Position
					if delta.Magnitude <= config.M1.Range + 3 and delta.Magnitude > 0.01 and liveRoot.CFrame.LookVector:Dot(delta.Unit) > 0.10 then
						local defended = model:GetAttribute("RiftBlocking") == true and targetRoot.CFrame.LookVector:Dot((-delta).Unit) >= config.Block.FrontDot
						if defended then
							local defender = Players:GetPlayerFromCharacter(model)
							local ds = defender and getState(defender)
							if ds and os.clock() <= ds.parryUntil then
								s.stunnedUntil = os.clock() + config.Block.ParryStun
								fx:FireAllClients("Parry",model,combo)
							else
								fx:FireAllClients("BlockedHit",model,combo)
							end
						else
							Shield.Damage(model, targetHum, config.M1.Damages[combo], player)
							PillPassive.OnHit(player, model)
							Void.OnHit(player, model)
							if combo == 4 and not targetRoot.Anchored then
								targetRoot.AssemblyLinearVelocity = liveRoot.CFrame.LookVector * config.M1.FinisherKnockback + Vector3.new(0,12,0)
							end
							fx:FireAllClients("Hit",model,combo,config.M1.Damages[combo])
						end
					end
				end
			end
		end
	end)
	task.delay(0.20, function() s.attacking = false end)
end

local function heavy(player)
	local s = getState(player)
	local character, _, root = alive(player)
	if not character or s.blocking or s.attacking or os.clock() < s.stunnedUntil then return end
	local now = os.clock()
	if now < s.nextHeavy then return end
	local slowAttack = (character:GetAttribute("Pill_MoodStabilizer") or 0) > os.clock()
	s.nextHeavy = now + config.Heavy.Cooldown * (slowAttack and (1 / 0.97) or 1)
	s.attacking = true
	fx:FireAllClients("HeavySwing",character)
	if character:GetAttribute("FrenzyNausea") == true then
		character:SetAttribute("FrenzyNausea", nil)
		fx:FireAllClients("NauseaMiss", character)
		task.delay(config.Heavy.Recovery, function() s.attacking = false end)
		return
	end
	task.delay(config.Heavy.Windup,function()
		local current, _, currentRoot = alive(player)
		if current ~= character or not currentRoot or os.clock() < s.stunnedUntil then return end
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {character}
		local seen = {}
		local box = currentRoot.CFrame * CFrame.new(0,0,-config.Heavy.Range/2)
		for _, part in Workspace:GetPartBoundsInBox(box,Vector3.new(config.Heavy.Width,config.Heavy.Height,config.Heavy.Range),params) do
			local target = part:FindFirstAncestorOfClass("Model")
			if target and not seen[target] then
				seen[target] = true
				local hum = target:FindFirstChildOfClass("Humanoid")
				local targetRoot = target:FindFirstChild("HumanoidRootPart")
				if hum and targetRoot and hum.Health > 0
					and not (Players:GetPlayerFromCharacter(target) and
						(character:GetAttribute("RiftSafeZone") == true or target:GetAttribute("RiftSafeZone") == true)) then
					local offset = targetRoot.Position-currentRoot.Position
					if offset.Magnitude > 0.01 and offset.Magnitude <= config.Heavy.Range+2 and currentRoot.CFrame.LookVector:Dot(offset.Unit) > 0.1 then
						local guarded = target:GetAttribute("RiftBlocking") == true and targetRoot.CFrame.LookVector:Dot(-offset.Unit) >= config.Block.FrontDot
						local defender = Players:GetPlayerFromCharacter(target)
						local ds = defender and getState(defender)
						if guarded and ds and now <= ds.parryUntil then
							s.stunnedUntil = os.clock()+config.Block.ParryStun
							fx:FireAllClients("Parry",target)
						else
							if guarded then
								if ds then
									ds.blocking = false
									ds.stunnedUntil = os.clock()+config.Heavy.GuardBreakStun
									local defenderHum = target:FindFirstChildOfClass("Humanoid")
									if defenderHum then defenderHum.WalkSpeed = 0 end
									task.delay(config.Heavy.GuardBreakStun,function()
										if defenderHum and defenderHum.Parent and ds and os.clock() >= ds.stunnedUntil then defenderHum.WalkSpeed=config.BaseWalkSpeed end
									end)
								end
								target:SetAttribute("RiftBlocking",false)
								if target:GetAttribute("RiftNPC") == true then
									target:SetAttribute("RiftNPCStunnedUntil", os.clock() + config.Heavy.GuardBreakStun)
								end
								fx:FireAllClients("GuardBreak",target)
							else
								Shield.Damage(target, hum, config.Heavy.Damage, player)
								PillPassive.OnHit(player, target)
								Void.OnHit(player, target)
								if not targetRoot.Anchored then targetRoot.AssemblyLinearVelocity=currentRoot.CFrame.LookVector*config.Heavy.Knockback end
								fx:FireAllClients("Hit",target,5,config.Heavy.Damage)
							end
						end
					end
				end
			end
		end
	end)
	task.delay(config.Heavy.Recovery,function() s.attacking=false end)
end

local function dash(player)
	local s = getState(player)
	local character, humanoid, root = alive(player)
	if not character or s.blocking or s.attacking or os.clock() < s.stunnedUntil then return end
	local now = os.clock()
	if now < s.nextDash then return end
	s.nextDash = now + config.Dash.Cooldown
	-- Humanoid.MoveDirection is a world-space vector, supporting WASD, thumbstick and touch.
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then direction = root.CFrame.LookVector end
	direction = Vector3.new(direction.X,0,direction.Z)
	if direction.Magnitude < 0.01 then return end
	direction = direction.Unit
	local velocity = Instance.new("LinearVelocity")
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	velocity.Attachment0 = attachment
	velocity.MaxForce = 100000
	velocity.VectorVelocity = direction * config.Dash.Speed
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.Parent = root
	Debris:AddItem(velocity,0.17)
	Debris:AddItem(attachment,0.17)
	fx:FireAllClients("Dash",character)
end

request.OnServerEvent:Connect(function(player, action, value)
	if typeof(action) ~= "string" then return end
	if action == "M1" then m1(player)
	elseif action == "Heavy" then heavy(player)
	elseif action == "Block" and typeof(value) == "boolean" then block(player,value)
	elseif action == "Dash" then dash(player)
	end
end)

local function setup(player)
	getState(player)
	-- Default to Unarmed; Ashley is granted as an unlocked starter Spec.
	Selection.Initialize(player)
	PillPassive.Reset(player)
	Shield.ResetPlayer(player)
	Buzz.ResetPlayer(player)
	AshleyMoves.ResetPlayer(player)
	Void.ResetPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local s = getState(player)
		s.combo,s.lastHit,s.nextM1,s.nextDash = 0,0,0,0
		s.blocking,s.attacking = false,false
		s.nextHeavy,s.stunnedUntil,s.parryUntil,s.nextParry = 0,0,0,0
		character:SetAttribute("RiftBlocking",false)
		Shield.Clear(character)
		Buzz.Clear(character)
		AshleyMoves.ClearCharacter(character)
		Void.ClearCharacter(character)
		PillPassive.Reset(player)
	end)
	if player.Character then player.Character:SetAttribute("RiftBlocking",false) end
end
Players.PlayerAdded:Connect(setup)
for _,player in Players:GetPlayers() do setup(player) end
Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
	Selection.Remove(player)
end)

if game:GetService("RunService"):IsStudio() then
	local dummy = Instance.new("Model")
	dummy.Name = "RIFTBOUND Training Dummy"
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 500
	hum.Health = 500
	hum.Parent = dummy
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2,5,2)
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		local location = spawn and spawn.Position or Vector3.new(0, 0, 0)
		local worldFolder = Workspace:FindFirstChild("RIFTBOUND World")
		local ground = worldFolder and worldFolder:GetAttribute("GroundY")
		root.Position = Vector3.new(location.X, (typeof(ground) == "number" and ground + 2.5) or location.Y + 4, location.Z - 12)
	root.Color = Color3.fromRGB(210,65,75)
	root.Material = Enum.Material.Neon
	root.Anchored = true
	root.Parent = dummy
	dummy.PrimaryPart = root
	dummy.Parent = Workspace
	hum.Died:Connect(function() task.delay(3,function() if dummy.Parent then hum.Health=hum.MaxHealth end end) end)
end


-- Spawn world encounter NPCs without coupling their startup to core combat.
-- The Studio dummy and player combat continue working if this module is missing.
task.defer(function()
	local module = script:FindFirstChild("CombatNPCs") or script:WaitForChild("CombatNPCs", 4)
	if not module or not module:IsA("ModuleScript") then
		warn("[RIFTBOUND] Combat NPC module not found; base combat remains available.")
		return
	end
	local ok, npc = pcall(require, module)
	if not ok or type(npc) ~= "table" or type(npc.Start) ~= "function" then
		warn("[RIFTBOUND] Combat NPC module could not load:", npc)
		return
	end
	local started, err = pcall(npc.Start, {
		DealDamage = function(character, humanoid, damage)
			return Shield.Damage(character, humanoid, damage)
		end,
		IsParrying = function(player)
			local s = getState(player)
			return s.blocking == true and os.clock() <= s.parryUntil
		end,
		AwardDefeat = function(player, npcName)
			return Progression.AwardNPCDefeat(player, npcName)
		end,
	})
	if not started then warn("[RIFTBOUND] Combat NPC startup failed:", err) end
end)
