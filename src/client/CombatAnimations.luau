--!strict
-- Lightweight procedural combat poses (no uploaded animation IDs needed).
-- These are visual-only. Server is responsible for damage and timing.
local TweenService = game:GetService("TweenService")
local Motion = {}
local active = setmetatable({}, {__mode = "k"})

local function joints(character)
	local result = {}
	for _, obj in character:GetDescendants() do
		if obj:IsA("Motor6D") then
			if obj.Name == "RightShoulder" or obj.Name == "Right Shoulder" then result.right = obj
			elseif obj.Name == "LeftShoulder" or obj.Name == "Left Shoulder" then result.left = obj
			elseif obj.Name == "Waist" or obj.Name == "RootJoint" or obj.Name == "Root" then result.waist = obj end
		end
	end
	return result
end

local function state(character)
	if not active[character] then active[character] = {serial = 0, originals = {}, tweens = {}} end
	return active[character]
end

local function pose(character, angles, duration, hold)
	local st = state(character)
	st.serial += 1
	local serial = st.serial
	for _, tween in st.tweens do tween:Cancel() end
	st.tweens = {}
	local motors = joints(character)
	for key, motor in motors do
		if st.originals[motor] == nil then st.originals[motor] = motor.C0 end
		local offset = angles[key] or CFrame.new()
		local tween = TweenService:Create(motor, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			C0 = st.originals[motor] * offset,
		})
		table.insert(st.tweens, tween)
		tween:Play()
	end
	if not hold then
		task.delay(duration + 0.12, function()
			if st.serial ~= serial then return end
			Motion.Reset(character, 0.18)
		end)
	end
end

function Motion.Reset(character, duration)
	local st = active[character]
	if not st then return end
	st.serial += 1
	for _, tween in st.tweens do tween:Cancel() end
	st.tweens = {}
	for motor, original in st.originals do
		if motor.Parent then
			local tween = TweenService:Create(motor, TweenInfo.new(duration or 0.18), {C0 = original})
			table.insert(st.tweens, tween)
			tween:Play()
		end
	end
end

local rad = math.rad
local function rot(x, y, z)
	return CFrame.Angles(rad(x),rad(y),rad(z))
end

function Motion.Play(character, effect, value)
	if not character or not character.Parent then return end
	if effect == "Swing" then
		local stage = tonumber(value) or 1
		local rightHand = stage % 2 == 1
		pose(character, {
			right = rightHand and rot(-85, 5, 30) or rot(-18, 0, 12),
			left = rightHand and rot(-18, 0, -12) or rot(-85, -5, -30),
			waist = rot(0, rightHand and 16 or -16, 0),
		}, 0.10, false)
	elseif effect == "HeavySwing" then
		pose(character, {right = rot(-120, 15, 20), left = rot(-65, -20, -25), waist = rot(-8, -24, 0)}, 0.24, false)
	elseif effect == "Block" then
		if value then
			pose(character, {right = rot(-70, 0, 25), left = rot(-70, 0, -25)}, 0.13, true)
		else
			Motion.Reset(character)
		end
	elseif effect == "Dash" then
		pose(character, {right = rot(25, 0, 15), left = rot(25, 0, -15), waist = rot(17, 0, 0)}, 0.08, false)
	elseif effect == "Hit" or effect == "GuardBreak" then
		pose(character, {right = rot(30, 0, 10), left = rot(30, 0, -10), waist = rot(13, 0, 0)}, 0.08, false)
	end
end

return Motion
