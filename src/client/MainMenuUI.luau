--!strict
-- RIFTBOUND central M menu. Opens existing, fully functional panels rather
-- than creating second copies of the inventory, quests, specs or map.
-- All content is player-facing only; profile data remains server owned.
local ContextActionService=game:GetService("ContextActionService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Deco=require(script.Parent.ArtDecoUI)
local Mastery=require(ReplicatedStorage.Riftbound.Shared.MasteryConfig)
local Registry=require(ReplicatedStorage.Riftbound.Shared.SpecRegistry)
local Menu={}

local SECTIONS={
	{title="SPECS",tagline="Equip your fighting style",kind="panel",target="SpecSelection",symbol="S"},
	{title="QUESTS",tagline="Contracts and story missions",kind="panel",target="QuestJournal",symbol="Q"},
	{title="INVENTORY",tagline="Gear, potions and materials",kind="panel",target="DecoInventory",symbol="I"},
	{title="WORLD MAP",tagline="Explore four island districts",kind="panel",target="RiftboundWorldMap",symbol="W"},
	{title="WORLD GUIDE",tagline="Zones and suggested levels",kind="panel",target="WorldGuide",symbol="G"},
	{title="CHARACTER",tagline="Level, coins and dungeon clears",kind="detail",target="Character",symbol="C"},
	{title="MASTERY",tagline="Skill XP and ability unlocks",kind="detail",target="Mastery",symbol="M"},
	{title="DUNGEONS",tagline="Abyss Citadel and its rewards",kind="detail",target="Dungeons",symbol="D"},
}

local function colorLabel(element,tint,size)
	element.TextColor3=tint
	if size then element.TextSize=size end
	element.TextStrokeColor3=Color3.fromRGB(6,7,11)
	element.TextStrokeTransparency=0.9
end

function Menu.Init(player,gui)
	local openButton=Deco.MakeButton(gui,"MainMenuToggle","MENU  [M]",
		UDim2.new(1,-155,0,16),UDim2.fromOffset(142,41))
	openButton.TextSize=15
	openButton.ZIndex=5

	local panel=Instance.new("Frame")
	panel.Name="RiftMainMenu"
	panel.AnchorPoint=Vector2.new(0.5,0.5)
	panel.Position=UDim2.fromScale(0.5,0.49)
	panel.Size=UDim2.fromOffset(575,540)
	panel.Visible=false
	panel.Parent=gui
	Deco.Panel(panel)
	local widthLimit=Instance.new("UISizeConstraint")
	widthLimit.Name="MenuSizeLimit"
	widthLimit.MinSize=Vector2.new(300,390)
	widthLimit.MaxSize=Vector2.new(575,540)
	widthLimit.Parent=panel

	local heading=Deco.Heading(Deco.Text(panel,"Title","RIFTBOUND",
		UDim2.fromOffset(19,14),UDim2.new(1,-82,0,35),28,true))
	local sub=Deco.Text(panel,"Subtitle","THE JOURNEY CONTINUES    /    MAIN MENU",
		UDim2.fromOffset(21,51),UDim2.new(1,-70,0,23),12,false)
	sub.TextColor3=Deco.Muted
	local close=Deco.MakeButton(panel,"Close","X",
		UDim2.new(1,-55,0,17),UDim2.fromOffset(34,32))
	close.Activated:Connect(function()panel.Visible=false end)

	local stat=Deco.Text(panel,"PlayerSummary","LEVEL 1    /    0 RIFT COINS",
		UDim2.fromOffset(20,81),UDim2.new(1,-40,0,25),14,true)
	stat.TextColor3=Deco.PaleGold

	local cards={}
	for index,option in SECTIONS do
		local col=(index-1)%2
		local row=math.floor((index-1)/2)
		local x=17+col*275
		local y=119+row*84
		local tile=Deco.MakeButton(panel,option.title.."Tile","",
			UDim2.fromOffset(x,y),UDim2.fromOffset(267,75))
		tile.Name=option.title.."Tile"
		tile.AutoButtonColor=true
		tile.Text=""
		local background=Instance.new("Frame")
		background.Name="Monogram"
		background.Position=UDim2.fromOffset(10,10)
		background.Size=UDim2.fromOffset(42,50)
		background.BorderSizePixel=0
		background.BackgroundColor3=Deco.Bronze
		background.Parent=tile
		local emblem=Deco.Text(background,"Letter",option.symbol,
			UDim2.fromScale(0,0),UDim2.fromScale(1,1),23,true)
		emblem.TextXAlignment=Enum.TextXAlignment.Center
		emblem.TextYAlignment=Enum.TextYAlignment.Center
		colorLabel(emblem,Deco.PaleGold)
		local label=Deco.Text(tile,"Title",option.title,
			UDim2.fromOffset(62,8),UDim2.fromOffset(190,26),17,true)
		colorLabel(label,Deco.PaleGold)
		local note=Deco.Text(tile,"Caption",option.tagline,
			UDim2.fromOffset(63,36),UDim2.fromOffset(191,30),11,false)
		colorLabel(note,Deco.Paper)
		cards[index]=tile
	end
	local footer=Deco.Text(panel,"Footnote",
		"M  OPEN/CLOSE    •    I  INVENTORY    •    P  QUESTS    •    B  GUIDE    •    N  MAP",
		UDim2.fromOffset(18,472),UDim2.new(1,-36,0,54),11,false)
	footer.TextXAlignment=Enum.TextXAlignment.Center
	footer.TextColor3=Deco.Muted

	-- Local detail page for Character / Mastery / Dungeons: each button has
	-- an actual destination and shows live replicated information.
	local detail=Instance.new("Frame")
	detail.Name="RiftMainMenuDetail"
	detail.Position=UDim2.fromOffset(17,115)
	detail.Size=UDim2.new(1,-34,0,346)
	detail.Visible=false
	detail.Parent=panel
	Deco.Panel(detail)
	local detailTitle=Deco.Heading(Deco.Text(detail,"Heading","CHARACTER",
		UDim2.fromOffset(16,12),UDim2.new(1,-125,0,29),20,true))
	local back=Deco.MakeButton(detail,"Back","BACK",
		UDim2.new(1,-98,0,12),UDim2.fromOffset(82,30))
	local details=Deco.Text(detail,"Details","",
		UDim2.fromOffset(19,59),UDim2.new(1,-38,1,-77),16,false)
	details.TextYAlignment=Enum.TextYAlignment.Top
	details.TextColor3=Deco.Paper
	back.Activated:Connect(function()detail.Visible=false end)

	local detailPage=nil
	local function redrawDetail()
		if not detail.Visible then return end
		if detailPage=="Character" then
			local spec=player:GetAttribute("EquippedSpec") or "Unarmed"
			local equipped=Registry.Specs[spec]
			detailTitle.Text="YOUR CHARACTER"
			details.Text="LEVEL   "..tostring(player:GetAttribute("Level") or 1).."/50"
				.."\n\nEXPERIENCE   "..tostring(player:GetAttribute("XP") or 0)
				.." / "..tostring(player:GetAttribute("XPToNext") or 0)
				.."\n\nRIFT COINS   "..tostring(player:GetAttribute("RiftCoins") or 0)
				.."\n\nEQUIPPED SPEC   "..(equipped and equipped.Name or "Unarmed")
				.."\n\nNPC DEFEATS   "..tostring(player:GetAttribute("NPCKills") or 0)
				.."\n\nABYSS CITADEL CLEARS   "..tostring(player:GetAttribute("AbyssClears") or 0)
		elseif detailPage=="Mastery" then
			local spec=player:GetAttribute("EquippedSpec")
			local xp=player:GetAttribute("SpecMastery_"..tostring(spec)) or 0
			local level,into,needed=Mastery.LevelDetails(xp)
			detailTitle.Text="SPEC MASTERY"
			details.Text="EQUIPPED   "..(Registry.Specs[spec] and Registry.Specs[spec].Name or "None")
				.."\n\nMASTERY LEVEL   "..level.."/"..Mastery.MaxLevel
				.."\nPROGRESS   "..into.." / "..needed.." XP"
				.."\nTOTAL MASTERY XP   "..xp
				.."\n\nZ   0 XP  (+2 on cast)"
				.."\nX   10 XP  (+3 on cast)"
				.."\nC   25 XP  (+4 on cast)"
				.."\nV   40 XP  (+5 on cast)"
				.."\nG   60 XP  (+7 on cast)"
		elseif detailPage=="Dungeons" then
			detailTitle.Text="DUNGEONS / RAIDS"
			details.Text="THE ABYSS CITADEL"
				.."\nLocation: Rift Expanse"
				.."\nRecommended: Level 25+"
				.."\n\nBOSS  •  Abyss Warden"
				.."\n1,650 HP with telegraphed area attacks"
				.."\nBeware the enraged phase and Abyss Echo."
				.."\n\nREWARDS"
				.."\nRift Coins, XP, Abyss Sigils"
				.."\n\nTravel to the Rift Expanse and interact with"
				.."\nthe citadel gate to enter the dungeon."
		end
	end

	local function enterDetail(page)
		detailPage=page
		detail.Visible=true
		redrawDetail()
	end

	for index,option in SECTIONS do
		cards[index].Activated:Connect(function()
			if option.kind=="detail" then
				enterDetail(option.target)
			else
				local target=gui:FindFirstChild(option.target)
				if target and target:IsA("GuiObject") then
					detail.Visible=false
					if option.target=="DecoInventory" then
						target:SetAttribute("OpenFromMainMenu",true)
					end
					panel.Visible=false
					target.Visible=true
				else
					footer.Text=option.title.." is unavailable. Check Studio Output / Rojo."
				end
			end
		end)
	end

	local function refreshSummary()
		local level=player:GetAttribute("Level") or 1
		local coins=player:GetAttribute("RiftCoins") or 0
		stat.Text="LEVEL "..level.."    /    "..coins.." RIFT COINS"
		redrawDetail()
	end
	for _,attr in {"Level","XP","XPToNext","RiftCoins","EquippedSpec",
		"NPCKills","AbyssClears","SpecMastery_AshleySimmons","SpecMastery_VoidDisciple"} do
		player:GetAttributeChangedSignal(attr):Connect(refreshSummary)
	end
	refreshSummary()
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			detail.Visible=false
			footer.Text="M  OPEN/CLOSE    •    I  INVENTORY    •    P  QUESTS    •    B  GUIDE    •    N  MAP"
			refreshSummary()
		end
	end)

	local function toggle()
		panel.Visible=not panel.Visible
	end
	openButton.Activated:Connect(toggle)
	ContextActionService:BindAction("RiftMainMenu",function(_,inputState)
		if inputState==Enum.UserInputState.Begin then
			toggle()
		end
		return Enum.ContextActionResult.Sink
	end,false,Enum.KeyCode.M)
	print("[RIFTBOUND UI] M opens the central menu; old shortcuts remain available.")
end

return Menu
