--!strict
-- RIFTBOUND quest requests. Client submits only an action and quest ID;
-- all eligibility, progress and rewards come from Progression on the server.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Progression = require(script.Parent.Progression)
local World = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)
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

	-- Two physical interaction points: a quest giver at spawn and a
	-- trial altar near the Rift Sentinel. Both use server ProximityPrompts.
	local world = game:GetService("Workspace")
	local spawn = world:FindFirstChildWhichIsA("SpawnLocation", true)
	local center = spawn and spawn.Position or Vector3.new(0, 0, 0)
	local folder = world:FindFirstChild("RIFTBOUND Quest Hub")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RIFTBOUND Quest Hub"
		folder.Parent = world
	end
	local function makeStation(name, text, offset, color, callback)
		local existing = folder:FindFirstChild(name)
		if existing then return end
		local pos = center + offset
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {folder}
		local floor = world:Raycast(pos + Vector3.new(0, 70, 0), Vector3.new(0,-200,0), params)
		local y = floor and floor.Position.Y or pos.Y
		local part = Instance.new("Part")
		part.Name = name
		part.Size = Vector3.new(3, 5, 3)
		part.Position = Vector3.new(pos.X, y + 2.5, pos.Z)
		part.Color = color
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = true
		part.Parent = folder
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "StationName"
		billboard.Size = UDim2.fromOffset(260, 54)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.4, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = part
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1,1,1)
		label.TextStrokeTransparency = 0.2
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Text = name
		label.Parent = billboard
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Talk"
		prompt.ObjectText = name
		prompt.ActionText = text
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
		prompt.Triggered:Connect(callback)
	end
	makeStation("Rift Archivist", "Browse Quests", World.QuestStations.Archivist,
		Color3.fromRGB(109, 188, 242), function(player)
			fx:FireClient(player, "OpenJournal", "")
		end)
	makeStation("Void Trial Altar", "Start Void Trial", World.QuestStations.VoidTrial,
		Color3.fromRGB(171, 79, 239), function(player)
			local success, msg = Progression.AcceptQuest(player, "VoidTrial")
			fx:FireClient(player, "OpenJournal", "")
			fx:FireClient(player, success == true, msg)
		end)
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
