--!strict
-- Unified R15 combat motion: the same named moves for every player.
-- Uploaded animation IDs take priority; procedural poses are a temporary fallback.
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- A missing Rojo-synced config must NEVER yield forever. The old unbounded
-- WaitForChild stopped the client before building any UI.
local function service(name)
	local ok, result = pcall(function() return game:GetService(name) end)
	return ok and result or nil
end
local AnimationClipProvider = service("AnimationClipProvider")
local KeyframeSequenceProvider = service("KeyframeSequenceProvider")
local shared = ReplicatedStorage:FindFirstChild("Riftbound")
local sharedFolder = shared and (shared:FindFirstChild("Shared") or shared:WaitForChild("Shared", 3))
local configModule = sharedFolder and (sharedFolder:FindFirstChild("AnimationConfig")
	or sharedFolder:WaitForChild("AnimationConfig", 3))
if not configModule or not configModule:IsA("ModuleScript") then
	error("[RIFTBOUND Animations] AnimationConfig missing under ReplicatedStorage/Riftbound/Shared. Restart Rojo and reconnect Studio.")
end
local Config = require(configModule)
local Motion = {}
local states = setmetatable({}, {__mode = "k"})

local function getState(character)
	if not states[character] then states[character] = {sequence = 0, tweens = {}, tracks = {}, originals = {}} end
	return states[character]
end

local function getMotors(character)
	local motors = {}
	for _, node in character:GetDescendants() do
		if node:IsA("Motor6D") then
			if node.Name == "RightShoulder" or node.Name == "Right Shoulder" then motors.right = node
			elseif node.Name == "LeftShoulder" or node.Name == "Left Shoulder" then motors.left = node
			elseif node.Name == "Waist" or node.Name == "RootJoint" or node.Name == "Root" then motors.body = node end
		end
	end
	return motors
end

local function clearTweens(s)
	for _, tween in s.tweens do tween:Cancel() end
	table.clear(s.tweens)
end

local function reset(character, s, duration)
	clearTweens(s)
	for motor, original in s.originals do
		if motor.Parent then
			local tween = TweenService:Create(motor, TweenInfo.new(duration or 0.14), {C0 = original})
			table.insert(s.tweens, tween)
			tween:Play()
		end
	end
end

local function fallback(character, s, move, persistent)
	clearTweens(s)
	s.sequence += 1
	local sequence = s.sequence
	local right = CFrame.new()
	local left = CFrame.new()
	local body = CFrame.new()
	local angle = math.rad
	if move == "M1_1" or move == "M1_3" then
		right = CFrame.Angles(angle(-105), angle(12), angle(28))
		left = CFrame.Angles(angle(-30), 0, angle(-18))
		body = CFrame.Angles(0, angle(24), 0)
	elseif move == "M1_2" or move == "M1_4" then
		right = CFrame.Angles(angle(-30), 0, angle(18))
		left = CFrame.Angles(angle(-105), angle(-12), angle(-28))
		body = CFrame.Angles(0, angle(-24), 0)
	elseif move == "Heavy" then
		right = CFrame.Angles(angle(-155), 0, angle(35))
		left = CFrame.Angles(angle(-95), 0, angle(-35))
		body = CFrame.Angles(angle(-14), angle(-22), 0)
	elseif move == "Block" then
		right = CFrame.Angles(angle(-115), 0, angle(30))
		left = CFrame.Angles(angle(-115), 0, angle(-30))
	elseif move == "Dash" then
		right = CFrame.Angles(angle(35), 0, angle(15))
		left = CFrame.Angles(angle(35), 0, angle(-15))
		body = CFrame.Angles(angle(23), 0, 0)
	elseif move == "Hit" or move == "GuardBreak" then
		right = CFrame.Angles(angle(50), 0, angle(15))
		left = CFrame.Angles(angle(50), 0, angle(-15))
		body = CFrame.Angles(angle(18), 0, 0)
	end
	local targets = {right=right,left=left,body=body}
	for key, motor in getMotors(character) do
		if not s.originals[motor] then s.originals[motor] = motor.C0 end
		local tween = TweenService:Create(motor, TweenInfo.new(0.09, Enum.EasingStyle.Quad), {
			C0 = s.originals[motor] * targets[key],
		})
		table.insert(s.tweens, tween)
		tween:Play()
	end
	if not persistent then
		task.delay(move == "Heavy" and 0.42 or 0.23, function()
			if s.sequence == sequence then reset(character, s, 0.15) end
		end)
	end
end

-- The curated .rbxm holds KeyframeSequences, NOT uploaded animation IDs.
-- Roblox lets Studio preview these as temporary hash:// IDs. Those hashes
-- never work in a published experience, so real uploaded IDs take priority.
local clipIds = setmetatable({}, {__mode = "k"})
local lastMissingWarning = false

-- Players sometimes import a model one level too deep or into Workspace,
-- or only have the ORIGINAL 150+ pack after a failed download. Recognize
-- both situations without making anyone import the ZIP again.
local originalSources = {
	M1_1={"Gauntlets Animations","M1 - 1"},
	M1_2={"Gauntlets Animations","M1 - 2"},
	M1_3={"Gauntlets Animations","M1 - 3"},
	M1_4={"Gauntlets Animations","M1 - 4"},
	Heavy={"Gauntlets Animations","Gauntlet Heavy"},
	Block={"Gauntlets Animations","blocking idle"},
	Parry={"Gauntlets Animations","parry 1"},
	GuardBreak={"Gauntlets Animations","Gauntlets_Parried"},
	Dash={"Dual Axes Animations","front dash"},
	DashLeft={"Dual Axes Animations","dash left"},
	DashRight={"Dual Axes Animations","dash right"},
	DashBack={"Dual Axes Animations","back dah"},
	Hit={"Dual Axes Animations","Flinch"},
	-- These names were verified inside the supplied ORIGINAL .rbxm.
	SwordM1_1={"Great Sword Animations","M1"},
	SwordM1_2={"Great Sword Animations","M2"},
	SwordM1_3={"Great Sword Animations","M3"},
	SwordM1_4={"Great Sword Animations","M4"},
	SwordHeavy={"Great Sword Animations","Greatsword Heavy"},
	SwordBlock={"Great Sword Animations","Blocking"},
	SwordParry={"Great Sword Animations","Parry"},
	SwordParried={"Great Sword Animations","Parried"},
	SwordDashAttack={"Great Sword Animations","DashAttack"},
	SwordUplift={"Great Sword Animations","TitanBladeUpTilt"},
	SwordSlam={"Great Sword Animations","TitanBladeAirSlam"},
	SwordExecution={"Great Sword Animations","M5"},
	SwordIdle={"Great Sword Animations","Idle"},
	SwordWalk={"Great Sword Animations","WalkWeaponShouldered"},
	SwordRun={"Great Sword Animations","RunWeaponShouldered"},
}

local function findSequence(move)
	local library=ReplicatedStorage:FindFirstChild(Config.PreviewFolder,true)
		or workspace:FindFirstChild(Config.PreviewFolder,true)
	local sequence=library and library:FindFirstChild(move,true)
	if sequence and sequence:IsA("KeyframeSequence") then
		return sequence
	end
	local source=originalSources[move]
	if not source then return nil end
	for _, root in {ReplicatedStorage, workspace} do
		local family=root:FindFirstChild(source[1],true)
		if family then
			local saves=family:FindFirstChild("AnimSaves",true)
			local original=saves and saves:FindFirstChild(source[2],true)
			if original and original:IsA("KeyframeSequence") then
				return original
			end
		end
	end
	return nil
end

function Motion.GetStatus()
	if findSequence("M1_1") or findSequence("SwordM1_1") then
		return "Imported animation clips found"
	end
	if (typeof(Config.Moves.M1_1)=="string" and Config.Moves.M1_1~="")
		or (typeof(Config.Moves.SwordM1_1)=="string" and Config.Moves.SwordM1_1~="") then
		return "Published animation IDs configured"
	end
	return "No animation clips: import the model into ReplicatedStorage"
end

local function resolveId(move)
	local id = Config.Moves[move]
	if typeof(id) == "string" and id ~= "" then
		if id:match("^%d+$") then return "rbxassetid://" .. id end
		return id
	end
	if Config.StudioPreview ~= true or not RunService:IsStudio() then
		return nil
	end
	local sequence = findSequence(move)
	if not sequence then
		if not lastMissingWarning then
			lastMissingWarning = true
			warn("[RIFTBOUND Animations] No KeyframeSequences found for",move,
				"Import either original 150+ pack or curated RIFTBOUND Animation Clips" ..
				" into ReplicatedStorage. Procedural fallback is active.")
		end
		return nil
	end
	if clipIds[sequence] then return clipIds[sequence] end
	local ok, previewId = false, nil
	if AnimationClipProvider then
		ok, previewId = pcall(function()
			return AnimationClipProvider:RegisterAnimationClip(sequence)
		end)
	end
	if (not ok or typeof(previewId) ~= "string" or previewId == "")
		and KeyframeSequenceProvider then
		-- Legacy fallback for Studio versions which don't accept clips.
		ok, previewId = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(sequence)
		end)
	end
	if ok and typeof(previewId) == "string" and previewId ~= "" then
		clipIds[sequence] = previewId
		return previewId
	end
	warn("[RIFTBOUND Animations] Could not register Studio preview:",move,previewId)
	return nil
end

local function playAsset(character, s, move)
	local id = resolveId(move)
	if not id then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return false end
	local track = s.tracks[move]
	if not track then
		local animation = Instance.new("Animation")
		animation.Name = "Riftbound_" .. move
		animation.AnimationId = id
		local success, loaded = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		animation:Destroy()
		if not success or not loaded then
			warn("[RIFTBOUND Animations] Could not load:",move,loaded)
			return false
		end
		track = loaded
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = move == "Block" or move == "SwordBlock"
			or move == "SwordIdle" or move == "SwordWalk" or move == "SwordRun"
		s.tracks[move] = track
	end
	clearTweens(s)
	-- Previous procedural C0s must not offset a genuine R15 animation.
	for motor, original in s.originals do
		if motor.Parent then motor.C0 = original end
	end
	for key, other in s.tracks do
		if key ~= move and other.IsPlaying then
			other:Stop(0.06)
		end
	end
	track:Play(0.06, 1, (Config.PlaybackSpeeds and Config.PlaybackSpeeds[move]) or 1)
	return true
end

function Motion.Play(character, effect, value)
	if not character or not character.Parent then return end
	local sword = character:GetAttribute("RiftSwordEquipped") == true
	if effect == "SwordGuardEnd" then
		local state = getState(character)
		state.sequence += 1
		if state.tracks.SwordBlock and state.tracks.SwordBlock.IsPlaying then
			state.tracks.SwordBlock:Stop(0.12)
		end
		-- Also restore original shoulder/waist C0 after procedural fallback
		-- guard poses, otherwise a missing animation can lock the avatar up.
		reset(character, state, 0.12)
		return
	end
	local move
	if effect == "Swing" then
		move = (sword and "SwordM1_" or "M1_")
			.. tostring(math.clamp(tonumber(value) or 1, 1, 4))
	elseif effect == "HeavySwing" then move = sword and "SwordHeavy" or "Heavy"
	elseif effect == "Dash" then
		if sword then
			move = "SwordDashAttack"
		elseif value == "Left" or value == "Right" or value == "Back" then
			move = "Dash" .. value
		else
			move = "Dash"
		end
	elseif effect == "Parry" then move = sword and "SwordParry" or "Parry"
	elseif effect == "Hit" or effect == "Stagger" then
		move = sword and "SwordParried" or "Hit"
	elseif effect == "GuardBreak" then move = sword and "SwordParried" or "GuardBreak"
	elseif effect == "SwordAbility" and sword then
		local mapping = {Z="SwordBlock",X="SwordDashAttack",
			C="SwordUplift",V="SwordSlam",G="SwordExecution"}
		move = mapping[value]
	elseif effect == "Block" then
		if value == false then
			local s = getState(character)
			s.sequence += 1
			if s.tracks.Block then s.tracks.Block:Stop(0.12) end
			if s.tracks.SwordBlock then s.tracks.SwordBlock:Stop(0.12) end
			reset(character, s, 0.12)
			return
		end
		move = sword and "SwordBlock" or "Block"
	end
	if not move then return end

	local s = getState(character)
	s.sequence += 1
	if not playAsset(character, s, move) then
		-- Don't drop movement/attack feedback if an imported animation is
		-- missing, invalid or not yet published. Legacy poses remain useful.
		local simpleMove = move
		if move:find("^SwordM1_") then simpleMove = "M1_" .. move:sub(-1)
		elseif move == "SwordHeavy" or move == "SwordExecution"
			or move == "SwordSlam" or move == "SwordUplift" then
			simpleMove = "Heavy"
		elseif move == "SwordBlock" then simpleMove = "Block"
		elseif move == "SwordDashAttack" then simpleMove = "Dash"
		elseif move == "SwordParried" then simpleMove = "Hit" end
		fallback(character, s, simpleMove, move == "Block" or move == "SwordBlock")
	end
end

-- Sword locomotion: cosmetic local-only blending; base controls, game stats
-- and default Animate remain unchanged for the original Specs. It runs only
-- after the animation module finished loading asynchronously (never blocks UI).
local LOCOMOTION = {SwordIdle=true,SwordWalk=true,SwordRun=true}
local bindings = setmetatable({}, {__mode="k"})

local function stopLocomotion(state)
	for name in LOCOMOTION do
		local track = state.tracks[name]
		if track and track.IsPlaying then track:Stop(0.12) end
	end
end

local function playLocomotion(char,state,name)
	local track=state.tracks[name]
	if not track then
		local id=resolveId(name)
		if not id then return end
		local hum=char:FindFirstChildOfClass("Humanoid")
		local animator=hum and hum:FindFirstChildOfClass("Animator")
		if not animator then return end
		local animation=Instance.new("Animation")
		animation.Name="Riftbound_"..name
		animation.AnimationId=id
		local ok,result=pcall(function()return animator:LoadAnimation(animation) end)
		animation:Destroy()
		if not ok or not result then
			warn("[RIFTBOUND Sword] Movement animation failed:",name,result)
			return
		end
		track=result
		track.Priority=Enum.AnimationPriority.Movement
		track.Looped=true
		state.tracks[name]=track
	end
	if track.IsPlaying then return end
	stopLocomotion(state)
	track:Play(0.13,1,1)
end

function Motion.BindLocalPlayer(player)
	if bindings[player] then return end
	bindings[player]=true
	task.spawn(function()
		local lastCharacter=nil
		while player.Parent do
			local character=player.Character
			if lastCharacter and lastCharacter~=character then
				stopLocomotion(getState(lastCharacter))
			end
			lastCharacter=character
			if character then
				local s=getState(character)
				local hum=character:FindFirstChildOfClass("Humanoid")
				local active=character:GetAttribute("RiftSwordEquipped")==true
					and hum and hum.Health>0
					and hum.FloorMaterial~=Enum.Material.Air
				if active then
					local attacking=false
					for key,track in s.tracks do
						if not LOCOMOTION[key] and track.IsPlaying then
							attacking=true
							break
						end
					end
					if attacking then
						stopLocomotion(s)
					else
						local name="SwordIdle"
						if hum.MoveDirection.Magnitude>0.15 then
							name=hum.WalkSpeed>18 and "SwordRun" or "SwordWalk"
						end
						playLocomotion(character,s,name)
					end
				else
					stopLocomotion(s)
				end
			end
			task.wait(0.2)
		end
		bindings[player]=nil
	end)
end

return Motion
