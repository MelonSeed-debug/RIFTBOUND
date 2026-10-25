--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local rift = ReplicatedStorage:WaitForChild("Riftbound")
local request = rift.Remotes.CombatRequest
local fx = rift.Remotes.CombatFX
local specFX = rift.Remotes.SpecFX
local Motion = require(script:WaitForChild("CombatAnimations"))

local function attack(_, inputState)
	if inputState == Enum.UserInputState.Begin then request:FireServer("M1") end
	return Enum.ContextActionResult.Sink
end
local function heavy(_, inputState)
	if inputState == Enum.UserInputState.Begin then request:FireServer("Heavy") end
	return Enum.ContextActionResult.Sink
end
local function block(_, inputState)
	if inputState == Enum.UserInputState.Begin then request:FireServer("Block",true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then request:FireServer("Block",false) end
	return Enum.ContextActionResult.Sink
end
local function dash(_, inputState)
	if inputState == Enum.UserInputState.Begin then request:FireServer("Dash") end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("RiftAttack",attack,true,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2)
ContextActionService:BindAction("RiftHeavy",heavy,true,Enum.KeyCode.R,Enum.KeyCode.ButtonX)
ContextActionService:BindAction("RiftBlock",block,true,Enum.KeyCode.F,Enum.KeyCode.ButtonL2)
ContextActionService:BindAction("RiftDash",dash,true,Enum.KeyCode.Q,Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("RiftAttack","Attack")
ContextActionService:SetTitle("RiftHeavy","Heavy")
ContextActionService:SetTitle("RiftBlock","Block")
ContextActionService:SetTitle("RiftDash","Dash")
ContextActionService:SetPosition("RiftAttack",UDim2.new(1,-100,1,-130))
ContextActionService:SetPosition("RiftHeavy",UDim2.new(1,-250,1,-230))
ContextActionService:SetPosition("RiftBlock",UDim2.new(1,-200,1,-135))
ContextActionService:SetPosition("RiftDash",UDim2.new(1,-145,1,-225))

local gui = Instance.new("ScreenGui")
gui.Name = "RIFTBOUND Controls"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(390,45)
label.Position = UDim2.new(0,15,1,-60)
label.BackgroundTransparency = 0.4
label.BackgroundColor3 = Color3.fromRGB(12,12,22)
label.TextColor3 = Color3.fromRGB(255,255,255)
label.Font = Enum.Font.GothamBold
label.TextSize = 13
label.Text = "RIFTBOUND  |  M1 Attack  •  R Heavy  •  F Parry/Block  •  Q Dash"
label.Parent = gui


-- Phase 1 combat feedback. Visuals are cosmetic and never determine damage.
local comboLabel = Instance.new("TextLabel")
comboLabel.Name = "ComboFeedback"
comboLabel.Size = UDim2.fromOffset(180, 55)
comboLabel.Position = UDim2.new(0.5, -90, 0.72, 0)
comboLabel.BackgroundTransparency = 1
comboLabel.TextColor3 = Color3.fromRGB(255, 226, 120)
comboLabel.TextStrokeTransparency = 0.3
comboLabel.Font = Enum.Font.GothamBlack
comboLabel.TextSize = 30
comboLabel.TextTransparency = 1
comboLabel.Parent = gui
local comboToken = 0

local function showCombo(index)
	comboToken += 1
	local token = comboToken
	comboLabel.Text = index == 5 and "HEAVY!" or (tostring(index) .. " / 4 COMBO")
	comboLabel.TextTransparency = 0
	comboLabel.Size = UDim2.fromOffset(205, 62)
	TweenService:Create(comboLabel, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
		Size = UDim2.fromOffset(180, 55),
	}):Play()
	task.delay(0.75, function()
		if token == comboToken then
			TweenService:Create(comboLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		end
	end)
end

local function floatingText(root, words, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CombatPopup"
	billboard.Size = UDim2.fromOffset(140, 65)
	billboard.StudsOffsetWorldSpace = Vector3.new(math.random(-5, 5)/10, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = root
	billboard.Parent = root
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = words
	text.TextColor3 = color
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.TextStrokeTransparency = 0.25
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.Parent = billboard
	TweenService:Create(billboard, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {
		StudsOffsetWorldSpace = billboard.StudsOffsetWorldSpace + Vector3.new(0, 1.6, 0),
	}):Play()
	TweenService:Create(text, TweenInfo.new(0.5), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(billboard, 0.6)
end

local function shockwave(root, color, size)
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.CanTouch = false
	sphere.CanQuery = false
	sphere.Material = Enum.Material.Neon
	sphere.Color = color
	sphere.Transparency = 0.45
	sphere.Size = Vector3.new(0.5, 0.5, 0.5)
	sphere.CFrame = root.CFrame
	sphere.Parent = workspace
	TweenService:Create(sphere, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		Size = Vector3.new(size, size, size),
		Transparency = 1,
	}):Play()
	Debris:AddItem(sphere, 0.3)
end

fx.OnClientEvent:Connect(function(effect, character, combo, damage)
	if not character or not character:IsA("Model") then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	Motion.Play(character, effect, combo)
	if effect == "Swing" or effect == "HeavySwing" then
		if character == Players.LocalPlayer.Character then
			showCombo(effect == "HeavySwing" and 5 or combo)
		end
		return
	end
	if effect == "Dash" then
		shockwave(root, Color3.fromRGB(110, 190, 255), 4)
		return
	end
	if effect == "Hit" and typeof(damage) == "number" then
		floatingText(root, "-" .. tostring(damage), Color3.fromRGB(255, 115, 115))
		shockwave(root, Color3.fromRGB(255, 200, 120), combo == 5 and 6 or 3)
	elseif effect == "BlockedHit" then
		floatingText(root, "BLOCKED", Color3.fromRGB(125, 190, 255))
	elseif effect == "Parry" then
		floatingText(root, "PARRY!", Color3.fromRGB(255, 220, 90))
	elseif effect == "GuardBreak" then
		floatingText(root, "GUARD BREAK!", Color3.fromRGB(255, 150, 65))
	end
	if effect == "Hit" or effect == "BlockedHit" or effect == "Parry" or effect == "GuardBreak" then
		local highlight = Instance.new("Highlight")
		highlight.FillColor = effect == "Hit" and Color3.fromRGB(255,55,55) or (effect == "Parry" and Color3.fromRGB(255,220,70) or (effect == "GuardBreak" and Color3.fromRGB(255,130,30) or Color3.fromRGB(75,150,255)))
		highlight.FillTransparency = 0.45
		highlight.OutlineTransparency = 1
		highlight.Parent = character
		TweenService:Create(highlight,TweenInfo.new(0.22),{FillTransparency=1}):Play()
		game:GetService("Debris"):AddItem(highlight,0.25)
	end
end)


-- Ashley passive prototype feedback.
local pillCounter = Instance.new("TextLabel")
pillCounter.Name = "PillAmmo"
pillCounter.Size = UDim2.fromOffset(225, 35)
pillCounter.Position = UDim2.new(0, 15, 1, -100)
pillCounter.BackgroundColor3 = Color3.fromRGB(35, 22, 54)
pillCounter.BackgroundTransparency = 0.15
pillCounter.TextColor3 = Color3.fromRGB(255, 190, 245)
pillCounter.Font = Enum.Font.GothamBold
pillCounter.TextSize = 17
pillCounter.Parent = gui

local player = Players.LocalPlayer
local function refreshPills()
	if player:GetAttribute("EquippedSpec") == "AshleySimmons" then
		pillCounter.Visible = true
		pillCounter.Text = "Pill Passive  " .. tostring(player:GetAttribute("PillAmmo") or 0) .. "/10"
	else
		pillCounter.Visible = false
	end
end
player:GetAttributeChangedSignal("PillAmmo"):Connect(refreshPills)
player:GetAttributeChangedSignal("EquippedSpec"):Connect(refreshPills)
refreshPills()

specFX.OnClientEvent:Connect(function(effect, target, status)
	if effect ~= "PillImpact" or not target or not target:IsA("Model") then return end
	local root = target:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local colors = {
		ChillPill = Color3.fromRGB(100, 220, 255),
		Euphoria = Color3.fromRGB(245, 100, 235),
		AdrenalineRush = Color3.fromRGB(255, 160, 60),
		AntiInflammatory = Color3.fromRGB(100, 255, 150),
		MoodStabilizer = Color3.fromRGB(195, 155, 255),
	}
	local color = colors[status] or Color3.new(1,1,1)
	floatingText(root, status, color)
	shockwave(root, color, 4.5)
end)
