--!strict
-- RIFTBOUND district tracker and world guide. Data comes from server owned attributes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local World = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)
local Deco = require(script.Parent.ArtDecoUI)

local HUD = {}
local colors = {
	bg = Deco.Ink,
	text = Deco.Paper,
	muted = Deco.Muted,
	safe = Deco.PaleGold,
}

local function round(parent, amount)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, amount)
	c.Parent = parent
end

local function makeLabel(parent, value, position, size, fontSize, tint, bold)
	local t = Instance.new("TextLabel")
	t.Position = position
	t.Size = size
	t.BackgroundTransparency = 1
	t.Text = value
	t.TextColor3 = tint
	t.TextSize = fontSize
	t.TextWrapped = true
	t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = parent
	return t
end

function HUD.Init(player, gui)
	if not game:GetService("RunService"):IsStudio() and World.StudioOnly then return end

	local header = Instance.new("TextButton")
	header.Name = "WorldGuideToggle"
	header.AnchorPoint = Vector2.new(0.5, 0)
	header.Position = UDim2.new(0.5, 0, 0, 17)
	header.Size = UDim2.new(0.67, 0, 0, 65)
	header.Text = ""
	header.AutoButtonColor = true
	header.BorderSizePixel = 0
	header.BackgroundColor3 = colors.bg
	header.Parent = gui
	round(header, 5)
	Deco.Button(header)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(330, 65)
	sizeLimit.MinSize = Vector2.new(200, 65)
	sizeLimit.Parent = header

	local outline = Instance.new("UIStroke")
	outline.Color = colors.safe
	outline.Thickness = 1.4
	outline.Parent = header

	local zoneName = makeLabel(header, "RIFTBOUND / WORLD", UDim2.fromOffset(12,5),
		UDim2.new(1,-24,0,30), 16, colors.text, true)
	zoneName.TextXAlignment = Enum.TextXAlignment.Center
	local zoneInfo = makeLabel(header, "WORLD GUIDE [B]", UDim2.fromOffset(12,34),
		UDim2.new(1,-24,0,24), 12, colors.muted, false)
	zoneInfo.TextXAlignment = Enum.TextXAlignment.Center

	local panel = Instance.new("Frame")
	panel.Name = "WorldGuide"
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	panel.Position = UDim2.fromScale(0.5,0.48)
	panel.Size = UDim2.new(0.9,0,0,330)
	panel.BackgroundColor3 = colors.bg
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	round(panel,5)
	Deco.Panel(panel)
	local panelLimit = Instance.new("UISizeConstraint")
	panelLimit.MaxSize = Vector2.new(390,330)
	panelLimit.MinSize = Vector2.new(290,330)
	panelLimit.Parent = panel
	local edge = Instance.new("UIStroke")
	edge.Color = Deco.Gold
	edge.Thickness = 1.5
	edge.Parent = panel

	makeLabel(panel,"RIFTBOUND / WORLD GUIDE", UDim2.fromOffset(15,10),
		UDim2.new(1,-55,0,30),20,colors.text,true)
	local close = Instance.new("TextButton")
	close.Position = UDim2.new(1,-45,0,9)
	close.Size = UDim2.fromOffset(33,31)
	close.Text = "X"
	close.TextColor3 = colors.text
	close.Font = Enum.Font.GothamBold
	close.BackgroundColor3 = Color3.fromRGB(53,46,79)
	close.Parent = panel
	round(close,4)
	Deco.Button(close)
	close.Activated:Connect(function() panel.Visible = false end)

	local entries = {
		{Name=World.Hub.Name, Range="SAFE HUB", Description="Spawn, quests, training, travel and future shops", Tint=colors.safe},
	}
	for _, zone in World.Zones do
		table.insert(entries, {
			Name=zone.Name,
			Range="LEVEL "..zone.MinLevel.."-"..zone.MaxLevel,
			Description=zone.Subtitle,
			Tint=zone.Color,
		})
	end
	for i, entry in entries do
		local y = 49 + (i-1)*61
		local group = Instance.new("Frame")
		group.Size = UDim2.new(1,-26,0,55)
		group.Position = UDim2.fromOffset(13,y)
		group.BackgroundColor3 = Color3.fromRGB(39,42,63)
		group.BorderSizePixel = 0
		group.Parent = panel
		round(group,8)
		makeLabel(group, entry.Name .. "  |  " .. entry.Range,
			UDim2.fromOffset(11,4),UDim2.new(1,-18,0,24),14,entry.Tint,true)
		makeLabel(group, entry.Description, UDim2.fromOffset(11,27),
			UDim2.new(1,-18,0,23),11,colors.muted,false)
	end
	makeLabel(panel,"Cross island bridges, press N for the map, or E at travel pads.",
		UDim2.fromOffset(15,301), UDim2.new(1,-25,0,23),11,colors.muted,false)

	local toast = makeLabel(gui,"",UDim2.new(0.5,-190,0,95),
		UDim2.fromOffset(380,40),16,colors.safe,true)
	toast.Name = "WorldNotification"
	toast.TextXAlignment = Enum.TextXAlignment.Center
	toast.TextTransparency = 1
	toast.TextStrokeTransparency = 1
	local toastToken = 0

	local function refresh()
		local id = player:GetAttribute("RiftZone") or "Haven"
		if id == World.Hub.Id then
			zoneName.Text = World.Hub.Name .. " / SAFE"
			zoneInfo.Text = "SAFE HUB  •  [B] GUIDE  [N] MAP"
			outline.Color = colors.safe
			return
		end
		for _, zone in World.Zones do
			if id == zone.Id then
				zoneName.Text = zone.Name .. " / DANGER"
				zoneInfo.Text = "LEVEL " .. zone.MinLevel .. "-" .. zone.MaxLevel .. "  •  [B] GUIDE  [N] MAP"
				outline.Color = zone.Color
				return
			end
		end
		zoneName.Text = "ISLAND CAUSEWAY"
		zoneInfo.Text = "BRIDGE ROUTE  •  [B] GUIDE  [N] MAP"
		outline.Color = colors.muted
	end
	local function openGuide()
		panel.Visible = not panel.Visible
	end
	header.Activated:Connect(openGuide)
	ContextActionService:BindAction("RiftWorldGuide",function(_,state)
		if state == Enum.UserInputState.Begin then openGuide() end
		return Enum.ContextActionResult.Pass
	end,false,Enum.KeyCode.B)
	player:GetAttributeChangedSignal("RiftZone"):Connect(refresh)
	player:GetAttributeChangedSignal("RiftWorldMessageId"):Connect(function()
		toastToken += 1
		local token = toastToken
		toast.Text = player:GetAttribute("RiftWorldMessage") or ""
		toast.TextTransparency = 0
		toast.TextStrokeTransparency = 0.4
		task.delay(3.1,function()
			if token ~= toastToken or not toast.Parent then return end
			TweenService:Create(toast,TweenInfo.new(0.3),{
				TextTransparency=1,
				TextStrokeTransparency=1,
			}):Play()
		end)
	end)
	refresh()
end

return HUD
