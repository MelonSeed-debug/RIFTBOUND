--!strict
-- RIFTBOUND quest journal: J key or QUESTS button.
-- UI reflects server attributes; it never awards XP, currency or quest permits.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Quests = require(ReplicatedStorage.Riftbound.Shared.QuestConfig)

local QuestBoard = {}
local colors = {
	bg = Color3.fromRGB(18, 19, 36),
	card = Color3.fromRGB(33, 31, 55),
	accent = Color3.fromRGB(153, 117, 250),
	text = Color3.fromRGB(250, 246, 255),
	muted = Color3.fromRGB(188, 181, 206),
	gold = Color3.fromRGB(255, 223, 126),
}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function text(parent, words, size, pos, fontSize, color, bold)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = pos
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.Text = words
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextSize = fontSize
	label.Parent = parent
	return label
end

local function button(parent, words, size, pos, color)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.Text = words
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = colors.text
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	corner(b, 8)
	b.Parent = parent
	return b
end

function QuestBoard.Init(player, gui)
	local remotes = ReplicatedStorage.Riftbound.Remotes
	-- Render the journal even when remotes have not synced yet.
	-- Buttons resolve QuestRequest at click time; a missing event gets an
	-- actionable status instead of hiding the whole journal and J binding.
	local function sendRequest(action, questId)
		local remote = remotes:FindFirstChild("QuestRequest")
		if not remote or not remote:IsA("RemoteEvent") then
			warn("[RIFTBOUND Quests] QuestRequest missing in ReplicatedStorage.Riftbound.Remotes. Re-sync default.project.json and restart Rojo.")
			return false
		end
		remote:FireServer(action, questId)
		return true
	end

	local toggle = button(gui, "QUESTS [J]", UDim2.fromOffset(142, 39), UDim2.new(1, -155, 0, 64), colors.card)
	toggle.Name = "OpenQuestLog"
	local panel = Instance.new("Frame")
	panel.Name = "QuestJournal"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.49)
	panel.Size = UDim2.new(0.94, 0, 0, 470)
	panel.BackgroundColor3 = colors.bg
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 12)
	local sizing = Instance.new("UISizeConstraint")
	sizing.MaxSize = Vector2.new(430, 470)
	sizing.MinSize = Vector2.new(300, 470)
	sizing.Parent = panel
	local edge = Instance.new("UIStroke")
	edge.Thickness = 2
	edge.Color = colors.accent
	edge.Parent = panel

	text(panel, "RIFTBOUND / QUESTS", UDim2.new(1, -74, 0, 34), UDim2.fromOffset(16, 10), 21, colors.text, true)
	local close = button(panel, "X", UDim2.fromOffset(34, 32), UDim2.new(1,-47,0,10), colors.card)
	close.Activated:Connect(function() panel.Visible = false end)

	local activeLine = text(panel, "No active quest", UDim2.new(1,-32,0,32), UDim2.fromOffset(16,46), 14, colors.gold, true)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "QuestList"
	scroll.Size = UDim2.new(1, -28, 1, -135)
	scroll.Position = UDim2.fromOffset(14, 83)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.fromOffset(0, #Quests.Order * 116)
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = panel

	local message
	local cards = {}
	for index, id in Quests.Order do
		local q = Quests.Quests[id]
		local card = Instance.new("Frame")
		card.Name = "Quest_" .. id
		card.Size = UDim2.new(1, -9, 0, 109)
		card.Position = UDim2.fromOffset(0, (index - 1) * 116)
		card.BackgroundColor3 = colors.card
		card.BorderSizePixel = 0
		card.Parent = scroll
		corner(card, 9)
		local name = text(card, q.Name, UDim2.new(1, -125, 0, 22), UDim2.fromOffset(10, 6), 16, colors.text, true)
		local description = text(card, q.Description, UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 28), 12, colors.muted, false)
		local rewardLine = text(card, "Lv " .. q.RequiredLevel .. "  |  +" .. q.XP .. " XP  +" .. q.Coins .. " coins",
			UDim2.new(1,-120,0,21), UDim2.fromOffset(10, 77), 12, colors.gold, true)
		local action = button(card, "ACCEPT", UDim2.fromOffset(105, 33), UDim2.new(1,-115,0,68), colors.accent)
		local note = text(card, "", UDim2.fromOffset(112, 25), UDim2.new(1,-122,0,6), 11, colors.muted, false)
		cards[id] = {button=action, note=note, quest=q}
		action.Activated:Connect(function()
			local active = player:GetAttribute("QuestActiveId") or ""
			if active == id then
				local count = player:GetAttribute("QuestCount") or 0
				if count >= q.Count then
					if not sendRequest("Claim") then message.Text = "QUEST OFFLINE: sync default.project.json" end
				else
					if not sendRequest("Abandon") then message.Text = "QUEST OFFLINE: sync default.project.json" end
				end
			elseif active == "" then
				if not sendRequest("Accept", id) then message.Text = "QUEST OFFLINE: sync default.project.json" end
			end
		end)
	end

	message = text(panel, "Complete quests for XP and Rift Coins.", UDim2.new(1,-32,0,33),
		UDim2.new(0,16,1,-43), 13, colors.muted, false)

	local tracker = button(gui, "NO ACTIVE QUEST  |  [J]", UDim2.fromOffset(225, 48),
		UDim2.new(1,-237,0,112), colors.bg)
	tracker.Name = "QuestTracker"
	tracker.TextSize = 12
	tracker.TextWrapped = true
	tracker.Activated:Connect(function() panel.Visible = not panel.Visible end)

	local function refresh()
		local level = player:GetAttribute("Level") or 1
		local loaded = player:GetAttribute("ProgressLoaded") == true
		local active = player:GetAttribute("QuestActiveId") or ""
		local count = player:GetAttribute("QuestCount") or 0
		local activeQuest = Quests.Quests[active]
		if not loaded then
			activeLine.Text = "Loading your saved quest progress..."
			tracker.Text = "QUESTS LOADING  |  [J]"
		elseif activeQuest then
			activeLine.Text = activeQuest.Name .. "  " .. math.min(count,activeQuest.Count) .. "/" .. activeQuest.Count
			tracker.Text = activeQuest.Name .. "  " .. math.min(count,activeQuest.Count)
				.. "/" .. activeQuest.Count .. (count >= activeQuest.Count and " - CLAIM!" or "")
		else
			activeLine.Text = "No active quest - choose one below"
			tracker.Text = "QUESTS AVAILABLE  |  [J]"
		end
		for id, row in cards do
			local done = player:GetAttribute("QuestCompleted_" .. id) == true
			local q = row.quest
			if not loaded then
				row.button.Text = "LOADING"
			elseif done and not q.Repeatable then
				row.button.Text = "DONE"
			elseif id == active then
				row.button.Text = count >= q.Count and "CLAIM" or "ABANDON"
			elseif active ~= "" then
				row.button.Text = "BUSY"
			elseif level < q.RequiredLevel then
				row.button.Text = "LOCKED"
			else
				row.button.Text = "ACCEPT"
			end
			row.button.Active = loaded and (id == active or
				(active == "" and level >= q.RequiredLevel and (not done or q.Repeatable)))
			row.button.BackgroundColor3 = row.button.Active and colors.accent or Color3.fromRGB(84, 79, 109)
			row.note.Text = (done and not q.Repeatable) and "COMPLETE" or
				(level < q.RequiredLevel and ("Requires Lv " .. q.RequiredLevel) or
				(q.Repeatable and "REPEATABLE" or "ONE TIME"))
		end
	end

	for _, attribute in {"Level", "ProgressLoaded", "QuestActiveId", "QuestCount",
		"QuestCompleted_FirstSteps", "QuestCompleted_ShieldWall",
		"QuestCompleted_StreetPatrol", "QuestCompleted_RiftInitiation"} do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()
	local feedbackConnected = false
	local function connectFeedback(remote)
		if feedbackConnected or not remote or not remote:IsA("RemoteEvent") then return end
		feedbackConnected = true
		remote.OnClientEvent:Connect(function(success, words)
			message.Text = tostring(words)
			message.TextColor3 = success and Color3.fromRGB(136, 241, 194) or Color3.fromRGB(255, 154, 150)
			refresh()
		end)
	end
	connectFeedback(remotes:FindFirstChild("QuestFX"))
	remotes.ChildAdded:Connect(function(child)
		if child.Name == "QuestFX" then connectFeedback(child) end
	end)
	if not remotes:FindFirstChild("QuestRequest") then
		message.Text = "Quest service connecting... Check Rojo sync."
		warn("[RIFTBOUND Quests] Quest journal loaded, but QuestRequest is missing. Verify default.project.json and Rojo.")
	end
	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
		refresh()
	end)
	ContextActionService:BindAction("RiftQuestJournal", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			panel.Visible = not panel.Visible
			refresh()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.J, Enum.KeyCode.ButtonSelect)
	print("[RIFTBOUND Quests] Quest journal initialized. Press J to open.")
end

return QuestBoard
