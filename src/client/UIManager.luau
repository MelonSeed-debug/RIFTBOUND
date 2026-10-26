--!strict
-- RIFTBOUND UI layout supervisor.
-- One large window visible at a time, responsive scaling for small viewports,
-- and a clear separation between the left stats, center navigation, right tools.
-- Called AFTER the UI modules have been initialized.
local Workspace=game:GetService("Workspace")
 
local Manager={}
local MODALS={
	RiftMainMenu={W=575,H=540},
	DecoInventory={W=530,H=515},
	QuestJournal={W=430,H=470},
	SpecSelection={W=380,H=408},
	RiftboundWorldMap={W=720,H=496},
	WorldGuide={W=390,H=330},
	RiftStoryDialogue={W=650,H=274},
}

local function applyScale(node,scale,name)
	if not node then return end
	local scaler=node:FindFirstChild(name)
	if not scaler then
		scaler=Instance.new("UIScale")
		scaler.Name=name
		scaler.Parent=node
	end
	scaler.Scale=scale
end

function Manager.Init(_,gui)
	-- Prevent modals from hiding their own text on ScreenGuis configured
	-- with global ZIndex layering.
	if gui:IsA("ScreenGui") then
		gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	end
	local watched={}
	local legacyButtons={
		OpenSpecs=true,
		OpenQuestLog=true,
		InventoryToggle=true,
		WorldMapButton=true,
	}
	local processing=false

	local function watchModal(element)
		if watched[element] or not MODALS[element.Name] then return end
		watched[element]=true
		-- With Sibling ZIndex, every descendant renders over the panel.
		element.ZIndex=20
		element.Active=true
		element:GetPropertyChangedSignal("Visible"):Connect(function()
			if processing or not element.Visible then return end
			processing=true
			for other in watched do
				if other~=element and other.Parent and other.Visible then
					other.Visible=false
				end
			end
			processing=false
		end)
	end

	local function watchElement(child)
		watchModal(child)
		if legacyButtons[child.Name] and child:IsA("GuiObject") then
			child.Visible=false
		end
	end
	for _,child in gui:GetChildren() do watchElement(child) end
	gui.ChildAdded:Connect(watchElement)

	local function layout()
		local camera=Workspace.CurrentCamera
		if not camera then return end
		local size=camera.ViewportSize
		local w,h=size.X,size.Y
		local compact=w<730
		local contentLeft=15+math.min(320,math.max(180,w-180))
		local contentRight=w-164
		local gap=math.max(0,contentRight-contentLeft)
		local contentCenter=(contentLeft+contentRight)/2

		-- Inventory, quests, Specs, world guide, map and dialogue cannot
		-- stack over one another, and scale to fit viewport height.
		for panel in watched do
			if panel.Parent then
				local limits=MODALS[panel.Name]
				local maxWidth=limits.W
				local maxHeight=limits.H
				local s=math.clamp(math.min(1,(w-24)/maxWidth,(h-35)/maxHeight),0.45,1)
				applyScale(panel,s,"ResponsiveWindowScale")
			end
		end

		local progress=gui:FindFirstChild("ProgressionHUD")
		applyScale(progress,math.min(1,math.max(0.55,(w-180)/320)),"ResponsiveStatsScale")

		local mastery=gui:FindFirstChild("RiftMasteryHUD")
		if mastery then
			local scale=math.min(1,math.max(0.58,(w-180)/320))
			if h<690 then scale=math.min(scale,math.clamp((h-500)/170,0.54,1)) end
			applyScale(mastery,scale,"ResponsiveMasteryScale")
			mastery.Position=UDim2.fromOffset(15,157)
		end

		local vitals=gui:FindFirstChild("ArtDecoVitals")
		if vitals then
			local scale=math.min(1,math.max(0.57,(w-180)/325))
			applyScale(vitals,scale,"ResponsiveVitalsScale")
			vitals.Position=compact
				and UDim2.new(0,15,0,276)
				or (h<580 and UDim2.new(0,15,0,250)
					or UDim2.new(0,15,1,-176))
		end

		local header=gui:FindFirstChild("WorldGuideToggle")
		local map=gui:FindFirstChild("WorldMapButton")
		if compact then
			-- On phones, put navigation underneath Specs, quests and inventory
			-- instead of over the two left-side stat panels.
			if header then
				header.AnchorPoint=Vector2.zero
				header.Position=UDim2.new(1,-155,0,221)
				applyScale(header,0.69,"ResponsiveWorldScale")
			end
			if map then
				map.Position=UDim2.new(1,-155,0,276)
				applyScale(map,0.95,"ResponsiveMapScale")
			end
		else
			local navScale=math.min(1,math.max(0.5,gap/335))
			if header then
				header.AnchorPoint=Vector2.new(0.5,0)
				header.Position=UDim2.fromOffset(contentCenter,17)
				applyScale(header,navScale,"ResponsiveWorldScale")
			end
			if map then
				map.Position=UDim2.fromOffset(contentCenter-68,88)
				applyScale(map,math.min(1,math.max(0.6,gap/140)),"ResponsiveMapScale")
			end
		end

		-- The skills sidebar stays pinned to the RIGHT edge, never centered
		-- over the crosshair. Its width shrinks to leave breathing room for
		-- the left health/progression panels, including on smaller screens.
		local sidebar=gui:FindFirstChild("RiftAbilitySidebar")
		if sidebar then
			local scaledWidth=math.clamp((w-380)/332,0.42,1)
			local scaledHeight=math.clamp((h-175)/431,0.42,1)
			local scale=sidebar:FindFirstChild("ResponsiveAbilityScale")
			if scale and scale:IsA("UIScale") then
				scale.Scale=math.min(scaledWidth,scaledHeight)
			end
			sidebar.AnchorPoint=Vector2.new(1,0.5)
			sidebar.Position=UDim2.new(1,-15,0.61,0)
			-- The existing touch ability buttons remain accessible. The
			-- read-only sidebar is tucked away on very small touch screens.
			sidebar:SetAttribute("RiftHideForTouch",
				game:GetService("UserInputService").TouchEnabled and w<540)
		end

		local tracker=gui:FindFirstChild("QuestTracker")
		if tracker then
			tracker.Position=UDim2.new(1,-238,0,86)
			if compact then
				applyScale(tracker,0.72,"QuestCompactScale")
			else
				applyScale(tracker,1,"QuestCompactScale")
			end
		end

		local menuButton=gui:FindFirstChild("MainMenuToggle")
		if menuButton then
			menuButton.Position=UDim2.new(1,-155,0,16)
			menuButton.Visible=true
		end

		local hint=gui:FindFirstChild("ControlsHint")
		if hint then
			hint.Visible=not compact
		end
	end

	local function bindCamera(camera)
		if not camera then return end
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
		layout()
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		bindCamera(Workspace.CurrentCamera)
	end)
	gui.ChildAdded:Connect(function()
		task.defer(layout)
	end)
	bindCamera(Workspace.CurrentCamera)
end

return Manager
