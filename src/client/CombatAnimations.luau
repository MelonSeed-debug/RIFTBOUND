--!strict
-- Unified R15 combat motion: the same named moves for every player.
-- Uploaded animation IDs take priority; procedural poses are a temporary fallback.
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Riftbound"):WaitForChild("Shared"):WaitForChild("AnimationConfig"))
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

local function playAsset(character, s, move)
	local id = Config.Moves[move]
	if typeof(id) ~= "string" or id == "" then return false end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then return false end
	local track = s.tracks[move]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local success, loaded = pcall(function() return animator:LoadAnimation(animation) end)
		animation:Destroy()
		if not success then warn("RIFTBOUND animation could not load:",move,loaded) return false end
		track = loaded
		track.Priority = Enum.AnimationPriority.Action
		s.tracks[move] = track
	end
	for key, other in s.tracks do
		if key ~= move and other.IsPlaying then other:Stop(0.08) end
	end
	track:Play(0.08)
	return true
end

function Motion.Play(character, effect, value)
	if not character or not character.Parent then return end
	local move
	if effect == "Swing" then
		move = "M1_" .. tostring(math.clamp(tonumber(value) or 1, 1, 4))
	elseif effect == "HeavySwing" then move = "Heavy"
	elseif effect == "Dash" then move = "Dash"
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
