--!strict
-- RIFTBOUND PvE progression: server-owned XP, levels 1-50 and Rift Coins.
-- Attempts DataStore persistence. If Studio API access is disabled, this remains
-- a session-only prototype and NEVER overwrites a previously saved profile.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local cfg = require(ReplicatedStorage.Riftbound.Shared.LevelConfig)
local questCfg = require(ReplicatedStorage.Riftbound.Shared.QuestConfig)
local worldConfig = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)
local registry = require(ReplicatedStorage.Riftbound.Shared.SpecRegistry)
local items = require(ReplicatedStorage.Riftbound.Shared.ItemConfig)
local masteryConfig = require(ReplicatedStorage.Riftbound.Shared.MasteryConfig)
local lootRng = Random.new()
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
	player:SetAttribute("ProgressLoadState", p.loadState or "Loading")
	player:SetAttribute("ProgressLoadNote", p.loadNote or "")
	player:SetAttribute("QuestActiveId", p.questActive)
	player:SetAttribute("QuestCount", p.questCount)
	local activeDefinition = questCfg.Quests[p.questActive]
	player:SetAttribute("QuestGoal", activeDefinition and activeDefinition.Count or 0)
	player:SetAttribute("QuestReadyToClaim", activeDefinition ~= nil and p.questCount >= activeDefinition.Count)
	for id in questCfg.Quests do
		player:SetAttribute("QuestCompleted_" .. id, p.questCompleted[id] == true)
	end
	player:SetAttribute("QuestPermit_RiftInitiate", p.questPermits.RiftInitiate == true)
	for id, spec in registry.Specs do
		player:SetAttribute("SpecUnlocked_" .. id, spec.StarterUnlocked == true or p.specUnlocks[id] == true)
		local total = p.mastery[id] or 0
		player:SetAttribute("SpecMastery_" .. id, total)
		player:SetAttribute("SpecMasteryLevel_" .. id, masteryConfig.LevelForXP(total))
	end
	player:SetAttribute("RiftInventoryJSON", HttpService:JSONEncode(p.inventory))
	player:SetAttribute("EquippedGear", p.equippedGear)
	player:SetAttribute("AbyssClears", p.abyssClears)
end

-- Inventory is capped by distinct stacks and per-stack quantity to keep saves small.
local function addItemToProfile(p, itemId, amount)
	if not items.Items[itemId] then return false end
	amount = cleanInteger(amount, 1, items.MaxStack, 1)
	local existing = p.inventory[itemId] or 0
	local size = 0
	for _ in p.inventory do size += 1 end
	if existing == 0 and size >= items.MaxDistinctItems then return false end
	if existing + amount > items.MaxStack then return false end
	p.inventory[itemId] = existing + amount
	p.revision += 1
	p.dirty = true
	return true
end

local function rollLoot(p, npcName)
	local earned = {}
	for _, drop in items.Loot[npcName] or {} do
		if lootRng:NextNumber() <= drop.Chance then
			local qty = drop.Amount or 1
			if addItemToProfile(p, drop.Item, qty) then
				table.insert(earned, {Item=drop.Item, Amount=qty})
			end
		end
	end
	return earned
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
	-- A slow GetAsync may return AFTER our watchdog started an unsaved
	-- session. Never import those late values or permit an accidental save.
	if profiles[player] ~= p or p.loadResolved then return end
	if success then
		local saved = typeof(result) == "table" and result or {}
		p.level = cleanInteger(saved.level, 1, cfg.MaxLevel, 1)
		p.xp = cleanInteger(saved.xp, 0, 1000000000, 0)
		p.coins = cleanInteger(saved.coins, 0, 1000000000, 0)
		p.kills = cleanInteger(saved.kills, 0, 1000000000, 0)
		local savedItems = typeof(saved.inventory) == "table" and saved.inventory or {}
		for itemId in items.Items do
			local amount = cleanInteger(savedItems[itemId], 0, items.MaxStack, 0)
			if amount > 0 then p.inventory[itemId] = amount end
		end
		local gear = typeof(saved.equippedGear) == "string" and saved.equippedGear or ""
		p.equippedGear = items.Items[gear] and items.Items[gear].Kind == "Gear"
			and (p.inventory[gear] or 0) > 0 and gear or ""
		local savedMastery = typeof(saved.masteryXP) == "table" and saved.masteryXP or nil
		local legacy = typeof(saved.mastery) == "table" and saved.mastery or {}
		for id in registry.Specs do
			-- Preserve previous defeat-earned progression when migrating v4 saves.
			-- New mastery points accumulate only from valid ability casts.
			local xp = savedMastery and savedMastery[id] or ((legacy[id] or 0) * 2)
			p.mastery[id] = cleanInteger(xp, 0, masteryConfig.MaxMasteryXP, 0)
		end
		p.abyssClears = cleanInteger(saved.abyssClears, 0, 999999, 0)
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
		local savedSpecs = typeof(saved.specs) == "table" and saved.specs or {}
		local savedUnlocked = typeof(savedSpecs.unlocked) == "table" and savedSpecs.unlocked or {}
		for id, spec in registry.Specs do
			if not spec.StarterUnlocked then
				p.specUnlocks[id] = savedUnlocked[id] == true
					or (id == "VoidDisciple" and p.questCompleted.VoidTrial == true)
			end
		end
		local savedEquipped = typeof(savedSpecs.equipped) == "string" and savedSpecs.equipped or registry.Default
		local spec = registry.Specs[savedEquipped]
		if spec and spec.Ready and (spec.StarterUnlocked or p.specUnlocks[savedEquipped])
			and (not spec.RequiredLevel or p.level >= spec.RequiredLevel)
			and (not spec.RequiredPermit or p.questPermits[spec.RequiredPermit] == true) then
			p.equippedSpec = savedEquipped
		else
			p.equippedSpec = registry.Default
		end
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
		p.loadState = "Saved"
		p.loadNote = "Save data connected."
		player:SetAttribute("EquippedSpec", p.equippedSpec)
	else
		p.canSave = false
		p.loadState = "Session"
		p.loadNote = "DataStore read failed. This session will not overwrite saved data."
		warn("[RIFTBOUND Progression] DataStore read failed; session progress only for", player.Name, result)
	end
	p.pendingXP, p.pendingCoins, p.pendingKills = 0, 0, 0
	p.loadResolved = true
	p.loaded = true
	publish(player, p)
end

function Progression.Initialize(player)
	if profiles[player] then return end
	local p = {
		level = 1, xp = 0, coins = 0, kills = 0,
		loaded = false, canSave = false, dirty = false,
		loadResolved = false, loadState = "Loading",
		loadNote = "Connecting to saved progress...",
		pendingXP = 0, pendingCoins = 0, pendingKills = 0,
		questActive = "", questCount = 0, questCompleted = {}, questPermits = {},
		specUnlocks = {}, equippedSpec = registry.Default,
		inventory = {}, equippedGear = "", mastery = {}, abyssClears = 0,
		revision = 0, saving = false,
	}
	profiles[player] = p
	-- Only the server may signal completed exploration objectives. The
	-- client cannot claim a region discovery by firing a RemoteEvent.
	player:GetAttributeChangedSignal("RiftZone"):Connect(function()
		local region = player:GetAttribute("RiftZone")
		if typeof(region) == "string" then
			Progression.AdvanceObjective(player, "Enter:" .. region)
		end
	end)
	publish(player, p)

	-- Never leave the entire interface at "LOADING" if DataStore calls stall.
	-- We err on the side of preserving saved data: the fallback is playable,
	-- session-only, and CANNOT save over the player's existing profile.
	local function startUnsaved(reason)
		if profiles[player] ~= p or p.loadResolved then return end
		p.loadResolved = true
		p.canSave = false
		p.loaded = true
		p.loadState = "Session"
		p.loadNote = reason
		p.pendingXP, p.pendingCoins, p.pendingKills = 0, 0, 0
		warn("[RIFTBOUND Progression] Unsaved session for", player.Name, reason)
		publish(player, p)
	end

	task.spawn(function()
		local ok, err = xpcall(function()
			load(player, p)
		end, function(err) return tostring(err) end)
		if not ok then
			-- Errors during data migration or attribute publishing must not
			-- strand the quest HUD. Still NEVER allow writes after failure.
			startUnsaved("Profile initialization failed. Session data will not be saved.")
			warn("[RIFTBOUND Progression] Initialization error:", err)
		end
	end)

	task.delay(18, function()
		startUnsaved("Save service took too long. Playing unsaved; previous data is safe.")
	end)
end

function Progression.AwardNPCDefeat(player, npcName)
	local p = profiles[player]
	local reward = cfg.Rewards[npcName]
	if not p or not reward or not player.Parent then return false end
	local xp, coins = reward.XP, reward.Coins
	local levelsGained = applyReward(p, xp, coins, 1)
	if p.loaded then
		local loot = rollLoot(p, npcName)
		if #loot > 0 then
			local drop = loot[1]
			local info = items.Items[drop.Item]
			player:SetAttribute("LastLoot", "+" .. drop.Amount .. " " .. info.Name)
			player:SetAttribute("LastLootSerial", (player:GetAttribute("LastLootSerial") or 0) + 1)
		end
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
	-- Flat-field prototype: repetitive open-world enemy contracts have been
	-- temporarily retired. Previously saved quests are retained, not wiped.
	if worldConfig.PracticeMode and definition.Category ~= "Exploration" then
		return false, "Legacy story and grind contracts are paused. Explore the overworld."
	end
	if p.questActive ~= "" then return false, "Finish or abandon your active quest first." end
	if p.level < definition.RequiredLevel then return false, "Reach level " .. definition.RequiredLevel .. " first." end
	if definition.PrerequisiteQuest and not p.questCompleted[definition.PrerequisiteQuest] then
		local prior = questCfg.Quests[definition.PrerequisiteQuest]
		return false, "Complete " .. (prior and prior.Name or "the previous story quest") .. " first."
	end
	if definition.RequiredPermit and p.questPermits[definition.RequiredPermit] ~= true then
		return false, "Complete Rift Initiation first."
	end
	if not definition.Repeatable and p.questCompleted[questId] then return false, "Quest already completed." end
	p.questActive = questId
	p.questCount = 0
	-- Players may accept a discovery objective while already standing in
	-- that region. It is still authoritative: RiftZone is server-owned.
	if definition.Category == "Exploration"
		and definition.Target == "Enter:" .. tostring(player:GetAttribute("RiftZone")) then
		p.questCount = 1
	end
	p.revision += 1
	p.dirty = true
	publish(player, p)
	return true, "Quest accepted: " .. definition.Name
end

-- Only trusted server NPC prompt handlers may advance Talk:* objectives.
function Progression.AdvanceObjective(player, objective)
	local p = profiles[player]
	if not p or not p.loaded or typeof(objective) ~= "string" then return false end
	local definition = questCfg.Quests[p.questActive]
	if not definition or definition.Target ~= objective or p.questCount >= definition.Count then return false end
	p.questCount += 1
	p.revision += 1
	p.dirty = true
	publish(player,p)
	return true
end

-- Only called by the server after a skill actually casts; repeated
-- client requests during cooldown cannot farm mastery.
function Progression.AwardSkillUse(player, specId, key)
	local p=profiles[player]
	if not p or not p.loaded then return false end
	if typeof(specId)~="string" or typeof(key)~="string" then return false end
	if player:GetAttribute("EquippedSpec")~=specId or not registry.Specs[specId] then return false end
	local amount=masteryConfig.XPPerCast[key]
	if not amount then return false end
	local current=p.mastery[specId] or 0
	local nextValue=math.min(masteryConfig.MaxMasteryXP,current+amount)
	if nextValue<=current then return false end
	p.mastery[specId]=nextValue
	p.revision+=1
	p.dirty=true
	publish(player,p)
	if feedback then
		local level=masteryConfig.LevelForXP(nextValue)
		local previous=masteryConfig.LevelForXP(current)
		feedback:FireClient(player,"MasteryGain",specId,amount,nextValue,level,level>previous)
	end
	return true
end

function Progression.GrantItem(player, itemId, amount)
	local p = profiles[player]
	if not p or not p.loaded then return false end
	if not addItemToProfile(p,itemId,amount) then return false end
	publish(player,p)
	return true
end

function Progression.BuyItem(player, itemId, shopId)
	local p=profiles[player]
	local info=typeof(itemId)=="string" and items.Items[itemId]
	if not p or not p.loaded then return false,"Progress is loading." end
	if not info or info.Shop ~= shopId then return false,"Item not sold here." end
	if p.level < (info.MinLevel or 1) then return false,"Requires level "..info.MinLevel.."." end
	if p.coins < info.Price then return false,"Not enough Rift Coins." end
	if not addItemToProfile(p,itemId,1) then return false,"Inventory full or stack at 99." end
	p.coins -= info.Price
	publish(player,p)
	return true,"Bought "..info.Name.." for "..info.Price.." Rift Coins."
end

function Progression.SellItem(player,itemId)
	local p=profiles[player]
	local info=typeof(itemId)=="string" and items.Items[itemId]
	if not p or not p.loaded or not info then return false,"Unavailable." end
	if info.Kind ~= "Material" or not info.SellValue then return false,"Only materials can be sold." end
	if (p.inventory[itemId] or 0)<1 then return false,"You do not have that item." end
	p.inventory[itemId] -= 1
	if p.inventory[itemId]==0 then p.inventory[itemId]=nil end
	p.coins=math.min(1000000000,p.coins+info.SellValue)
	p.revision += 1
	p.dirty = true
	publish(player,p)
	return true,"Sold "..info.Name.." for "..info.SellValue.." Rift Coins."
end

function Progression.EquipGear(player,itemId)
	local p=profiles[player]
	if not p or not p.loaded then return false,"Progress is loading." end
	local info=typeof(itemId)=="string" and items.Items[itemId]
	if itemId ~= "" and (not info or info.Kind ~= "Gear" or (p.inventory[itemId] or 0)<1) then
		return false,"Gear is not owned."
	end
	if itemId ~= "" and p.level < (info.MinLevel or 1) then return false,"Level too low." end
	p.equippedGear=itemId
	p.revision += 1
	p.dirty = true
	publish(player,p)
	return true,itemId=="" and "Unequipped gear." or ("Equipped "..info.Name..".")
end

function Progression.UseItem(player,itemId)
	local p=profiles[player]
	local info=typeof(itemId)=="string" and items.Items[itemId]
	if not p or not p.loaded then return false,"Progress is loading." end
	if not info or info.Kind~="Consumable" or (p.inventory[itemId] or 0)<1 then
		return false,"Consumable not owned."
	end
	local char=player.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then return false,"You must be alive." end
	local now=Workspace:GetServerTimeNow()
	if (player:GetAttribute("LastConsumableAt") or 0)+2 > now then
		return false,"Consumables are on cooldown."
	end
	if info.Restore and hum.Health>=hum.MaxHealth then return false,"Health is already full." end
	p.inventory[itemId]-=1
	if p.inventory[itemId]==0 then p.inventory[itemId]=nil end
	player:SetAttribute("LastConsumableAt",now)
	if info.Restore then
		hum.Health=math.min(hum.MaxHealth,hum.Health+info.Restore)
	elseif info.Buff=="Damage" then
		char:SetAttribute("RiftDamageBuffMultiplier",info.BuffValue)
		char:SetAttribute("RiftDamageBuffEnds",now+info.Duration)
	elseif info.Buff=="Defense" then
		char:SetAttribute("RiftDefenseBuffMultiplier",info.BuffValue)
		char:SetAttribute("RiftDefenseBuffEnds",now+info.Duration)
	end
	p.revision += 1
	p.dirty = true
	publish(player,p)
	return true,"Used "..info.Name.."."
end

function Progression.RecordAbyssClear(player)
	local p=profiles[player]
	if not p or not p.loaded then return false end
	p.abyssClears=math.min(999999,p.abyssClears+1)
	p.revision += 1
	p.dirty = true
	publish(player,p)
	return true
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
	if definition.UnlockSpec and registry.Specs[definition.UnlockSpec] then
		p.specUnlocks[definition.UnlockSpec] = true
	end
	local gained = applyReward(p, definition.XP, definition.Coins, 0)
	publish(player, p)
	if feedback then
		feedback:FireClient(player, "QuestReward", definition.Name, definition.XP, definition.Coins, gained)
	end
	local suffix = definition.UnlockSpec and (" | UNLOCKED: " .. registry.Specs[definition.UnlockSpec].Name) or ""
	return true, "Quest completed: " .. definition.Name .. suffix
end

-- Spec selection tells the profile about validated changes so equipped Spec
-- persists alongside XP, coins, quest permits and earned Spec ownership.
function Progression.RecordEquip(player, specId)
	local p = profiles[player]
	if not p or not p.loaded then return end
	if specId ~= registry.Default and (not registry.Specs[specId]
		or not registry.Specs[specId].Ready or
		(not registry.Specs[specId].StarterUnlocked and p.specUnlocks[specId] ~= true)) then
		return
	end
	if p.equippedSpec == specId then return end
	p.equippedSpec = specId
	p.revision += 1
	p.dirty = true
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
		specs = {
			equipped = p.equippedSpec,
			unlocked = table.clone(p.specUnlocks),
		},
		inventory = table.clone(p.inventory),
		equippedGear = p.equippedGear,
		masteryXP = table.clone(p.mastery),
		abyssClears = p.abyssClears,
		version = 5,
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
