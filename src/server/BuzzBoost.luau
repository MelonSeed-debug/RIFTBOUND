--!strict
-- Ashley Simmons X: Buzz Boost, server-authoritative temporary damage resistance.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cfg = require(ReplicatedStorage.Riftbound.Shared.AshleySimmonsSpec).Abilities.X
local Buzz = {}
local readyAt = setmetatable({}, {__mode = "k"})
local tokens = setmetatable({}, {__mode = "k"})

function Buzz.Clear(character)
	if not character then return end
	tokens[character] = (tokens[character] or 0) + 1
	character:SetAttribute("BuzzBoostEnds", 0)
	character:SetAttribute("BuzzBoostResistance", 0)
end

function Buzz.Activate(player)
	if player:GetAttribute("EquippedSpec") ~= "AshleySimmons" then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	local now = workspace:GetServerTimeNow()
	if now < (readyAt[player] or 0) then return false end
	readyAt[player] = now + cfg.Cooldown
	Buzz.Clear(character)
	local token = tokens[character]
	character:SetAttribute("BuzzBoostEnds", now + cfg.Duration)
	character:SetAttribute("BuzzBoostResistance", cfg.DamageResistance)
	player:SetAttribute("BuzzBoostReadyAt", readyAt[player])
	task.delay(cfg.Duration, function()
		if character.Parent and tokens[character] == token then Buzz.Clear(character) end
	end)
	return true
end

function Buzz.ResetPlayer(player)
	readyAt[player] = nil
	player:SetAttribute("BuzzBoostReadyAt", 0)
end

return Buzz
