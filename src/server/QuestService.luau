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
	-- Handle old local Rojo project files that do not yet define these
	-- events. New installs still define them in default.project.json.
	local function ensureEvent(name)
		local existing = remotes:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then return existing end
		if existing then
			warn("[RIFTBOUND Quests] " .. name .. " exists but is not a RemoteEvent.")
			return nil
		end
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
		warn("[RIFTBOUND Quests] Created missing " .. name .. " RemoteEvent at runtime. Update default.project.json for persistent Rojo sync.")
		return event
	end
	local request = ensureEvent("QuestRequest")
	local fx = ensureEvent("QuestFX")
	if not request or not fx then return end
	started = true
	print("[RIFTBOUND Quests] Quest service ready.")
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
