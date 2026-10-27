--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- If Rojo accidentally syncs an empty/mismatched project, the first
-- WaitForChild below can yield indefinitely. Show a useful recovery banner
-- rather than presenting an apparently empty Roblox place with no clues.
local clientUIReady = false
local diagnosticGui
task.delay(8, function()
	if clientUIReady then return end
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	if not playerGui or clientUIReady then return end
	diagnosticGui = Instance.new("ScreenGui")
	diagnosticGui.Name = "RIFTBOUND Startup Diagnostic"
	diagnosticGui.ResetOnSpawn = false
	diagnosticGui.DisplayOrder = 150
	diagnosticGui.Parent = playerGui
	local warning = Instance.new("TextLabel")
	warning.Name = "RojoSyncWarning"
	warning.AnchorPoint = Vector2.new(0.5, 0)
	warning.Position = UDim2.new(0.5, 0, 0, 18)
	warning.Size = UDim2.new(0.9, 0, 0, 78)
	warning.BackgroundColor3 = Color3.fromRGB(41, 17, 22)
	warning.TextColor3 = Color3.fromRGB(255, 239, 207)
	warning.TextScaled = false
	warning.TextSize = 17
	warning.TextWrapped = true
	warning.Font = Enum.Font.GothamBold
	warning.Text = "RIFTBOUND CLIENT NOT READY\nCheck Rojo connection and ReplicatedStorage > Riftbound. Open View > Output for errors."
	warning.Parent = diagnosticGui
end)
local rift = ReplicatedStorage:WaitForChild("Riftbound")
local request = rift.Remotes.CombatRequest
local fx = rift.Remotes.CombatFX
local specFX = rift.Remotes:WaitForChild("SpecFX", 5)
local specRequest = rift.Remotes:WaitForChild("SpecRequest", 5)
local localPlayer = Players.LocalPlayer
local function fireSpec(ashleyAction, voidAction, swordAction)
	if not specRequest then return end
	local equipped = localPlayer:GetAttribute("EquippedSpec")
	if equipped == "AshleySimmons" then
		specRequest:FireServer(ashleyAction)
	elseif equipped == "VoidDisciple" then
		specRequest:FireServer(voidAction)
	elseif equipped == "GreatSword" and swordAction then
		specRequest:FireServer(swordAction)
	end
end
-- IMPORTANT: animation assets are OPTIONAL. Previously the startup blocked
-- here before creating ANY HUD if AnimationConfig was missing/not replicated.
-- Load asynchronously so even stalled/malformed animation packs never hide
-- the player's menu, vitals, skill list, inventory or combat controls.
local Motion = {Play = function() end}
task.spawn(function()
	local module = script:FindFirstChild("CombatAnimations")
		or script:WaitForChild("CombatAnimations", 5)
	if not module or not module:IsA("ModuleScript") then
		warn("[RIFTBOUND] CombatAnimations module is missing. Check Rojo sync.")
		return
	end
	local ok, loaded = pcall(require, module)
	if ok and type(loaded) == "table" and type(loaded.Play) == "function" then
		Motion = loaded
		if type(Motion.BindLocalPlayer) == "function" then
			local bindOK, bindErr = pcall(Motion.BindLocalPlayer, localPlayer)
			if not bindOK then warn("[RIFTBOUND] Sword movement animations unavailable:",bindErr) end
		end
		print("[RIFTBOUND] Animation layer ready; HUD startup remains independent.")
	else
		warn("[RIFTBOUND] CombatAnimations failed, HUD continues:", loaded)
	end
end)

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
ContextActionService:BindAction("RiftPillShield", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		fireSpec("PillShield", "VoidGuard", "SwordGuard")
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.Z, Enum.KeyCode.DPadUp)
ContextActionService:SetTitle("RiftPillShield", "Shield")
ContextActionService:SetPosition("RiftPillShield", UDim2.new(1,-300,1,-135))
ContextActionService:BindAction("RiftBuzzBoost", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		fireSpec("BuzzBoost", "VoidStep", "SwordLunge")
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.X, Enum.KeyCode.DPadLeft)
ContextActionService:SetTitle("RiftBuzzBoost", "Buzz")
ContextActionService:SetPosition("RiftBuzzBoost", UDim2.new(1,-310,1,-220))
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


-- Ashley's remaining abilities: C, V and G, including gamepad and touch.
local function bindSpecAction(name, action, voidAction, swordAction, key, gamepad, buttonTitle, touchPosition)
	ContextActionService:BindAction(name, function(_, state)
		if state == Enum.UserInputState.Begin then
			fireSpec(action, voidAction, swordAction)
		end
		return Enum.ContextActionResult.Sink
	end, true, key, gamepad)
	ContextActionService:SetTitle(name, buttonTitle)
	ContextActionService:SetPosition(name, touchPosition)
end
bindSpecAction("RiftRaveRush", "RaveRush", "VoidGrasp", "SwordUplift", Enum.KeyCode.C, Enum.KeyCode.DPadRight, "Rave", UDim2.new(1,-355,1,-315))
bindSpecAction("RiftTrippyToss", "TrippyToss", "VoidCleave", "SwordSlam", Enum.KeyCode.V, Enum.KeyCode.ButtonL1, "Trippy", UDim2.new(1,-230,1,-320))
bindSpecAction("RiftFrenzy", "Frenzy", "VoidNova", "SwordExecution", Enum.KeyCode.G, Enum.KeyCode.ButtonY, "Frenzy", UDim2.new(1,-110,1,-320))

-- Touch buttons show the names of whichever Spec is equipped.
local function updateTouchAbilityTitles()
	local current = localPlayer:GetAttribute("EquippedSpec")
	local isVoid = current == "VoidDisciple"
	local isSword = current == "GreatSword"
	ContextActionService:SetTitle("RiftPillShield", isSword and "Guard" or (isVoid and "Guard" or "Shield"))
	ContextActionService:SetTitle("RiftBuzzBoost", isSword and "Lunge" or (isVoid and "Step" or "Buzz"))
	ContextActionService:SetTitle("RiftRaveRush", isSword and "Uplift" or (isVoid and "Grasp" or "Rave"))
	ContextActionService:SetTitle("RiftTrippyToss", isSword and "Slam" or (isVoid and "Cleave" or "Trippy"))
	ContextActionService:SetTitle("RiftFrenzy", isSword and "Execute" or (isVoid and "Nova" or "Frenzy"))
end
localPlayer:GetAttributeChangedSignal("EquippedSpec"):Connect(updateTouchAbilityTitles)
updateTouchAbilityTitles()

local gui = Instance.new("ScreenGui")
gui.Name = "RIFTBOUND Controls"
-- Required: in Sibling mode modal children render ABOVE their own
-- background. Global mode made bright text/buttons appear blacked out when
-- UIManager elevated the modal root ZIndex.
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Optional progression HUD. If it fails to sync, combat controls still work.
local hudModule = script:FindFirstChild("ProgressionHUD") or script:WaitForChild("ProgressionHUD", 3)
if hudModule and hudModule:IsA("ModuleScript") then
	local loaded, hud = pcall(require, hudModule)
	if loaded and type(hud) == "table" and type(hud.Init) == "function" then
		local built, err = pcall(hud.Init, Players.LocalPlayer, gui)
		if not built then warn("[RIFTBOUND] Progression HUD failed:", err) end
	else
		warn("[RIFTBOUND] Progression HUD unavailable:", hud)
	end
end

-- Screenshot-inspired right-side move list for BOTH Specs. Replaces the old
-- centered Void ability dock; missing HUD never interrupts combat controls.
local abilitiesModule = script:FindFirstChild("SpecAbilityHUD") or script:WaitForChild("SpecAbilityHUD", 3)
if abilitiesModule and abilitiesModule:IsA("ModuleScript") then
	local ok, abilityHUD = pcall(require, abilitiesModule)
	if ok and type(abilityHUD) == "table" and type(abilityHUD.Init) == "function" then
		local created, err = pcall(abilityHUD.Init, Players.LocalPlayer, gui)
		if not created then warn("[RIFTBOUND] Ability HUD could not initialize:", err) end
	else
		warn("[RIFTBOUND] Ability HUD unavailable:", abilityHUD)
	end
end

-- Flat-grass prototype: no district tracker, B world guide, or N island map.
-- Existing combat, quests, Specs, inventory and mastery interfaces remain.

-- Inventory, story dialogue and mastery panels use the provided Art Deco palette.
-- Each is optional: a UI error cannot disable combat.
local function loadOptionalUI(moduleName)
	local mod=script:FindFirstChild(moduleName) or script:WaitForChild(moduleName,3)
	if not mod or not mod:IsA("ModuleScript") then
		warn("[RIFTBOUND UI] Module missing:",moduleName)
		return
	end
	local loaded,ui=pcall(require,mod)
	if not loaded or type(ui)~="table" or type(ui.Init)~="function" then
		warn("[RIFTBOUND UI] Could not load:",moduleName,ui)
		return
	end
	local worked,err=pcall(ui.Init,Players.LocalPlayer,gui)
	if not worked then warn("[RIFTBOUND UI] Could not initialize:",moduleName,err) end
end
loadOptionalUI("InventoryUI")
loadOptionalUI("DialogueUI")
loadOptionalUI("MasteryHUD")
loadOptionalUI("VitalsHUD")

-- Quest journal is optional: broken UI never disables attacks or Spec selection.
local boardModule = script:FindFirstChild("QuestBoard") or script:WaitForChild("QuestBoard", 3)
if boardModule and boardModule:IsA("ModuleScript") then
	local ok, board = pcall(require, boardModule)
	if ok and type(board) == "table" and type(board.Init) == "function" then
		local built, err = pcall(board.Init, Players.LocalPlayer, gui)
		if not built then warn("[RIFTBOUND] Quest Board could not initialize:", err) end
	else
		warn("[RIFTBOUND] Quest Board missing or failed to load:", board)
	end
end

-- The Spec menu is an optional UI module: combat input still loads without it.
local specMenuModule = script:FindFirstChild("SpecMenu") or script:WaitForChild("SpecMenu", 3)
if specMenuModule and specRequest then
	local ok, menu = pcall(require, specMenuModule)
	if ok and type(menu) == "table" and type(menu.Init) == "function" then
		local built, err = pcall(menu.Init, Players.LocalPlayer, specRequest, gui)
		if not built then warn("[RIFTBOUND] Spec menu failed:", err) end
	else
		warn("[RIFTBOUND] SpecMenu could not load:", menu)
	end
else
	warn("[RIFTBOUND] Spec menu unavailable; combat controls still active.")
end


-- All large windows are mutually exclusive and panels adjust for the viewport.
loadOptionalUI("UIManager")
loadOptionalUI("MainMenuUI")

-- UI is operational even when the animation pack is absent.
clientUIReady = gui:FindFirstChild("MainMenuToggle") ~= nil
	and gui:FindFirstChild("ProgressionHUD") ~= nil
	and gui:FindFirstChild("ArtDecoVitals") ~= nil
if clientUIReady then
	if diagnosticGui then diagnosticGui:Destroy() diagnosticGui=nil end
	print("[RIFTBOUND UI] Core HUD, status bars and central menu loaded.")
else
	warn("[RIFTBOUND UI] At least one core panel missing. Check Rojo modules and Output.")
end

-- Explain missing animation imports separately from UI, so a corrupted model
-- cannot look like a failure of the whole game.
task.delay(5, function()
	if not gui or not gui.Parent then return end
	if not Motion.GetStatus then return end
	local ok, status = pcall(Motion.GetStatus)
	if not ok or typeof(status) ~= "string" then return end
	print("[RIFTBOUND Animations]", status)
	if status:find("No animation clips", 1, true) then
		local hint = Instance.new("TextLabel")
		hint.Name = "AnimationImportHint"
		hint.AnchorPoint = Vector2.new(0.5, 0)
		hint.Position = UDim2.new(0.5, 0, 0, 62)
		hint.Size = UDim2.fromOffset(465, 51)
		hint.BackgroundColor3 = Color3.fromRGB(34, 25, 31)
		hint.BackgroundTransparency = 0.12
		hint.BorderSizePixel = 0
		hint.TextColor3 = Color3.fromRGB(255, 226, 172)
		hint.TextSize = 13
		hint.TextWrapped = true
		hint.Font = Enum.Font.GothamBold
		hint.Text = "Animations not imported. Insert your .rbxm model under ReplicatedStorage in Edit mode. HUD/combat still work."
		hint.Parent = gui
		task.delay(11,function()
			if hint.Parent then hint:Destroy() end
		end)
	end
end)

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
	if effect == "NPCWindup" then
		floatingText(root, "DODGE OR PARRY!", Color3.fromRGB(255, 145, 90))
		shockwave(root, Color3.fromRGB(255, 125, 85), 3.5)
		return
	end
	if effect == "Dash" then
		shockwave(root, Color3.fromRGB(110, 190, 255), 4)
		return
	end
	if effect == "Stagger" then
		if character == Players.LocalPlayer.Character then
			floatingText(root, "STAGGERED!", Color3.fromRGB(252, 150, 108))
		end
		return
	elseif effect == "NauseaMiss" then
		floatingText(root, "MISSED!", Color3.fromRGB(210, 180, 255))
	elseif effect == "Hit" and typeof(damage) == "number" then
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
local shieldLabel = Instance.new("TextLabel")
shieldLabel.Name = "PillShieldIndicator"
shieldLabel.Size = UDim2.fromOffset(245, 32)
shieldLabel.Position = UDim2.new(0, 15, 1, -138)
shieldLabel.BackgroundColor3 = Color3.fromRGB(38, 40, 90)
shieldLabel.BackgroundTransparency = 0.12
shieldLabel.TextColor3 = Color3.fromRGB(135, 235, 255)
shieldLabel.Font = Enum.Font.GothamBold
shieldLabel.TextSize = 16
shieldLabel.Parent = gui

local buzzLabel = Instance.new("TextLabel")
buzzLabel.Name = "BuzzBoostIndicator"
buzzLabel.Size = UDim2.fromOffset(245, 32)
buzzLabel.Position = UDim2.new(0, 15, 1, -176)
buzzLabel.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
buzzLabel.BackgroundTransparency = 0.12
buzzLabel.TextColor3 = Color3.fromRGB(255, 215, 105)
buzzLabel.Font = Enum.Font.GothamBold
buzzLabel.TextSize = 16
buzzLabel.Parent = gui

local function updateBuzz()
	local character = player.Character
	local now = workspace:GetServerTimeNow()
	local activeEnds = character and character:GetAttribute("BuzzBoostEnds") or 0
	local ready = player:GetAttribute("BuzzBoostReadyAt") or 0
	buzzLabel.Visible = player:GetAttribute("EquippedSpec") == "AshleySimmons"
	if activeEnds > now then
		buzzLabel.Text = "X  BUZZ BOOST: " .. math.ceil(activeEnds-now) .. "s"
	elseif ready > now then
		buzzLabel.Text = "X  BUZZ COOLDOWN: " .. math.ceil(ready-now) .. "s"
	else
		buzzLabel.Text = "X  BUZZ BOOST READY"
	end
end

local shieldConnection
local function updateShield()
	local character = player.Character
	local hp = character and character:GetAttribute("PillShieldHP") or 0
	local ready = player:GetAttribute("PillShieldReadyAt") or 0
	local remaining = math.max(0, math.ceil(ready - workspace:GetServerTimeNow()))
	shieldLabel.Visible = player:GetAttribute("EquippedSpec") == "AshleySimmons"
	if hp > 0 then
		shieldLabel.Text = "Z  PILL SHIELD: " .. math.ceil(hp) .. " HP"
	elseif remaining > 0 then
		shieldLabel.Text = "Z  SHIELD COOLDOWN: " .. remaining .. "s"
	else
		shieldLabel.Text = "Z  PILL SHIELD READY"
	end
end
local function watchCharacter(character)
	if shieldConnection then shieldConnection:Disconnect() end
	shieldConnection = character:GetAttributeChangedSignal("PillShieldHP"):Connect(updateShield)
	updateBuzz()
	updateShield()
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then watchCharacter(player.Character) end
player:GetAttributeChangedSignal("PillShieldReadyAt"):Connect(updateShield)
player:GetAttributeChangedSignal("BuzzBoostReadyAt"):Connect(updateBuzz)
task.spawn(function()
	while gui.Parent do
		updateShield()
		updateBuzz()
		task.wait(0.2)
	end
end)
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


-- Skill rows mirror server-owned cooldown and status attributes.
local skillRows = {
	{key = "C", name = "RAVE RUSH", attribute = "AshleyCReadyAt", active = "RaveRushEnds", y = -214, color = Color3.fromRGB(135, 255, 235)},
	{key = "V", name = "TRIPPY TOSS", attribute = "AshleyVReadyAt", active = nil, y = -252, color = Color3.fromRGB(225, 165, 255)},
	{key = "G", name = "FRENZY", attribute = "AshleyGReadyAt", active = nil, y = -290, color = Color3.fromRGB(255, 150, 195)},
}
for _, row in skillRows do
	local control = Instance.new("TextLabel")
	control.Name = row.name:gsub(" ", "") .. "Indicator"
	control.Size = UDim2.fromOffset(245, 32)
	control.Position = UDim2.new(0, 15, 1, row.y)
	control.BackgroundColor3 = Color3.fromRGB(29, 25, 50)
	control.BackgroundTransparency = 0.12
	control.TextColor3 = row.color
	control.Font = Enum.Font.GothamBold
	control.TextSize = 16
	control.Parent = gui
	row.ui = control
end
local function updateAshleySkills()
	local character = player.Character
	local currentTime = workspace:GetServerTimeNow()
	local hasAshley = player:GetAttribute("EquippedSpec") == "AshleySimmons"
	for _, row in skillRows do
		row.ui.Visible = hasAshley
		local activeEnds = row.active and character and character:GetAttribute(row.active) or 0
		local readyTime = player:GetAttribute(row.attribute) or 0
		if activeEnds > currentTime then
			row.ui.Text = row.key .. "  " .. row.name .. ": " .. math.ceil(activeEnds-currentTime) .. "s"
		elseif readyTime > currentTime then
			row.ui.Text = row.key .. "  COOLDOWN: " .. math.ceil(readyTime-currentTime) .. "s"
		else
			row.ui.Text = row.key .. "  " .. row.name .. " READY"
		end
	end
end

-- Local-only visual impairment and temporary PC movement inversion.
local blur = Instance.new("BlurEffect")
blur.Name = "RiftboundVisionBlur"
blur.Size = 0
blur.Parent = Lighting
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "RiftboundVisionGrade"
grade.Parent = Lighting
local inverted = false
local pressed = {W=false,A=false,S=false,D=false}
local function confusionInput(_, inputState, input)
	local k = input.KeyCode.Name
	if pressed[k] ~= nil then
		pressed[k] = inputState == Enum.UserInputState.Begin
	end
	return Enum.ContextActionResult.Sink
end
local function setInverted(enabled)
	if enabled == inverted then return end
	inverted = enabled
	if enabled then
		ContextActionService:BindActionAtPriority("RiftConfusionMovement", confusionInput, false, 4000,
			Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)
		RunService:BindToRenderStep("RiftConfusionMove", Enum.RenderPriority.Input.Value + 20, function()
			local character = player.Character
			local hum = character and character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local x = (pressed.A and 1 or 0) - (pressed.D and 1 or 0)
				local z = (pressed.W and 1 or 0) - (pressed.S and 1 or 0)
				local direction = Vector3.new(x,0,z)
				hum:Move(direction.Magnitude > 1 and direction.Unit or direction, true)
			end
		end)
	else
		ContextActionService:UnbindAction("RiftConfusionMovement")
		RunService:UnbindFromRenderStep("RiftConfusionMove")
		for k in pressed do pressed[k] = false end
	end
end
task.spawn(function()
	while gui.Parent do
		updateAshleySkills()
		local character = player.Character
		local currentTime = workspace:GetServerTimeNow()
		local trippy = character and (character:GetAttribute("TrippyVisionEnds") or 0) > currentTime
		local confused = character and (character:GetAttribute("FrenzyConfusionEnds") or 0) > currentTime
		blur.Size = trippy and 18 or (confused and 8 or 0)
		grade.Saturation = trippy and -0.65 or (confused and 0.65 or 0)
		grade.TintColor = confused and Color3.fromRGB(250, 165, 255) or Color3.new(1,1,1)
		setInverted(confused == true)
		task.wait(0.12)
	end
	setInverted(false)
	blur:Destroy()
	grade:Destroy()
end)

if specFX then
specFX.OnClientEvent:Connect(function(effect, target, status)
	if effect == "TrippyExplosion" or effect == "FrenzyExplosion" then
		if typeof(target) ~= "Vector3" then return end
		local marker = Instance.new("Part")
		marker.Name = "AshleyImpactLabel"
		marker.Size = Vector3.new(0.1,0.1,0.1)
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.Transparency = 1
		marker.Position = target
		marker.Parent = workspace
		floatingText(marker, effect == "TrippyExplosion" and "TRIPPY!" or tostring(status),
			effect == "TrippyExplosion" and Color3.fromRGB(210, 135, 255) or Color3.fromRGB(255, 155, 195))
		Debris:AddItem(marker, 0.8)
		return
	end
	if (effect == "SwordAbility" or effect == "SwordGuardEnd")
		and target and target:IsA("Model") then
		Motion.Play(target, effect, status)
		if effect == "SwordGuardEnd" then return end
	end
	if not target or not target:IsA("Model") then return end
	local root = target:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if effect == "SwordAbility" then
		local names = {Z="COVENANT GUARD",X="RENDING LUNGE",C="TITAN UPLIFT",
			V="FALLING COVENANT",G="ABYSSAL EXECUTION"}
		if names[status] then
			floatingText(root, names[status] .. "!", Color3.fromRGB(255, 194, 104))
			if status ~= "Z" then shockwave(root, Color3.fromRGB(173, 97, 255),status == "G" and 11 or 5) end
		end
		return
	elseif effect == "RaveRush" then
		floatingText(root, "RAVE RUSH!", Color3.fromRGB(110, 245, 220))
		return
	elseif effect == "FrenzyCast" then
		floatingText(root, "FRENZY!", Color3.fromRGB(255, 100, 195))
		return
	elseif effect == "VoidMark" then
		floatingText(root, "VOID MARK " .. tostring(status) .. "/3", Color3.fromRGB(185, 128, 255))
		return
	elseif effect == "VoidBurst" then
		floatingText(root, "VOID BURST!", Color3.fromRGB(233, 151, 255))
		shockwave(root, Color3.fromRGB(168, 87, 255), 7)
		return
	elseif effect == "VoidGuard" or effect == "VoidStep" or effect == "VoidNova" then
		local names = {VoidGuard="ABYSS GUARD!", VoidStep="VOID STEP!", VoidNova="ABYSS NOVA!"}
		floatingText(root, names[effect], Color3.fromRGB(161, 155, 255))
		return
	elseif effect == "VoidGrasp" or effect == "VoidCleave" then
		floatingText(root, effect == "VoidGrasp" and "SHADOW GRASP!" or "RIFT CLEAVE!", Color3.fromRGB(202, 135, 255))
		return
	elseif effect ~= "PillImpact" then
		return
	end
	local colors = {
		ChillPill = Color3.fromRGB(100,220,255),
		Euphoria = Color3.fromRGB(245,100,235),
		AdrenalineRush = Color3.fromRGB(255,160,60),
		AntiInflammatory = Color3.fromRGB(100,255,150),
		MoodStabilizer = Color3.fromRGB(195,155,255),
	}
	local color = colors[status] or Color3.new(1,1,1)
	floatingText(root, status, color)
	shockwave(root, color, 4.5)
end)
end
