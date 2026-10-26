--!strict
-- Prototype Spec selection UI: M on keyboard, or SPECS button on any device.
-- The server validates every equip request. This module never grants ownership.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Registry = require(ReplicatedStorage.Riftbound.Shared.SpecRegistry)

local Menu = {}
local colors = {
	background = Color3.fromRGB(17, 19, 34),
	panel = Color3.fromRGB(30, 30, 54),
	outline = Color3.fromRGB(104, 88, 151),
	accent = Color3.fromRGB(226, 116, 247),
	secondary = Color3.fromRGB(132, 209, 255),
	text = Color3.fromRGB(249, 241, 255),
	muted = Color3.fromRGB(174, 170, 191),
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
	round(item, 9)
	item.Parent = parent
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
	panel.Size = UDim2.new(0.94, 0, 0, 335)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(380, 335)
	sizeLimit.MinSize = Vector2.new(290, 335)
	sizeLimit.Parent = panel
	panel.BackgroundColor3 = colors.background
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	round(panel, 14)
	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = colors.outline
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

	local ashley = Registry.Specs.AshleySimmons
	label(specCard, ashley.Name, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(13, 9), 19, colors.text, true)
	label(specCard, ashley.Subtitle, UDim2.new(1, -24, 0, 21), UDim2.fromOffset(13, 37), 13, colors.accent, false)
	label(specCard, ashley.Description, UDim2.new(1, -24, 0, 34), UDim2.fromOffset(13, 61), 12, colors.muted, false)
	local equip = button(specCard, "EQUIP ASHLEY", UDim2.new(1, -26, 0, 32), UDim2.fromOffset(13, 100), colors.accent, 15)
	equip.TextColor3 = colors.background

	local unarmed = button(panel, "GO UNARMED", UDim2.new(1, -44, 0, 37), UDim2.fromOffset(22, 233), colors.panel, 15)
	local status = label(panel, "", UDim2.new(1, -44, 0, 24), UDim2.fromOffset(22, 277), 13, colors.secondary, true)
	local footer = label(panel, "Other Specs and unlock quests are coming later.", UDim2.new(1, -44, 0, 20), UDim2.fromOffset(22, 305), 11, colors.muted, false)

	local function refresh()
		local equipped = player:GetAttribute("EquippedSpec") or Registry.Default
		local unlocked = player:GetAttribute("SpecUnlocked_AshleySimmons") == true
		status.Text = equipped == "AshleySimmons" and "EQUIPPED: ASHLEY SIMMONS" or "EQUIPPED: UNARMED"
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
	end

	equip.Activated:Connect(function()
		if equip.Active and request then
			request:FireServer("EquipSpec", "AshleySimmons")
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
	refresh()
	panel.Visible = (player:GetAttribute("EquippedSpec") or Registry.Default) == Registry.Default
end

return Menu
