--!strict
-- Void Disciple cooldown indicators, visible only while Void Disciple is equipped.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spec = require(ReplicatedStorage.Riftbound.Shared.VoidDiscipleSpec)
local HUD = {}

function HUD.Init(player, gui)
	local rows = {}
	local order = {"Z", "X", "C", "V", "G"}
	for i, key in order do
		local ability = spec.Abilities[key]
		local label = Instance.new("TextLabel")
		label.Name = "Void" .. key .. "Cooldown"
		label.Size = UDim2.fromOffset(250, 31)
		label.Position = UDim2.new(0, 15, 1, -138 - (i - 1) * 38)
		label.BackgroundColor3 = Color3.fromRGB(31, 20, 58)
		label.BackgroundTransparency = 0.12
		label.TextColor3 = Color3.fromRGB(185, 146, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 15
		label.Text = key .. " " .. string.upper(ability.Name)
		label.Visible = false
		label.Parent = gui
		rows[key] = label
	end

	local mark = Instance.new("TextLabel")
	mark.Name = "VoidPassiveHint"
	mark.Size = UDim2.fromOffset(245, 34)
	mark.Position = UDim2.new(0, 15, 1, -100)
	mark.BackgroundColor3 = Color3.fromRGB(46, 23, 74)
	mark.BackgroundTransparency = 0.1
	mark.TextColor3 = Color3.fromRGB(231, 196, 255)
	mark.Font = Enum.Font.GothamBold
	mark.TextSize = 14
	mark.Text = "PASSIVE: VOID MARK (3 HITS)"
	mark.Visible = false
	mark.Parent = gui

	task.spawn(function()
		while gui.Parent do
			local usingVoid = player:GetAttribute("EquippedSpec") == spec.Id
			local now = workspace:GetServerTimeNow()
			for key, label in rows do
				label.Visible = usingVoid
				if usingVoid then
					local remaining = math.max(0, math.ceil((player:GetAttribute("Void" .. key .. "ReadyAt") or 0) - now))
					local title = string.upper(spec.Abilities[key].Name)
					label.Text = key .. "  " .. title .. (remaining > 0 and ("  " .. remaining .. "s") or "  READY")
				end
			end
			mark.Visible = usingVoid
			task.wait(0.15)
		end
	end)
end

return HUD
