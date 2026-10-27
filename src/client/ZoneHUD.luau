--!strict
-- RIFTBOUND world-region banner. Server RiftZone attributes are display only:
-- this client module never grants quest completion or accepts damage decisions.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local World = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)

local UI = {}

local function label(parent, name, text, fontSize, color, y)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Text = text
	item.Size = UDim2.new(1,-24,0,fontSize+7)
	item.Position = UDim2.fromOffset(12,y)
	item.BackgroundTransparency = 1
	item.TextColor3 = color
	item.Font = Enum.Font.GothamBold
	item.TextSize = fontSize
	item.TextXAlignment = Enum.TextXAlignment.Center
	item.TextStrokeTransparency = 0.55
	item.Parent = parent
	return item
end

function UI.Init(player, gui)
	if gui:FindFirstChild("RiftZoneBanner") then return end
	local banner = Instance.new("Frame")
	banner.Name = "RiftZoneBanner"
	banner.AnchorPoint = Vector2.new(0.5,0)
	banner.Position = UDim2.new(0.5,0,0,64)
	banner.Size = UDim2.fromOffset(338,62)
	banner.BackgroundColor3 = Color3.fromRGB(26,26,32)
	banner.BackgroundTransparency = 0.25
	banner.BorderSizePixel = 0
	banner.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,9)
	corner.Parent = banner
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.35
	stroke.Color = Color3.fromRGB(220,179,117)
	stroke.Transparency = 0.15
	stroke.Parent = banner

	local title = label(banner,"Region","HAVEN",19,
		Color3.fromRGB(255,224,168),6)
	local hint = label(banner,"ZoneStatus","SAFE HAVEN  /  WORLD ORIGIN",11,
		Color3.fromRGB(224,224,231),35)

	local scaler = Instance.new("UIScale")
	scaler.Name = "ZoneBannerScale"
	scaler.Parent = banner
	local function layout()
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local size = camera.ViewportSize
		scaler.Scale = math.clamp(math.min(size.X/850,size.Y/710),0.7,1)
		banner.Position = UDim2.new(0.5,0,0,size.Y<520 and 48 or 64)
	end
	local activeCamera
	local cameraConnection
	local function hookCamera()
		if cameraConnection then cameraConnection:Disconnect() end
		activeCamera = Workspace.CurrentCamera
		if activeCamera then
			cameraConnection = activeCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
		end
		layout()
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)
	hookCamera()

	local serial = 0
	local function refresh()
		local zoneId = player:GetAttribute("RiftZone") or "Haven"
		local zone = zoneId == World.Hub.Id and World.Hub or World.ZoneById(zoneId)
		local safe = zoneId == World.Hub.Id
		title.Text = zone and zone.Name or "WILDERNESS"
		title.TextColor3 = safe and Color3.fromRGB(251,224,167)
			or (zone and zone.Accent or Color3.fromRGB(226,226,226))
		hint.Text = safe and "SAFE HAVEN  /  REST & PREPARE"
			or (zone and ("RECOMMENDED LEVEL "..tostring(zone.RecommendedLevel).."+")
				or "OPEN OVERWORLD  /  EXPLORE")
		serial += 1
		local token = serial
		banner.BackgroundTransparency = 0.17
		stroke.Transparency = 0.08
		title.TextTransparency = 0
		hint.TextTransparency = 0
		task.delay(4.5,function()
			if token ~= serial or not banner.Parent then return end
			TweenService:Create(banner,TweenInfo.new(0.65),
				{BackgroundTransparency=0.72}):Play()
			TweenService:Create(stroke,TweenInfo.new(0.65),
				{Transparency=0.72}):Play()
			TweenService:Create(hint,TweenInfo.new(0.65),
				{TextTransparency=0.5}):Play()
			TweenService:Create(title,TweenInfo.new(0.65),
				{TextTransparency=0.18}):Play()
		end)
	end
	player:GetAttributeChangedSignal("RiftZone"):Connect(refresh)
	refresh()
end

return UI
