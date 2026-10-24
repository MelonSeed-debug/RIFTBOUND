--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local rift = ReplicatedStorage:WaitForChild("Riftbound")
local request = rift.Remotes.CombatRequest
local fx = rift.Remotes.CombatFX

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

fx.OnClientEvent:Connect(function(effect, character, combo)
	if not character or not character:IsA("Model") then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
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
