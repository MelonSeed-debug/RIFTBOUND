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
local function resolveId(move)
	local id = Config.Moves[move]
	if typeof(id) == "string" and id ~= "" then
		if id:match("^%d+$") then return "rbxassetid://" .. id end
		return id
	end
	if Config.StudioPreview ~= true or not RunService:IsStudio() then
		return nil
	end
	local library = ReplicatedStorage:FindFirstChild(Config.PreviewFolder)
	if not library then
		if not lastMissingWarning then
			lastMissingWarning = true
			warn("[RIFTBOUND Animations] Import RIFTBOUND_Combat_Animation_Clips.rbxm " ..
				"into ReplicatedStorage for local animation preview. " ..
				"Using procedural motion until then.")
		end
		return nil
	end
	local sequence = library:FindFirstChild(move)
	if not sequence or not sequence:IsA("KeyframeSequence") then return nil end
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
		track.Looped = move == "Block"
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
	local move
	if effect == "Swing" then
		move = "M1_" .. tostring(math.clamp(tonumber(value) or 1, 1, 4))
	elseif effect == "HeavySwing" then move = "Heavy"
	elseif effect == "Dash" then
		if value == "Left" or value == "Right" or value == "Back" then
			move = "Dash" .. value
		else
			move = "Dash"
		end
	elseif effect == "Parry" then move = "Parry"
	elseif effect == "Hit" then move = "Hit"
	elseif effect == "GuardBreak" then move = "GuardBreak"
	elseif effect == "Block" then
		if value == false then
			local s = getState(character)
			s.sequence += 1
			if s.tracks.Block then s.tracks.Block:Stop(0.12) end
			reset(character, s, 0.12)
			return
		end
		move = "Block"
	else return end

	local s = getState(character)
	s.sequence += 1
	if not playAsset(character, s, move) then fallback(character, s, move, move == "Block") end
end

return Motion
