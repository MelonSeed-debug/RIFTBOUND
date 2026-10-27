--!strict
-- Art Deco three-bar combat HUD inspired by the user's red/blue/green sprite sheet.
-- Red = health, blue = active shield, green = Spec mastery.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Deco=require(script.Parent.ArtDecoUI)
local Mastery=require(ReplicatedStorage.Riftbound.Shared.MasteryConfig)
local HUD={}

local function bar(parent,name,y,tint)
	local label=Deco.Text(parent,name.."Title",name,
		UDim2.fromOffset(14,y),UDim2.fromOffset(304,17),11,true)
	label.TextColor3=Deco.Paper
	local track=Instance.new("Frame")
	track.Name=name.."Track"
	track.Size=UDim2.new(1,-29,0,12)
	track.Position=UDim2.fromOffset(14,y+18)
	track.BackgroundColor3=Deco.Slate
	track.BorderSizePixel=0
	track.ClipsDescendants=true
	track.Parent=parent
	local border=Instance.new("UIStroke")
	border.Thickness=1.1
	border.Color=Deco.Gold
	border.Parent=track
	local fill=Instance.new("Frame")
	fill.Name=name.."Fill"
	fill.Size=UDim2.fromScale(0,1)
	fill.BackgroundColor3=tint
	fill.BorderSizePixel=0
	fill.Parent=track
	local gradient=Instance.new("UIGradient")
	gradient.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromRGB(54,45,38)),
		ColorSequenceKeypoint.new(0.25,tint),
		ColorSequenceKeypoint.new(0.7,tint),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(250,226,156)),
	})
	gradient.Parent=fill
	return label,fill
end

function HUD.Init(player,gui)
	local panel=Instance.new("Frame")
	panel.Name="ArtDecoVitals"
	panel.Size=UDim2.fromOffset(325,145)
	-- UIManager pins this below the left-side profile card on compact
	-- screens, or to the bottom-left on desktop. No legacy hints overlap.
	panel.Position=UDim2.new(0,15,1,-176)
	panel.Parent=gui
	Deco.Panel(panel)
	local header=Deco.Text(panel,"Title","RIFTBOUND  /  VITAL STATUS",
		UDim2.fromOffset(13,4),UDim2.new(1,-26,0,22),14,true)
	Deco.Heading(header)
	local hpLabel,hpFill=bar(panel,"HEALTH",25,Color3.fromRGB(228,76,72))
	local shieldLabel,shieldFill=bar(panel,"SHIELD",63,Color3.fromRGB(74,172,225))
	local masteryLabel,masteryFill=bar(panel,"MASTERY",101,Color3.fromRGB(109,206,135))
	local healthConnections={}
	local function clearHealth()
		for _,conn in healthConnections do conn:Disconnect() end
		table.clear(healthConnections)
	end
	local function update()
		local char=player.Character
		local hum=char and char:FindFirstChildOfClass("Humanoid")
		local hp=hum and hum.Health or 0
		local maxHP=hum and hum.MaxHealth or 100
		local shield=char and char:GetAttribute("PillShieldHP") or 0
		local expires=char and char:GetAttribute("PillShieldEnds") or 0
		local spec=player:GetAttribute("EquippedSpec") or "None"
		local mastery=player:GetAttribute("SpecMastery_"..spec) or 0
		local masteryLevel,masteryWithin,masteryRequired=Mastery.LevelDetails(mastery)
		hpLabel.Text="HEALTH   "..math.ceil(hp).." / "..math.floor(maxHP)
		local maxShield=spec=="VoidDisciple" and 100 or 150
		if expires<=workspace:GetServerTimeNow() then shield=0 end
		shieldLabel.Text="SHIELD   "..math.floor(shield).." / "..maxShield
		if spec=="None" or spec=="" then
			masteryLabel.Text="MASTERY   EQUIP A SPEC"
		elseif masteryLevel>=Mastery.MaxLevel then
			masteryLabel.Text="MASTERY   MAX LEVEL"
		else
			masteryLabel.Text="MASTERY LV "..masteryLevel.."   "..masteryWithin.." / "..masteryRequired.." XP"
		end
		hpFill.Size=UDim2.fromScale(math.clamp(hp/math.max(1,maxHP),0,1),1)
		shieldFill.Size=UDim2.fromScale(math.clamp(shield/maxShield,0,1),1)
		masteryFill.Size=UDim2.fromScale(masteryRequired==0 and 1
			or math.clamp(masteryWithin/masteryRequired,0,1),1)
	end
	local function bindCharacter(char)
		clearHealth()
		local hum=char:WaitForChild("Humanoid",5)
		if hum then
			table.insert(healthConnections,hum.HealthChanged:Connect(update))
			table.insert(healthConnections,hum:GetPropertyChangedSignal("MaxHealth"):Connect(update))
		end
		table.insert(healthConnections,char:GetAttributeChangedSignal("PillShieldHP"):Connect(update))
		table.insert(healthConnections,char:GetAttributeChangedSignal("PillShieldEnds"):Connect(update))
		update()
	end
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then task.spawn(bindCharacter,player.Character) end
	player:GetAttributeChangedSignal("EquippedSpec"):Connect(update)
	for _,id in {"AshleySimmons","VoidDisciple","GreatSword"} do
		player:GetAttributeChangedSignal("SpecMastery_"..id):Connect(update)
	end
	-- Shield timeouts are handled by the server's attributes; this also refreshes
	-- the expiration display if no other attribute changes arrive.
	task.spawn(function()
		while gui.Parent do
			update()
			task.wait(0.5)
		end
		clearHealth()
	end)
end
return HUD
