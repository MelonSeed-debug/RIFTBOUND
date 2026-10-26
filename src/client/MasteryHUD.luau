--!strict
-- Lightweight combat notifications only. Mastery totals and skill requirements
-- now live in the right-edge SpecAbilityHUD and the existing Vitals HUD.
-- This removes the duplicated top-left mastery card and its overlap.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Mastery = require(ReplicatedStorage.Riftbound.Shared.MasteryConfig)
local Deco = require(script.Parent.ArtDecoUI)

local HUD = {}
function HUD.Init(player, gui)
	local notice = Deco.Text(gui, "CombatNotice", "",
		UDim2.new(0.5, -205, 0.81, 0),
		UDim2.fromOffset(410, 39), 16, true)
	notice.TextXAlignment = Enum.TextXAlignment.Center
	notice.TextColor3 = Deco.PaleGold
	notice.TextStrokeColor3 = Color3.new(0, 0, 0)
	notice.TextStrokeTransparency = 1
	notice.TextTransparency = 1

	local serial = 0
	local function toast(message, color)
		serial += 1
		local current = serial
		notice.Text = message
		notice.TextColor3 = color or Deco.PaleGold
		notice.TextTransparency = 0
		notice.TextStrokeTransparency = 0.2
		task.delay(2.5, function()
			if current ~= serial or not notice.Parent then return end
			TweenService:Create(notice, TweenInfo.new(0.3), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
		end)
	end

	player:GetAttributeChangedSignal("LastLootSerial"):Connect(function()
		local drop = player:GetAttribute("LastLoot")
		if typeof(drop) == "string" then
			toast("LOOT  •  " .. drop, Deco.PaleGold)
		end
	end)

	local remotes = ReplicatedStorage.Riftbound.Remotes
	local masteryFX = remotes:FindFirstChild("MasteryFX")
	if masteryFX then
		masteryFX.OnClientEvent:Connect(function(key, required, owned)
			toast(tostring(key) .. " LOCKED  •  " .. tostring(owned)
				.. "/" .. tostring(required) .. " MASTERY XP", Deco.Gold)
		end)
	end

	local progressFX = remotes:FindFirstChild("ProgressionFX")
	if progressFX then
		progressFX.OnClientEvent:Connect(function(action, spec, amount, total, level, leveledUp)
			if action ~= "MasteryGain" then return end
			-- Skill unlock notifications take precedence when XP crosses a gate;
			-- mastery-level increases are shown otherwise.
			for _, key in Mastery.SkillOrder do
				local needed = Mastery.SkillRequirements[key]
				if needed > 0 and total >= needed and total - amount < needed then
					toast(key .. " SKILL UNLOCKED!", Deco.Green)
					return
				end
			end
			if leveledUp then
				toast("MASTERY LEVEL " .. tostring(level) .. "!", Deco.PaleGold)
			end
		end)
	end

	local dungeon = remotes:FindFirstChild("DungeonFX")
	if dungeon then
		dungeon.OnClientEvent:Connect(function(action, message)
			if action == "Warning" then
				toast(tostring(message), Deco.Red)
			elseif action == "Victory" then
				toast(tostring(message), Deco.PaleGold)
			else
				toast(tostring(message), Deco.Paper)
			end
		end)
	end
end

return HUD
