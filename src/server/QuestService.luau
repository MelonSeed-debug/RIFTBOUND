--!strict
-- RIFTBOUND quest requests. Client submits only an action and quest ID;
-- all eligibility, progress and rewards come from Progression on the server.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Progression = require(script.Parent.Progression)
local QuestService = {}
local throttle = setmetatable({}, {__mode = "k"})
local started = false

function QuestService.Start()
	if started then return end
	local remotes = ReplicatedStorage:WaitForChild("Riftbound"):WaitForChild("Remotes")
	local request = remotes:WaitForChild("QuestRequest", 5)
	local fx = remotes:WaitForChild("QuestFX", 5)
	if not request or not fx then
		warn("[RIFTBOUND Quests] Quest remotes are missing; combat can continue.")
		return
	end
	started = true
	request.OnServerEvent:Connect(function(player, action, questId)
		if typeof(action) ~= "string" or #action > 20 then return end
		local now = os.clock()
		if now - (throttle[player] or -math.huge) < 0.25 then return end
		throttle[player] = now

		local success, message
		if action == "Accept" then
			success, message = Progression.AcceptQuest(player, questId)
		elseif action == "Claim" then
			success, message = Progression.ClaimQuest(player)
		elseif action == "Abandon" then
			success, message = Progression.AbandonQuest(player)
		else
			return
		end
		fx:FireClient(player, success == true, message or "Action unavailable.")
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		throttle[player] = nil
	end)
end

return QuestService
