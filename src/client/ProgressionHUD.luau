--!strict
-- RIFTBOUND progression HUD. All values are replicated server attributes.
-- Contains no level-up or currency-granting client logic.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local config = require(ReplicatedStorage.Riftbound.Shared.LevelConfig)
local HUD = {}

local function corner(object, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = object
end

local function text(parent, size, position, content, fontSize, color, bold)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextSize = fontSize
	label.Text = content
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end

function HUD.Init(player, gui)
	local panel = Instance.new("Frame")
	panel.Name = "ProgressionHUD"
	panel.Size = UDim2.fromOffset(320, 126)
	panel.Position = UDim2.fromOffset(15, 17)
	panel.BackgroundColor3 = Color3.fromRGB(21, 20, 41)
	panel.BackgroundTransparency = 0.06
	panel.BorderSizePixel = 0
	panel.Parent = gui
	corner(panel, 12)

	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(122, 86, 176)
	outline.Thickness = 1.4
	outline.Parent = panel

	local title = text(panel, UDim2.fromOffset(290, 27), UDim2.fromOffset(13, 9),
		"RIFTBOUND  /  PROGRESSION", 14, Color3.fromRGB(208, 159, 255), true)
	local levelText = text(panel, UDim2.fromOffset(290, 28), UDim2.fromOffset(13, 35),
		"LEVEL 1 / 50", 20, Color3.fromRGB(250, 246, 255), true)

	local track = Instance.new("Frame")
	track.Name = "XPTrack"
	track.Position = UDim2.fromOffset(13, 69)
	track.Size = UDim2.fromOffset(294, 11)
	track.BackgroundColor3 = Color3.fromRGB(64, 59, 89)
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = panel
	corner(track, 6)

	local fill = Instance.new("Frame")
	fill.Name = "XPFill"
	fill.BackgroundColor3 = Color3.fromRGB(220, 114, 240)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	corner(fill, 6)

	local progressText = text(panel, UDim2.fromOffset(288, 20), UDim2.fromOffset(13, 83),
		"0 / 75 XP", 13, Color3.fromRGB(198, 195, 215), false)
	local coinsText = text(panel, UDim2.fromOffset(175, 19), UDim2.fromOffset(13, 105),
		"Rift Coins: 0", 12, Color3.fromRGB(255, 222, 123), true)
	local killsText = text(panel, UDim2.fromOffset(120, 19), UDim2.fromOffset(190, 105),
		"Defeats: 0", 12, Color3.fromRGB(150, 227, 236), false)

	local rewardText = text(gui, UDim2.fromOffset(390, 42), UDim2.new(0.5, -195, 0, 160),
		"", 21, Color3.fromRGB(255, 232, 139), true)
	rewardText.Name = "NPCRewardToast"
	rewardText.TextXAlignment = Enum.TextXAlignment.Center
	rewardText.TextTransparency = 1
	rewardText.TextStrokeTransparency = 1
	rewardText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	local toastNumber = 0

	local function refresh()
		local level = math.clamp(player:GetAttribute("Level") or 1, 1, config.MaxLevel)
		local xp = math.max(0, player:GetAttribute("XP") or 0)
		local required = player:GetAttribute("XPToNext") or config.XPToNext(level)
		local coins = math.max(0, player:GetAttribute("RiftCoins") or 0)
		local kills = math.max(0, player:GetAttribute("NPCKills") or 0)
		local loaded = player:GetAttribute("ProgressLoaded") == true
		local saveEnabled = player:GetAttribute("ProgressSavingEnabled") == true

		levelText.Text = "LEVEL " .. level .. " / " .. config.MaxLevel
		coinsText.Text = "Rift Coins: " .. coins
		killsText.Text = "Defeats: " .. kills

		local atCap = level >= config.MaxLevel
		progressText.Text = atCap and "MAX LEVEL REACHED" or (xp .. " / " .. required .. " XP")
		if not loaded then
			title.Text = "RIFTBOUND  /  LOADING PROGRESS"
		elseif not saveEnabled then
			title.Text = "RIFTBOUND  /  SESSION ONLY"
		else
			title.Text = "RIFTBOUND  /  PROGRESSION"
		end
		local ratio = atCap and 1 or (required > 0 and math.clamp(xp / required, 0, 1) or 0)
		TweenService:Create(fill, TweenInfo.new(0.24, Enum.EasingStyle.Quad), {
			Size = UDim2.fromScale(ratio, 1),
		}):Play()
	end

	for _, attribute in {"Level", "XP", "XPToNext", "RiftCoins", "NPCKills", "ProgressLoaded", "ProgressSavingEnabled"} do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()

	local remote = ReplicatedStorage.Riftbound.Remotes:FindFirstChild("ProgressionFX")
	if remote then
		remote.OnClientEvent:Connect(function(effect, enemyName, xp, coins, levelsGained)
			if effect ~= "NPCReward" and effect ~= "QuestReward" then return end
			toastNumber += 1
			local token = toastNumber
			rewardText.Text = (effect == "QuestReward" and "QUEST COMPLETE!  " or "") .. "+" .. tostring(xp) .. " XP  •  +" .. tostring(coins)
				.. " Rift Coins" .. (levelsGained > 0 and ("  •  LEVEL UP +" .. tostring(levelsGained)) or "")
			rewardText.TextColor3 = levelsGained > 0
				and Color3.fromRGB(255, 226, 119)
				or Color3.fromRGB(213, 161, 245)
			rewardText.TextTransparency = 0
			rewardText.TextStrokeTransparency = 0.38
			task.delay(2.6, function()
				if token ~= toastNumber or not rewardText.Parent then return end
				TweenService:Create(rewardText, TweenInfo.new(0.3), {
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				}):Play()
			end)
		end)
	end
end

return HUD
