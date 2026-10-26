--!strict
-- RIFTBOUND PvE progression: server-owned XP, levels 1-50 and Rift Coins.
-- Attempts DataStore persistence. If Studio API access is disabled, this remains
-- a session-only prototype and NEVER overwrites a previously saved profile.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cfg = require(ReplicatedStorage.Riftbound.Shared.LevelConfig)
local questCfg = require(ReplicatedStorage.Riftbound.Shared.QuestConfig)
local feedback = ReplicatedStorage.Riftbound.Remotes:FindFirstChild("ProgressionFX")
local Progression = {}
local profiles = {}
local started = false

local storeOK, store = pcall(function()
	return DataStoreService:GetDataStore("RIFTBOUND_Progression_v1")
end)
if not storeOK then
	warn("[RIFTBOUND Progression] DataStore unavailable; using session-only progress:", store)
	store = nil
end

local function cleanInteger(value, minimum, maximum, default)
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return default
	end
	return math.clamp(math.floor(value), minimum, maximum)
end

local function publish(player, p)
	if not player.Parent then return end
	player:SetAttribute("Level", p.level)
	player:SetAttribute("XP", p.xp)
	player:SetAttribute("XPToNext", cfg.XPToNext(p.level))
	player:SetAttribute("RiftCoins", p.coins)
	player:SetAttribute("NPCKills", p.kills)
	player:SetAttribute("LevelCap", cfg.MaxLevel)
	player:SetAttribute("ProgressLoaded", p.loaded)
	player:SetAttribute("ProgressSavingEnabled", p.canSave)
	player:SetAttribute("QuestActiveId", p.questActive)
	player:SetAttribute("QuestCount", p.questCount)
	local activeDefinition = questCfg.Quests[p.questActive]
	player:SetAttribute("QuestGoal", activeDefinition and activeDefinition.Count or 0)
	player:SetAttribute("QuestReadyToClaim", activeDefinition ~= nil and p.questCount >= activeDefinition.Count)
	for id in questCfg.Quests do
		player:SetAttribute("QuestCompleted_" .. id, p.questCompleted[id] == true)
	end
	player:SetAttribute("QuestPermit_RiftInitiate", p.questPermits.RiftInitiate == true)
end

local function addXP(p, amount)
	amount = cleanInteger(amount, 0, 1000000, 0)
	if p.level >= cfg.MaxLevel then p.xp = 0 return 0 end
	local oldLevel = p.level
	p.xp += amount
	while p.level < cfg.MaxLevel do
		local nextXP = cfg.XPToNext(p.level)
		if p.xp < nextXP then break end
		p.xp -= nextXP
		p.level += 1
	end
	if p.level >= cfg.MaxLevel then p.xp = 0 end
	return p.level - oldLevel
end

local function applyReward(p, xp, coins, kills)
	local levelUps = addXP(p, xp)
	p.coins = math.clamp(p.coins + coins, 0, 1000000000)
	p.kills = math.clamp(p.kills + kills, 0, 1000000000)
	p.revision += 1
	p.dirty = true
	return levelUps
end

local function load(player, p)
	local key = "Player_" .. tostring(player.UserId)
	local success, result
	if store then
		success, result = pcall(function() return store:GetAsync(key) end)
	else
		success, result = false, "DataStore could not be created"
	end
	if profiles[player] ~= p then return end
	if success then
		local saved = typeof(result) == "table" and result or {}
		p.level = cleanInteger(saved.level, 1, cfg.MaxLevel, 1)
		p.xp = cleanInteger(saved.xp, 0, 1000000000, 0)
		p.coins = cleanInteger(saved.coins, 0, 1000000000, 0)
		p.kills = cleanInteger(saved.kills, 0, 1000000000, 0)
		local quests = typeof(saved.quests) == "table" and saved.quests or {}
		local requestedActive = typeof(quests.active) == "string" and quests.active or ""
		p.questActive = questCfg.Quests[requestedActive] and requestedActive or ""
		p.questCount = cleanInteger(quests.count, 0, 1000000, 0)
		local savedCompletions = typeof(quests.completed) == "table" and quests.completed or {}
		for id, definition in questCfg.Quests do
			p.questCompleted[id] = not definition.Repeatable and savedCompletions[id] == true or false
		end
		local permits = typeof(quests.permits) == "table" and quests.permits or {}
		p.questPermits.RiftInitiate = permits.RiftInitiate == true or p.questCompleted.RiftInitiation == true
		local activeDefinition = questCfg.Quests[p.questActive]
		if not activeDefinition or (not activeDefinition.Repeatable and p.questCompleted[p.questActive]) then
			p.questActive, p.questCount = "", 0
		else
			p.questCount = math.min(p.questCount, activeDefinition.Count)
		end
		if p.level >= cfg.MaxLevel then
			p.xp = 0
		else
			p.xp = math.min(p.xp, cfg.XPToNext(p.level) - 1)
		end
		-- A player might defeat an NPC while GetAsync is still running.
		-- Reapply those rewards instead of overwriting them on load.
		if p.pendingXP > 0 or p.pendingCoins > 0 or p.pendingKills > 0 then
			applyReward(p, p.pendingXP, p.pendingCoins, p.pendingKills)
		end
		p.canSave = true
	else
		p.canSave = false
		warn("[RIFTBOUND Progression] DataStore read failed; session progress only for", player.Name, result)
	end
	p.pendingXP, p.pendingCoins, p.pendingKills = 0, 0, 0
	p.loaded = true
	publish(player, p)
end

function Progression.Initialize(player)
	if profiles[player] then return end
	local p = {
		level = 1, xp = 0, coins = 0, kills = 0,
		loaded = false, canSave = false, dirty = false,
		pendingXP = 0, pendingCoins = 0, pendingKills = 0,
		questActive = "", questCount = 0, questCompleted = {}, questPermits = {},
		revision = 0, saving = false,
	}
	profiles[player] = p
	publish(player, p)
	task.spawn(load, player, p)
end

function Progression.AwardNPCDefeat(player, npcName)
	local p = profiles[player]
	local reward = cfg.Rewards[npcName]
	if not p or not reward or not player.Parent then return false end
	local xp, coins = reward.XP, reward.Coins
	local levelsGained = applyReward(p, xp, coins, 1)
	if p.loaded then
		local activeDefinition = questCfg.Quests[p.questActive]
		if activeDefinition and p.questCount < activeDefinition.Count
			and (activeDefinition.Target == "Any" or activeDefinition.Target == npcName) then
			p.questCount += 1
			p.revision += 1
			p.dirty = true
		end
	end
	if not p.loaded then
		p.pendingXP += xp
		p.pendingCoins += coins
		p.pendingKills += 1
	end
	publish(player, p)
	if feedback then
		feedback:FireClient(player, "NPCReward", npcName, xp, coins, levelsGained)
	end
	return true
end

-- Quest actions are server-validated, and the same DataStore snapshot persists
-- quest completion and the Rift Initiate permit alongside XP and currency.
function Progression.AcceptQuest(player, questId)
	local p = profiles[player]
	if not p or not p.loaded or typeof(questId) ~= "string" then return false, "Progress is still loading." end
	local definition = questCfg.Quests[questId]
	if not definition then return false, "Unknown quest." end
	if p.questActive ~= "" then return false, "Finish or abandon your active quest first." end
	if p.level < definition.RequiredLevel then return false, "Reach level " .. definition.RequiredLevel .. " first." end
	if not definition.Repeatable and p.questCompleted[questId] then return false, "Quest already completed." end
	p.questActive = questId
	p.questCount = 0
	p.revision += 1
	p.dirty = true
	publish(player, p)
	return true, "Quest accepted: " .. definition.Name
end

function Progression.AbandonQuest(player)
	local p = profiles[player]
	if not p or not p.loaded or p.questActive == "" then return false, "No active quest." end
	p.questActive = ""
	p.questCount = 0
	p.revision += 1
	p.dirty = true
	publish(player, p)
	return true, "Quest abandoned."
end

function Progression.ClaimQuest(player)
	local p = profiles[player]
	if not p or not p.loaded then return false, "Progress is still loading." end
	local id = p.questActive
	local definition = questCfg.Quests[id]
	if not definition or p.questCount < definition.Count then return false, "Quest objectives are incomplete." end
	if not definition.Repeatable and p.questCompleted[id] then return false, "Quest already claimed." end

	-- Clear first: a duplicate client request cannot collect twice.
	p.questActive, p.questCount = "", 0
	if not definition.Repeatable then p.questCompleted[id] = true end
	if definition.Permit == "RiftInitiate" then p.questPermits.RiftInitiate = true end
	local gained = applyReward(p, definition.XP, definition.Coins, 0)
	publish(player, p)
	if feedback then
		feedback:FireClient(player, "QuestReward", definition.Name, definition.XP, definition.Coins, gained)
	end
	return true, "Quest completed: " .. definition.Name
end

function Progression.Save(player)
	local p = profiles[player]
	if not p or not p.loaded or not p.canSave or not p.dirty or not store then return end
	if p.saving then
		local start = os.clock()
		while p.saving and os.clock() - start < 8 do task.wait(0.1) end
		if p.saving or not p.dirty then return end
	end
	p.saving = true
	local revision = p.revision
	local snapshot = {
		level = p.level,
		xp = p.xp,
		coins = p.coins,
		kills = p.kills,
		quests = {
			active = p.questActive,
			count = p.questCount,
			completed = table.clone(p.questCompleted),
			permits = table.clone(p.questPermits),
		},
		version = 2,
	}
	local success, err = pcall(function()
		store:UpdateAsync("Player_" .. tostring(player.UserId), function()
			return snapshot
		end)
	end)
	if success then
		p.dirty = p.revision ~= revision
	else
		warn("[RIFTBOUND Progression] Save failed for", player.Name, err)
	end
	p.saving = false
end

function Progression.Start()
	if started then return end
	started = true
	Players.PlayerAdded:Connect(Progression.Initialize)
	for _, player in Players:GetPlayers() do Progression.Initialize(player) end
	Players.PlayerRemoving:Connect(function(player)
		Progression.Save(player)
		profiles[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(90)
			for _, player in Players:GetPlayers() do
				local p = profiles[player]
				if p and p.dirty and p.canSave then task.spawn(Progression.Save, player) end
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				Progression.Save(player)
				pending -= 1
			end)
		end
		local start = os.clock()
		while pending > 0 and os.clock() - start < 22 do task.wait(0.1) end
	end)
end

return Progression
