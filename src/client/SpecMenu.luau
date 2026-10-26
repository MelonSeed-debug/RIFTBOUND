--!strict
-- Prototype Spec selection UI: M on keyboard, or SPECS button on any device.
-- The server validates every equip request. This module never grants ownership.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Registry = require(ReplicatedStorage.Riftbound.Shared.SpecRegistry)
local Deco = require(script.Parent.ArtDecoUI)

local Menu = {}
local colors = {
	background = Deco.Ink,
	panel = Deco.Slate,
	outline = Deco.Bronze,
	accent = Deco.Gold,
	secondary = Deco.PaleGold,
	text = Deco.Paper,
	muted = Deco.Muted,
}

local function round(gui, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = gui
end

local function label(parent, text, size, position, fontSize, color, bold)
	local item = Instance.new("TextLabel")
	item.Size = size
	item.Position = position
	item.BackgroundTransparency = 1
	item.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	item.TextSize = fontSize
	item.TextColor3 = color
	item.TextWrapped = true
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Center
	item.Text = text
	item.Parent = parent
	return item
end

local function button(parent, text, size, position, fill, fontSize)
	local item = Instance.new("TextButton")
	item.Size = size
	item.Position = position
	item.BackgroundColor3 = fill
	item.AutoButtonColor = true
	item.Text = text
	item.TextWrapped = true
	item.Font = Enum.Font.GothamBold
	item.TextSize = fontSize or 16
	item.TextColor3 = colors.text
	round(item, 4)
	item.Parent = parent
	Deco.Button(item)
	return item
end

function Menu.Init(player, request, gui)
	local toggle = button(gui, "SPECS  [M]", UDim2.fromOffset(142, 40), UDim2.new(1, -155, 0, 16), colors.panel, 15)
	toggle.Name = "OpenSpecs"
	local outline = Instance.new("UIStroke")
	outline.Color = colors.outline
	outline.Thickness = 1
	outline.Parent = toggle

	local panel = Instance.new("Frame")
	panel.Name = "SpecSelection"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.47)
	panel.Size = UDim2.new(0.94, 0, 0, 408)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(380, 408)
	sizeLimit.MinSize = Vector2.new(290, 408)
	sizeLimit.Parent = panel
	panel.BackgroundColor3 = colors.background
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	round(panel, 6)
	Deco.Panel(panel)
	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = colors.accent
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	label(panel, "RIFTBOUND  /  SPECS", UDim2.fromOffset(275, 30), UDim2.fromOffset(22, 14), 23, colors.text, true)
	button(panel, "X", UDim2.fromOffset(36, 34), UDim2.new(1, -50, 0, 13), colors.panel, 18).Activated:Connect(function()
		panel.Visible = false
	end)

	local subtitle = label(panel, "Choose your fighting identity", UDim2.new(1, -44, 0, 25), UDim2.fromOffset(22, 45), 14, colors.muted, false)
	subtitle.TextWrapped = false

	local specCard = Instance.new("Frame")
	specCard.Size = UDim2.new(1, -44, 0, 139)
	specCard.Position = UDim2.fromOffset(22, 83)
	specCard.BackgroundColor3 = colors.panel
	specCard.BorderSizePixel = 0
	round(specCard, 11)
	specCard.Parent = panel
	Deco.Panel(specCard)

	local ashley = Registry.Specs.AshleySimmons
	label(specCard, ashley.Name, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(13, 9), 19, colors.text, true)
	label(specCard, ashley.Subtitle, UDim2.new(1, -24, 0, 21), UDim2.fromOffset(13, 37), 13, colors.accent, false)
	label(specCard, ashley.Description, UDim2.new(1, -24, 0, 34), UDim2.fromOffset(13, 61), 12, colors.muted, false)
	local equip = button(specCard, "EQUIP ASHLEY", UDim2.new(1, -26, 0, 32), UDim2.fromOffset(13, 100), colors.accent, 15)
	equip.TextColor3 = colors.background

	local upcoming = Instance.new("Frame")
	upcoming.Name = "FutureSpec"
	upcoming.Size = UDim2.new(1, -44, 0, 57)
	upcoming.Position = UDim2.fromOffset(22, 229)
	upcoming.BorderSizePixel = 0
	upcoming.BackgroundColor3 = colors.panel
	round(upcoming, 9)
	upcoming.Parent = panel
	Deco.Panel(upcoming)
	label(upcoming, "VOID DISCIPLE", UDim2.new(1,-20,0,26),
		UDim2.fromOffset(12,3), 14, colors.secondary, true)
	local voidEquip = button(upcoming, "LOCKED", UDim2.fromOffset(134, 27),
		UDim2.new(1,-144,0,15), colors.outline, 13)
	local permitHint = label(upcoming, "Level 10 + Rift Initiation + Void Trial",
		UDim2.new(1,-151,0,35), UDim2.fromOffset(12,23), 11, colors.muted, false)
	local unarmed = button(panel, "GO UNARMED", UDim2.new(1, -44, 0, 37), UDim2.fromOffset(22, 295), colors.panel, 15)
	local status = label(panel, "", UDim2.new(1, -44, 0, 24), UDim2.fromOffset(22, 340), 13, colors.secondary, true)
	local footer = label(panel, "Complete the Void Trial to earn your second Spec.", UDim2.new(1, -44, 0, 20), UDim2.fromOffset(22, 374), 11, colors.muted, false)

	local function refresh()
		local equipped = player:GetAttribute("EquippedSpec") or Registry.Default
		local unlocked = player:GetAttribute("SpecUnlocked_AshleySimmons") == true
		status.Text = equipped == "AshleySimmons" and "EQUIPPED: ASHLEY SIMMONS"
			or (equipped == "VoidDisciple" and "EQUIPPED: VOID DISCIPLE" or "EQUIPPED: UNARMED")
		if equipped == "AshleySimmons" then
			equip.Text = "CURRENTLY EQUIPPED"
			equip.BackgroundColor3 = colors.outline
			equip.Active = false
		elseif unlocked then
			equip.Text = "EQUIP ASHLEY"
			equip.BackgroundColor3 = colors.accent
			equip.Active = true
		else
			equip.Text = "LOCKED"
			equip.BackgroundColor3 = colors.outline
			equip.Active = false
		end
		unarmed.Text = equipped == Registry.Default and "CURRENTLY UNARMED" or "UNEQUIP / GO UNARMED"
		unarmed.Active = equipped ~= Registry.Default
		local level = player:GetAttribute("Level") or 1
		local hasPermit = player:GetAttribute("QuestPermit_RiftInitiate") == true
		local hasVoid = player:GetAttribute("SpecUnlocked_VoidDisciple") == true
		if equipped == "VoidDisciple" then
			voidEquip.Text = "EQUIPPED"
			voidEquip.Active = false
		elseif hasVoid and hasPermit and level >= 10 then
			voidEquip.Text = "EQUIP VOID"
			voidEquip.Active = true
		else
			voidEquip.Text = "LOCKED"
			voidEquip.Active = false
		end
		voidEquip.BackgroundColor3 = voidEquip.Active and colors.accent or colors.outline
		permitHint.Text = hasVoid and "TRIAL COMPLETE" or
			(level < 10 and "REQUIRES LEVEL 10" or
			(not hasPermit and "RIFT INITIATION FIRST" or "DEFEAT RIFT SENTINEL"))
	end

	equip.Activated:Connect(function()
		if equip.Active and request then
			request:FireServer("EquipSpec", "AshleySimmons")
		end
	end)
	voidEquip.Activated:Connect(function()
		if voidEquip.Active and request then
			request:FireServer("EquipSpec", "VoidDisciple")
		end
	end)
	unarmed.Activated:Connect(function()
		if unarmed.Active and request then
			request:FireServer("UnequipSpec")
		end
	end)
	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
		refresh()
	end)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.KeyCode ~= Enum.KeyCode.M then return end
		panel.Visible = not panel.Visible
		refresh()
	end)
	player:GetAttributeChangedSignal("EquippedSpec"):Connect(refresh)
	player:GetAttributeChangedSignal("SpecUnlocked_AshleySimmons"):Connect(refresh)
	player:GetAttributeChangedSignal("QuestPermit_RiftInitiate"):Connect(refresh)
	player:GetAttributeChangedSignal("SpecUnlocked_VoidDisciple"):Connect(refresh)
	player:GetAttributeChangedSignal("Level"):Connect(refresh)
	refresh()
	panel.Visible = (player:GetAttribute("EquippedSpec") or Registry.Default) == Registry.Default
end

return Menu
