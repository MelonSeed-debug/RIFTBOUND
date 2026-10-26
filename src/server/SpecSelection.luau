--!strict
-- Authoritative Spec ownership, equipping and unequipping for the prototype.
-- No DataStore yet: starter Specs are granted on each join.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Registry = require(ReplicatedStorage.Riftbound.Shared.SpecRegistry)

local Selection = {}
local lastRequest = setmetatable({}, {__mode = "k"})

function Selection.Initialize(player)
	if player:GetAttribute("EquippedSpec") == nil then
		player:SetAttribute("EquippedSpec", Registry.Default)
	end
	for id, spec in Registry.Specs do
		if spec.StarterUnlocked then
			player:SetAttribute("SpecUnlocked_" .. id, true)
		end
	end
end

function Selection.Request(player, action, requestedId)
	if action ~= "EquipSpec" and action ~= "UnequipSpec" then return false end
	local current = player:GetAttribute("EquippedSpec") or Registry.Default
	local nextId = Registry.Default

	if action == "EquipSpec" then
		if typeof(requestedId) ~= "string" or #requestedId > 60 then return false end
		local definition = Registry.Specs[requestedId]
		if not definition or not definition.Ready then return false end
		if definition.RequiredLevel and (player:GetAttribute("Level") or 1) < definition.RequiredLevel then return false end
		if definition.RequiredPermit and player:GetAttribute("QuestPermit_" .. definition.RequiredPermit) ~= true then return false end
		if player:GetAttribute("SpecUnlocked_" .. requestedId) ~= true then return false end
		nextId = requestedId
	end

	if nextId == current then return false end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < 0.4 then return false end
	lastRequest[player] = now

	player:SetAttribute("EquippedSpec", nextId)
	return true, current, nextId
end

function Selection.Remove(player)
	lastRequest[player] = nil
end

return Selection
