--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local rift = ReplicatedStorage:WaitForChild("Riftbound")
local config = require(rift.Shared.CombatConfig)
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
local specRequest = rift.Remotes:FindFirstChild("SpecRequest")
if specRequest then
	specRequest.OnServerEvent:Connect(function(player, action)
		if action == "PillShield" then Shield.Activate(player)
		elseif action == "BuzzBoost" then Buzz.Activate(player) end
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
	humanoid.WalkSpeed = active and config.Block.WalkSpeed or config.BaseWalkSpeed
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
	s.nextM1 = now + (combo == 4 and config.M1.FinisherCooldown or config.M1.HitCooldown)
	s.attacking = true
	fx:FireAllClients("Swing", character, combo)
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
				if targetHum and targetRoot and targetHum.Health > 0 then
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
							Shield.Damage(model, targetHum, config.M1.Damages[combo])
							PillPassive.OnHit(player, model)
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
	s.nextHeavy = now + config.Heavy.Cooldown
	s.attacking = true
	fx:FireAllClients("HeavySwing",character)
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
				if hum and targetRoot and hum.Health > 0 then
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
								fx:FireAllClients("GuardBreak",target)
							else
								Shield.Damage(target, hum, config.Heavy.Damage)
								PillPassive.OnHit(player, target)
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
	-- Draft testing: give Ashley to testers in Studio until Spec selection is implemented.
	if game:GetService("RunService"):IsStudio() then player:SetAttribute("EquippedSpec", "AshleySimmons") end
	PillPassive.Reset(player)
	Shield.ResetPlayer(player)
	Buzz.ResetPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local s = getState(player)
		s.combo,s.lastHit,s.nextM1,s.nextDash = 0,0,0,0
		s.blocking,s.attacking = false,false
		s.nextHeavy,s.stunnedUntil,s.parryUntil,s.nextParry = 0,0,0,0
		character:SetAttribute("RiftBlocking",false)
		Shield.Clear(character)
		Buzz.Clear(character)
		PillPassive.Reset(player)
	end)
	if player.Character then player.Character:SetAttribute("RiftBlocking",false) end
end
Players.PlayerAdded:Connect(setup)
for _,player in Players:GetPlayers() do setup(player) end
Players.PlayerRemoving:Connect(function(player) states[player]=nil end)

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
	root.Position = Vector3.new(0,4,-12)
	root.Color = Color3.fromRGB(210,65,75)
	root.Material = Enum.Material.Neon
	root.Anchored = true
	root.Parent = dummy
	dummy.PrimaryPart = root
	dummy.Parent = Workspace
	hum.Died:Connect(function() task.delay(3,function() if dummy.Parent then hum.Health=hum.MaxHealth end end) end)
end
