--!strict
-- RIFTBOUND UI layout supervisor.
-- One large window visible at a time, responsive scaling for small viewports,
-- and a clear separation between the left stats, center navigation, right tools.
-- Called AFTER the UI modules have been initialized.
local Workspace=game:GetService("Workspace")
 
local Manager={}
local MODALS={
	RiftMainMenu={W=575,H=492},
	DecoInventory={W=530,H=515},
	QuestJournal={W=430,H=470},
	SpecSelection={W=380,H=480},
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
		local margin=compact and 10 or 16

		-- Inventory, quests, Specs and dialogue cannot
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

		-- Two distinct, predictable HUD anchors. Keep status/XP at top-left,
		-- and health at bottom-left on desktop. Stack on small viewports so
		-- neither HUD clips or overlaps the Roblox topbar.
		local progress=gui:FindFirstChild("ProgressionHUD")
		local statsScale=math.clamp((w-170)/320,0.56,1)
		applyScale(progress,statsScale,"ResponsiveStatsScale")
		if progress then
			progress.AnchorPoint=Vector2.new(0,0)
			progress.Position=UDim2.fromOffset(margin,14)
		end

		local vitals=gui:FindFirstChild("ArtDecoVitals")
		if vitals then
			local vitalsScale=math.clamp((w-170)/325,0.56,1)
			applyScale(vitals,vitalsScale,"ResponsiveVitalsScale")
			if h>=535 and w>=730 then
				vitals.AnchorPoint=Vector2.new(0,1)
				vitals.Position=UDim2.new(0,margin,1,-margin)
			else
				vitals.AnchorPoint=Vector2.new(0,0)
				vitals.Position=UDim2.fromOffset(margin,
					14+math.ceil(153*statsScale)+14)
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
			-- Stack below MENU; both are pinned to the same right margin.
			tracker.AnchorPoint=Vector2.new(1,0)
			tracker.Position=UDim2.new(1,-margin,0,72)
			applyScale(tracker,compact and 0.83 or 1,"QuestCompactScale")
		end

		local menuButton=gui:FindFirstChild("MainMenuToggle")
		if menuButton then
			menuButton.AnchorPoint=Vector2.new(1,0)
			menuButton.Position=UDim2.new(1,-margin,0,14)
			menuButton.Visible=true
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
