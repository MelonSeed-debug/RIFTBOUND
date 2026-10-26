--!strict
-- RIFTBOUND right-edge move list inspired by the player's reference screenshot:
-- warm orange mastery heading, white move names, violet mastery requirements,
-- black/grey keycaps, and a slim XP bar. NO friends-boost section.
-- Display only: Z/X/C/V/G still go through existing server-authorized inputs.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local mastery = require(ReplicatedStorage.Riftbound.Shared.MasteryConfig)
local ashley = require(ReplicatedStorage.Riftbound.Shared.AshleySimmonsSpec)
local void = require(ReplicatedStorage.Riftbound.Shared.VoidDiscipleSpec)

local HUD = {}
local ORDER = {"Z", "X", "C", "V", "G"}
local SPEC_NAMES = {
	AshleySimmons = "ASHLEY SIMMONS",
	VoidDisciple = "VOID DISCIPLE",
}
local PALETTE = {
	orange = Color3.fromRGB(255, 146, 58),
	gold = Color3.fromRGB(243, 198, 105),
	white = Color3.fromRGB(250, 249, 252),
	violet = Color3.fromRGB(202, 102, 255),
	muted = Color3.fromRGB(186, 186, 202),
	green = Color3.fromRGB(139, 234, 175),
	red = Color3.fromRGB(241, 133, 147),
}

local function text(parent, name, words, pos, size, fontSize, tint, bold)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = pos
	label.Size = size
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = words
	label.TextSize = fontSize
	label.TextScaled = false
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextColor3 = tint
	label.TextStrokeColor3 = Color3.fromRGB(9, 7, 14)
	label.TextStrokeTransparency = 0.12
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end

local function frame(parent, name, pos, size, tint, alpha)
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = tint
	f.BackgroundTransparency = alpha or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function cooldownAttribute(spec, key)
	if spec == "VoidDisciple" then
		return "Void" .. key .. "ReadyAt"
	end
	if key == "Z" then return "PillShieldReadyAt" end
	if key == "X" then return "BuzzBoostReadyAt" end
	return "Ashley" .. key .. "ReadyAt"
end

local function moveName(spec, key)
	if spec == "VoidDisciple" then
		return void.Abilities[key].Name
	end
	if key == "G" then return ashley.Ultimate.Name end
	local ability = ashley.Abilities[key]
	return ability and ability.Name or key
end

local function rounded(parent, amount)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, amount)
	round.Parent = parent
end

function HUD.Init(player, gui)
	local sidebar = Instance.new("Frame")
	sidebar.Name = "RiftAbilitySidebar"
	sidebar.AnchorPoint = Vector2.new(1, 0.5)
	sidebar.Position = UDim2.new(1, -17, 0.59, 0)
	sidebar.Size = UDim2.fromOffset(332, 431)
	sidebar.BackgroundTransparency = 1
	sidebar.BorderSizePixel = 0
	sidebar.Visible = false
	sidebar.Parent = gui

	local scaler = Instance.new("UIScale")
	scaler.Name = "ResponsiveAbilityScale"
	scaler.Scale = 1
	scaler.Parent = sidebar

	local specName = text(sidebar, "SpecLabel", "",
		UDim2.fromOffset(0, 0), UDim2.fromOffset(328, 20),
		12, PALETTE.gold, true)
	local heading = text(sidebar, "MasteryHeading", "",
		UDim2.fromOffset(0, 19), UDim2.fromOffset(328, 31),
		23, PALETTE.orange, true)
	local explainer = text(sidebar, "SkillHeader", "SKILLS   /   KEYBINDS",
		UDim2.fromOffset(0, 54), UDim2.fromOffset(328, 17),
		11, PALETTE.muted, true)

	local rule = frame(sidebar, "TopRule", UDim2.fromOffset(36, 76),
		UDim2.fromOffset(292, 2), PALETTE.gold, 0.28)
	local rows = {}
	for index, key in ORDER do
		local y = 83 + (index - 1) * 58
		local backing = frame(sidebar, key .. "Row",
			UDim2.fromOffset(13, y), UDim2.fromOffset(319, 55),
			Color3.fromRGB(14, 12, 19), 0.52)
		rounded(backing, 7)

		local name = text(backing, "MoveName", key,
			UDim2.fromOffset(2, 1), UDim2.fromOffset(255, 22),
			17, PALETTE.white, true)
		local requirement = text(backing, "MasteryRequirement", "Mastery 0",
			UDim2.fromOffset(2, 23), UDim2.fromOffset(255, 17),
			14, PALETTE.violet, true)
		local state = text(backing, "MoveStatus", "READY",
			UDim2.fromOffset(2, 40), UDim2.fromOffset(255, 12),
			10, PALETTE.green, true)

		-- The reference's chunky, dark metallic keyboard-cap design.
		local cap = frame(backing, "Keycap", UDim2.fromOffset(264, 2),
			UDim2.fromOffset(51, 51), Color3.new(1, 1, 1), 0)
		rounded(cap, 7)
		local gradient = Instance.new("UIGradient")
		gradient.Name = "KeycapMetal"
		gradient.Rotation = 15
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 69, 75)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(28, 29, 34)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 10)),
		})
		gradient.Parent = cap
		local capOutline = Instance.new("UIStroke")
		capOutline.Thickness = 2.5
		capOutline.Color = Color3.fromRGB(5, 5, 6)
		capOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		capOutline.Parent = cap
		local keyText = text(cap, "Key", key,
			UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
			32, Color3.fromRGB(204, 199, 223), true)
		keyText.TextXAlignment = Enum.TextXAlignment.Center
		keyText.TextStrokeTransparency = 0.36
		rows[key] = {Name = name, Requirement = requirement, State = state, Key = keyText}
	end

	local progressTitle = text(sidebar, "XPProgressText", "",
		UDim2.fromOffset(0, 377), UDim2.fromOffset(328, 21),
		12, PALETTE.white, true)
	local track = frame(sidebar, "XPBar",
		UDim2.fromOffset(40, 409), UDim2.fromOffset(288, 11),
		Color3.fromRGB(31, 30, 35), 0.08)
	rounded(track, 6)
	local border = Instance.new("UIStroke")
	border.Thickness = 1.4
	border.Color = Color3.fromRGB(13, 12, 17)
	border.Parent = track
	local fill = frame(track, "XPFill",
		UDim2.fromOffset(0, 0), UDim2.fromScale(0, 1),
		PALETTE.gold, 0)
	rounded(fill, 6)
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.violet),
		ColorSequenceKeypoint.new(1, PALETTE.gold),
	})
	fillGradient.Parent = fill

	-- Hide the abilities when a large menu or dialogue is open, preventing
	-- background HUD from cluttering readable modal text.
	local modalNames = {
		"RiftMainMenu", "QuestJournal", "DecoInventory",
		"SpecSelection", "RiftboundWorldMap", "WorldGuide",
		"RiftStoryDialogue",
	}
	local function modalIsOpen()
		for _, name in modalNames do
			local child = gui:FindFirstChild(name)
			if child and child:IsA("GuiObject") and child.Visible then return true end
		end
		return false
	end

	local lastSpec = ""
	local function refresh()
		local spec = player:GetAttribute("EquippedSpec")
		local valid = spec == "AshleySimmons" or spec == "VoidDisciple"
		sidebar.Visible = valid and not modalIsOpen()
		if not valid then return end

		local total = math.clamp(player:GetAttribute("SpecMastery_" .. spec) or 0,
			0, mastery.MaxMasteryXP)
		local level, earned, needed = mastery.LevelDetails(total)
		specName.Text = SPEC_NAMES[spec] or spec
		heading.Text = "Mastery " .. level .. " (Max. " .. mastery.MaxLevel .. ")"
		progressTitle.Text = needed == 0 and "MAX MASTERY ACHIEVED"
			or (earned .. " / " .. needed .. " XP TO NEXT MASTERY")
		fill.Size = UDim2.fromScale(needed == 0 and 1 or math.clamp(earned / needed, 0, 1), 1)
		local now = Workspace:GetServerTimeNow()

		for _, key in ORDER do
			local row = rows[key]
			local required = mastery.SkillRequirements[key] or 0
			local unlocked = total >= required
			row.Name.Text = moveName(spec, key)
			row.Requirement.Text = "Mastery " .. required .. (unlocked and "  ✓" or "")
			row.Requirement.TextColor3 = unlocked and PALETTE.violet or Color3.fromRGB(173, 88, 202)
			row.Key.TextColor3 = unlocked and PALETTE.white or Color3.fromRGB(108, 105, 123)
			if not unlocked then
				row.State.Text = "LOCKED"
				row.State.TextColor3 = PALETTE.red
			else
				local cooldown = player:GetAttribute(cooldownAttribute(spec, key)) or 0
				local remaining = math.max(0, math.ceil(cooldown - now))
				row.State.Text = remaining > 0 and (remaining .. "s COOLDOWN") or "READY"
				row.State.TextColor3 = remaining > 0 and PALETTE.gold or PALETTE.green
			end
		end
	end

	-- Cooldowns count down in real time; profile and equip changes appear on
	-- the next tick without polling the server or sending any requests.
	task.spawn(function()
		while gui.Parent do
			refresh()
			task.wait(0.20)
		end
	end)
	refresh()
	print("[RIFTBOUND UI] Right-side skill list active. No Friends Boost.")
end

return HUD
