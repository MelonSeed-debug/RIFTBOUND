--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local rift = ReplicatedStorage:WaitForChild("Riftbound")
local config = require(rift.Shared.CombatConfig)
local worldCfg = require(rift.Shared.WorldConfig)
local masteryCfg = require(rift.Shared.MasteryConfig)
local Hitbox = require(script:WaitForChild("CombatHitbox", 8))
-- Sword tuning stays optional: a missing new file cannot break legacy combat.
local swordSpec = {Passive = {}}
local swordSpecModule = rift.Shared:FindFirstChild("GreatSwordSpec")
	or rift.Shared:WaitForChild("GreatSwordSpec", 5)
if swordSpecModule then
	local ok, result = pcall(require, swordSpecModule)
	if ok and type(result) == "table" then swordSpec = result end
end
local masteryRemote = rift.Remotes:FindFirstChild("MasteryFX")

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
local Shield = {Activate = function() return false end, Damage = function(_, hum, n) hum:TakeDamage(n) return n end, Clear = function() end, ResetPlayer = function() end}
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
-- Optional Sword move module (including model equipment). No errors here
-- should disable the two original Specs or the core combat system.
local Sword = {
	Cast = function() return false end,
	Start = function() end,
	Refresh = function() end,
	StopPlayerBuffs = function() end,
	ClearCharacter = function() end,
	ResetPlayer = function() end,
}
local swordModule = script:FindFirstChild("GreatSwordMoves")
	or script:WaitForChild("GreatSwordMoves", 5)
local swordLoaded = false
if swordModule then
	local ok, result = pcall(require, swordModule)
	if ok and type(result) == "table" then
		Sword = result
		swordLoaded = true
		print("[RIFTBOUND Sword] GreatSwordMoves loaded successfully.")
	else
		warn("[RIFTBOUND] Great Sword module failed; legacy Specs still work:", result)
	end
else
	warn("[RIFTBOUND Sword] GreatSwordMoves missing! Check Rojo sync and restart server.")
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
-- These feature services are isolated so inventory/dialogue failures cannot
-- stop M1, blocking, Spec selection, quest rewards or saved progression.
local function bootOptional(moduleName)
	local instance = script:FindFirstChild(moduleName) or script:WaitForChild(moduleName, 3)
	if not instance or not instance:IsA("ModuleScript") then
		warn("[RIFTBOUND] Missing optional server service:", moduleName)
		return
	end
	local ok,service=pcall(require,instance)
	if not ok or type(service)~="table" or type(service.Start)~="function" then
		warn("[RIFTBOUND] Cannot load service:",moduleName,service)
		return
	end
	local started,err=pcall(service.Start)
	if not started then warn("[RIFTBOUND] Cannot start service:",moduleName,err) end
end
task.defer(function()
	bootOptional("EconomyService")
	bootOptional("WorldActors")
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
					Sword.StopPlayerBuffs(player)
				end
				if not swordLoaded and player:GetAttribute("EquippedSpec") == "GreatSword" then
					player:SetAttribute("GreatSwordEquipStatus",
						"GreatSwordMoves not loaded. Restart Rojo and reconnect Studio.")
				else
					local attached, err = pcall(Sword.Refresh, player)
					if not attached then
						warn("[RIFTBOUND Sword] Equip refresh failed:", err)
						player:SetAttribute("GreatSwordEquipStatus", "Server sword error: check Output.")
					end
				end
			end
			return
		end
		-- The server checks Spec ownership, unlock thresholds and the actual
		-- ability cooldown. XP is granted only if Cast/Activate returns true.
		local skill=masteryCfg.SkillActions[action]
		if not skill then return end
		if player:GetAttribute("EquippedSpec")~=skill.Spec then return end
		-- Casting while hitstunned would evade stagger with teleport/guard.
		if Hitbox.IsStunned(player.Character) then return end
		local needed=masteryCfg.SkillRequirements[skill.Key] or 0
		local owned=player:GetAttribute("SpecMastery_"..skill.Spec) or 0
		if owned<needed then
			if masteryRemote then
				masteryRemote:FireClient(player,skill.Key,needed,owned)
			end
			return
		end

		local castSucceeded=false
		if action == "PillShield" then castSucceeded=Shield.Activate(player)
		elseif action == "BuzzBoost" then castSucceeded=Buzz.Activate(player)
		elseif action == "RaveRush" then castSucceeded=AshleyMoves.Cast(player, "C")
		elseif action == "TrippyToss" then castSucceeded=AshleyMoves.Cast(player, "V")
		elseif action == "Frenzy" then castSucceeded=AshleyMoves.Cast(player, "G")
		elseif action == "VoidGuard" then castSucceeded=Void.Cast(player, "Z")
		elseif action == "VoidStep" then castSucceeded=Void.Cast(player, "X")
		elseif action == "VoidGrasp" then castSucceeded=Void.Cast(player, "C")
		elseif action == "VoidCleave" then castSucceeded=Void.Cast(player, "V")
		elseif action == "VoidNova" then castSucceeded=Void.Cast(player, "G")
		elseif action == "SwordGuard" then castSucceeded=Sword.Cast(player, "Z")
		elseif action == "SwordLunge" then castSucceeded=Sword.Cast(player, "X")
		elseif action == "SwordUplift" then castSucceeded=Sword.Cast(player, "C")
		elseif action == "SwordSlam" then castSucceeded=Sword.Cast(player, "V")
		elseif action == "SwordExecution" then castSucceeded=Sword.Cast(player, "G") end
		if castSucceeded == true and Progression.AwardSkillUse then
			Progression.AwardSkillUse(player,skill.Spec,skill.Key)
		end
	end)
end
local request = rift.Remotes.CombatRequest
local fx = rift.Remotes.CombatFX

-- Combat 2.0: server-owned hitstun, counter windows and attack sequences.
local states = {}
local v2 = config.CombatV2
local function getState(player)
	if not states[player] then
		states[player] = {
			combo=0, lastHit=0, nextM1=0, nextDash=0,
			blocking=false, attacking=false,
			nextHeavy=0, stunnedUntil=0, parryUntil=0, nextParry=0,
			attackSerial=0, counterUntil=0,
		}
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

local function stunned(player, character)
	local s = getState(player)
	return os.clock() < s.stunnedUntil or Hitbox.IsStunned(character)
end

local function stagger(character, seconds)
	if not Hitbox.Stagger(character, seconds) then return end
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		local s = getState(player)
		s.attackSerial += 1 -- instantly cancels unresolved server attack callbacks
		s.attacking = false
		local wasBlocking = s.blocking
		s.blocking = false
		s.combo = 0
		s.parryUntil = 0
		s.stunnedUntil = math.max(s.stunnedUntil, os.clock() + seconds)
		character:SetAttribute("RiftBlocking", false)
		local hum = character:FindFirstChildOfClass("Humanoid")
		if hum and wasBlocking then hum.WalkSpeed = config.BaseWalkSpeed end
		fx:FireAllClients("Block", character, false)
	end
	fx:FireAllClients("Stagger", character)
end

-- Only the next VALID attack consumes the parry reward. One swing can hit
-- several targets, but the bonus is computed once, from server state.
local function consumeCounter(s, sword)
	local now = os.clock()
	if now > s.counterUntil then return 1 end
	s.counterUntil = 0
	return sword and v2.SwordCounterDamageBonus or v2.CounterDamageBonus
end

local function guarded(target, targetRoot, attackerRoot)
	if target:GetAttribute("RiftBlocking") ~= true then return false end
	local towardAttacker = attackerRoot.Position - targetRoot.Position
	local flat = Vector3.new(towardAttacker.X, 0, towardAttacker.Z)
	if flat.Magnitude < 0.1 then return false end
	return targetRoot.CFrame.LookVector:Dot(flat.Unit) >= config.Block.FrontDot
end

-- Uniform block -> perfect-parry -> guard-break -> damage flow. All outcomes
-- are resolved from the target's CURRENT state at hit time, not attack start.
local function strike(player, character, entry, damage, combo, heavy, stunTime, bonus)
	local target = entry.model
	local hum = entry.humanoid
	local targetRoot = entry.root
	if not target.Parent or hum.Health <= 0 then return false end
	local attackerRoot = character:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return false end
	if guarded(target, targetRoot, attackerRoot) then
		local defender = Players:GetPlayerFromCharacter(target)
		local ds = defender and getState(defender) or nil
		local parrying = ds and ds.blocking and os.clock() <= ds.parryUntil
		if parrying then
			-- A parry is earned ONLY when a server-validated hit meets guard
			-- direction inside the 0.25s perfect-block window.
			ds.parryUntil = 0
			ds.counterUntil = os.clock() + v2.CounterWindow
			stagger(character, v2.ParryStun)
			fx:FireAllClients("Parry", target, combo)
			return false
		end
		if heavy then
			target:SetAttribute("RiftBlocking", false)
			stagger(target, config.Heavy.GuardBreakStun)
			fx:FireAllClients("GuardBreak", target, combo)
		else
			fx:FireAllClients("BlockedHit", target, combo)
		end
		return false
	end

	local dealt = Shield.Damage(target, hum, damage * bonus, player) or 0
	if dealt <= 0 then return false end
	PillPassive.OnHit(player, target)
	Void.OnHit(player, target)
	stagger(target, stunTime)
	if not targetRoot.Anchored then
		if heavy then
			targetRoot.AssemblyLinearVelocity = attackerRoot.CFrame.LookVector
				* (config.Heavy.Knockback + (player:GetAttribute("EquippedSpec") == "GreatSword" and 8 or 0))
				+ Vector3.new(0, 7, 0)
		elseif combo == 4 then
			targetRoot.AssemblyLinearVelocity = attackerRoot.CFrame.LookVector
				* config.M1.FinisherKnockback + Vector3.new(0, 12, 0)
		end
	end
	fx:FireAllClients("Hit", target, combo, math.round(dealt * 10) / 10)
	return true
end

local function block(player, active)
	local s = getState(player)
	local character, humanoid = alive(player)
	if not character then return end
	if not active then
		-- Always permit releasing block, including during stagger.
		s.blocking = false
		s.parryUntil = 0
		character:SetAttribute("RiftBlocking", false)
		humanoid.WalkSpeed = config.BaseWalkSpeed
		fx:FireAllClients("Block", character, false)
		return
	end
	if s.blocking or s.attacking or stunned(player, character) then return end
	local current = os.clock()
	if current >= s.nextParry then
		s.parryUntil = current + config.Block.ParryWindow
		s.nextParry = current + config.Block.ParryCooldown
	else
		s.parryUntil = 0
	end
	s.blocking = true
	character:SetAttribute("RiftBlocking", true)
	humanoid.WalkSpeed = config.Block.WalkSpeed
	fx:FireAllClients("Block", character, true)
end

local function m1(player)
	local s = getState(player)
	local character = alive(player)
	if not character or s.blocking or s.attacking or stunned(player, character) then return end
	local now = os.clock()
	if now < s.nextM1 then return end
	local sword = player:GetAttribute("EquippedSpec") == "GreatSword" and swordSpec.Passive or nil
	local resetWindow = sword and v2.SwordComboResetTime or config.M1.ComboResetTime
	if now - s.lastHit > resetWindow then s.combo = 0 end
	s.combo = s.combo % #config.M1.Damages + 1
	s.lastHit = now
	local combo = s.combo
	local windup = sword and sword.M1Windup or config.M1.Windup
	local recovery = sword and sword.M1Recovery or config.M1.Recovery
	local cooldown = combo == 4 and (sword and sword.M1FinisherCooldown or config.M1.FinisherCooldown)
		or (sword and sword.M1HitCooldown or config.M1.HitCooldown)
	local slowAttack = (character:GetAttribute("Pill_MoodStabilizer") or 0) > now
	s.nextM1 = now + cooldown * (slowAttack and (1 / 0.97) or 1)
	s.attacking = true
	s.attackSerial += 1
	local serial = s.attackSerial
	local bonus = consumeCounter(s, sword)
	if bonus > 1 then fx:FireAllClients("Counter", character) end
	fx:FireAllClients("Swing", character, combo)

	if character:GetAttribute("FrenzyNausea") == true then
		character:SetAttribute("FrenzyNausea", nil)
		fx:FireAllClients("NauseaMiss", character)
	else
		task.delay(windup, function()
			local currentCharacter, _, root = alive(player)
			if currentCharacter ~= character or not root or serial ~= s.attackSerial
				or stunned(player, character)
				or (sword and player:GetAttribute("EquippedSpec") ~= "GreatSword") then return end
			local range = sword and sword.M1Range or config.M1.Range
			local width = sword and sword.M1Width or config.M1.Width
			local damage = sword and sword.M1Damage and sword.M1Damage[combo]
				or config.M1.Damages[combo]
			local stun = sword and v2.SwordHitstun or v2.UnarmedHitstun
			if combo == 4 then
				stun = sword and v2.SwordFinisherHitstun or v2.UnarmedFinisherHitstun
			end
			for _, target in Hitbox.Scan(character, root, range, width,
				config.M1.Height, {FrontDot = sword and -0.12 or 0.02}) do
				-- A successful parry cancels the attack mid-resolution.
				if serial ~= s.attackSerial then break end
				strike(player, character, target, damage, combo, false, stun, bonus)
			end
		end)
	end
	task.delay(recovery, function()
		if serial == s.attackSerial then s.attacking = false end
	end)
end

local function heavy(player)
	local s = getState(player)
	local character = alive(player)
	if not character or s.blocking or s.attacking or stunned(player, character) then return end
	local now = os.clock()
	if now < s.nextHeavy then return end
	local sword = player:GetAttribute("EquippedSpec") == "GreatSword" and swordSpec.Passive or nil
	local cooldown = sword and sword.HeavyCooldown or config.Heavy.Cooldown
	local windup = sword and sword.HeavyWindup or config.Heavy.Windup
	local recovery = sword and sword.HeavyRecovery or config.Heavy.Recovery
	local slowAttack = (character:GetAttribute("Pill_MoodStabilizer") or 0) > now
	s.nextHeavy = now + cooldown * (slowAttack and (1 / 0.97) or 1)
	s.attacking = true
	s.attackSerial += 1
	local serial = s.attackSerial
	local bonus = consumeCounter(s, sword)
	if bonus > 1 then fx:FireAllClients("Counter", character) end
	fx:FireAllClients("HeavySwing", character)
	if character:GetAttribute("FrenzyNausea") == true then
		character:SetAttribute("FrenzyNausea", nil)
		fx:FireAllClients("NauseaMiss", character)
	else
		task.delay(windup, function()
			local liveCharacter, _, root = alive(player)
			if liveCharacter ~= character or not root or serial ~= s.attackSerial
				or stunned(player, character)
				or (sword and player:GetAttribute("EquippedSpec") ~= "GreatSword") then return end
			local range = sword and sword.HeavyRange or config.Heavy.Range
			local width = sword and sword.HeavyWidth or config.Heavy.Width
			local damage = sword and sword.HeavyDamage or config.Heavy.Damage
			local stun = sword and v2.SwordHeavyHitstun or v2.HeavyHitstun
			for _, target in Hitbox.Scan(character, root, range, width,
				config.Heavy.Height, {FrontDot = sword and -0.16 or 0.0}) do
				if serial ~= s.attackSerial then break end
				strike(player, character, target, damage, 5, true, stun, bonus)
			end
		end)
	end
	task.delay(recovery, function()
		if serial == s.attackSerial then s.attacking = false end
	end)
end

local function dash(player)
	local s = getState(player)
	local character, humanoid, root = alive(player)
	if not character or s.blocking or s.attacking or stunned(player, character) then return end
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
	-- Pass directional metadata ONLY for animation selection. Actual
	-- distance/speed remains server-authoritative and unchanged.
	local forwardDot = root.CFrame.LookVector:Dot(direction)
	local sideDot = root.CFrame.RightVector:Dot(direction)
	local dashDirection
	if math.abs(sideDot) > math.abs(forwardDot) then
		dashDirection = sideDot >= 0 and "Right" or "Left"
	else
		dashDirection = forwardDot < 0 and "Back" or "Forward"
	end
	fx:FireAllClients("Dash",character,dashDirection)
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
	Sword.ResetPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local s = getState(player)
		s.combo,s.lastHit,s.nextM1,s.nextDash = 0,0,0,0
		s.blocking,s.attacking = false,false
		s.nextHeavy,s.stunnedUntil,s.parryUntil,s.nextParry = 0,0,0,0
		s.attackSerial += 1
		s.counterUntil = 0
		character:SetAttribute("RiftHitstunUntil",0)
		character:SetAttribute("RiftBlocking",false)
		Shield.Clear(character)
		Buzz.Clear(character)
		AshleyMoves.ClearCharacter(character)
		Void.ClearCharacter(character)
		Sword.ClearCharacter(character)
		PillPassive.Reset(player)
	end)
	if player.Character then
		player.Character:SetAttribute("RiftHitstunUntil",0)
		player.Character:SetAttribute("RiftBlocking",false)
	end
end
Players.PlayerAdded:Connect(setup)
for _,player in Players:GetPlayers() do setup(player) end
-- Attach the imported sword whenever GreatSword is equipped or a character respawns.
local startedSword, swordError = pcall(Sword.Start)
if not startedSword then warn("[RIFTBOUND Sword] Equip watcher unavailable:", swordError) end
Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
	Selection.Remove(player)
end)

if game:GetService("RunService"):IsStudio() then
	-- This dummy is a repeatable COMBAT TARGET, not an enemy to grind.
	-- A dead Humanoid cannot be reliably brought back with Health=MaxHealth;
	-- that old code made M1s appear to stop dealing damage after ~500 HP.
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local location = spawn and spawn.Position or Vector3.new(0, 0, 0)
	local worldFolder = Workspace:FindFirstChild("RIFTBOUND World")
	local ground = worldFolder and worldFolder:GetAttribute("GroundY")
	local offset = worldCfg.TrainingDummy or Vector3.new(0, 0, -12)
	local targetPosition = Vector3.new(location.X + offset.X,
		(typeof(ground) == "number" and ground + 4) or location.Y + 4,
		location.Z + offset.Z)

	local function createTrainingDummy()
		local dummy = Instance.new("Model")
		dummy.Name = "RIFTBOUND Training Dummy"
		dummy:SetAttribute("RiftTrainingDummy", true)
		local hum = Instance.new("Humanoid")
		hum.MaxHealth = 500
		hum.Health = 500
		hum.BreakJointsOnDeath = false
		hum.Parent = dummy
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 5, 2)
		root.Position = targetPosition
		root.Color = Color3.fromRGB(210, 65, 75)
		root.Material = Enum.Material.Neon
		root.Anchored = true
		root.Parent = dummy
		dummy.PrimaryPart = root
		dummy.Parent = Workspace

		-- Refill just before the 500-HP dummy would die, so repeated M1s,
		-- sword combos and ability tests remain hittable without restarting Play.
		hum.HealthChanged:Connect(function(health)
			if health > 0 and health <= 85 and hum.Parent and dummy.Parent then
				hum.Health = hum.MaxHealth
			end
		end)
		-- Safety net if any oversized damage bypasses the refill threshold:
		-- replace the DEAD Humanoid/model rather than trying to revive it.
		hum.Died:Connect(function()
			task.delay(1.5, function()
				if not dummy.Parent then return end
				dummy:Destroy()
				createTrainingDummy()
			end)
		end)
		return dummy
	end

	-- Studio Play can retain an obsolete dummy during script reloading.
	local old = Workspace:FindFirstChild("RIFTBOUND Training Dummy")
	if old then old:Destroy() end
	createTrainingDummy()
	print("[RIFTBOUND Training] Infinite practice dummy ready; health auto-refills.")
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
-- Dungeon waits until the shared NPC module has been bootstrapped.
task.defer(function()
	task.wait(0.25)
	bootOptional("DungeonService")
end)
