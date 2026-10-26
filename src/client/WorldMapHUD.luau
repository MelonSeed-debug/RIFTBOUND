--!strict
-- RIFTBOUND island map: simple interactable schematic based on WorldConfig.
-- N or MAP button; no client teleport requests or reward logic.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local World = require(ReplicatedStorage.Riftbound.Shared.WorldConfig)
local Deco = require(script.Parent.ArtDecoUI)
local Map = {}

local DUSK = Deco.Ink
local SKY = Color3.fromRGB(25,27,36)
local TEXT = Deco.Paper
local MUTE = Deco.Muted
local SAFE = Deco.Gold
local minX,maxX,minZ,maxZ = -370,560,-555,155

local function nodePos(x,z)
	return UDim2.fromScale((x-minX)/(maxX-minX),(z-minZ)/(maxZ-minZ))
end
local function corner(parent,radius)
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,radius)
	c.Parent=parent
end
local function label(parent,text,position,size,fontSize,tint,bold)
	local t=Instance.new("TextLabel")
	t.Size=size
	t.Position=position
	t.Text=text
	t.TextColor3=tint or TEXT
	t.BackgroundTransparency=1
	t.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
	t.TextSize=fontSize
	t.TextWrapped=true
	t.TextXAlignment=Enum.TextXAlignment.Left
	t.Parent=parent
	return t
end
local function entry(parent,name,center,radius,tint,subtitle,select)
	local land=Instance.new("TextButton")
	land.Name=name:gsub(" ","").."Node"
	land.AnchorPoint=Vector2.new(0.5,0.5)
	land.Position=nodePos(center.X,center.Z)
	land.Size=UDim2.new(radius*2/(maxX-minX),0,radius*2/(maxZ-minZ),0)
	land.Text=""
	land.BackgroundColor3=tint
	land.BackgroundTransparency=0.52
	land.BorderSizePixel=0
	land.AutoButtonColor=true
	land.Parent=parent
	local rim=Instance.new("UICorner")
	rim.CornerRadius=UDim.new(1,0)
	rim.Parent=land
	local stroke=Instance.new("UIStroke")
	stroke.Color=tint
	stroke.Thickness=3
	stroke.Parent=land
	local title=label(land,name..(subtitle and "\n"..subtitle or ""),
		UDim2.fromScale(0,0.34),UDim2.fromScale(1,0.39),14,TEXT,true)
	title.TextXAlignment=Enum.TextXAlignment.Center
	title.TextScaled=true
	land.Activated:Connect(select)
	return land
end
local function bridge(canvas,a,b,tint)
	local u1=(a.X-minX)/(maxX-minX)
	local v1=(a.Z-minZ)/(maxZ-minZ)
	local u2=(b.X-minX)/(maxX-minX)
	local v2=(b.Z-minZ)/(maxZ-minZ)
	local beam=Instance.new("Frame")
	beam.Name="Map Bridge"
	beam.AnchorPoint=Vector2.new(0.5,0.5)
	beam.BackgroundColor3=tint
	beam.BorderSizePixel=0
	beam.Parent=canvas
	local function resize()
		local width=canvas.AbsoluteSize.X
		local height=canvas.AbsoluteSize.Y
		local x1,y1=u1*width,v1*height
		local x2,y2=u2*width,v2*height
		local dx,dy=x2-x1,y2-y1
		beam.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),4)
		beam.Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2)
		beam.Rotation=math.deg(math.atan2(dy,dx))
	end
	canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
end

function Map.Init(player,gui)
	local toggle=Instance.new("TextButton")
	toggle.Name="WorldMapButton"
	toggle.Position=UDim2.new(0.5,-68,0,88)
	toggle.Size=UDim2.fromOffset(136,31)
	toggle.BackgroundColor3=Color3.fromRGB(39,49,81)
	toggle.TextColor3=SAFE
	toggle.Font=Enum.Font.GothamBold
	toggle.TextSize=13
	toggle.Text="WORLD MAP [N]"
	toggle.Parent=gui
	corner(toggle,4)
	Deco.Button(toggle)
	local map=Instance.new("Frame")
	map.Name="RiftboundWorldMap"
	map.AnchorPoint=Vector2.new(0.5,0.5)
	map.Position=UDim2.fromScale(0.5,0.48)
	map.Size=UDim2.new(0.95,0,0,496)
	map.Visible=false
	map.BackgroundColor3=DUSK
	map.BorderSizePixel=0
	map.Parent=gui
	corner(map,5)
	Deco.Panel(map)
	local maxSize=Instance.new("UISizeConstraint")
	maxSize.MaxSize=Vector2.new(720,496)
	maxSize.MinSize=Vector2.new(310,496)
	maxSize.Parent=map
	local outline=Instance.new("UIStroke")
	outline.Thickness=2
	outline.Color=SAFE
	outline.Parent=map
	label(map,"RIFTBOUND / WORLD MAP",UDim2.fromOffset(17,9),
		UDim2.new(1,-95,0,34),22,TEXT,true)
	local close=Instance.new("TextButton")
	close.Size=UDim2.fromOffset(42,32)
	close.Position=UDim2.new(1,-54,0,10)
	close.Text="X"
	close.BackgroundColor3=Color3.fromRGB(52,62,92)
	close.TextColor3=TEXT
	close.Font=Enum.Font.GothamBold
	close.Parent=map
	corner(close,5)
	Deco.Button(close)
	close.Activated:Connect(function()map.Visible=false end)
	local subtitle=label(map,"Four islands / four bridges / one shared world",
		UDim2.fromOffset(17,41),UDim2.new(1,-32,0,21),12,MUTE,false)
	local canvas=Instance.new("Frame")
	canvas.Name="IslandMapCanvas"
	canvas.Position=UDim2.fromOffset(14,70)
	canvas.Size=UDim2.new(1,-28,1,-150)
	canvas.BackgroundColor3=SKY
	canvas.BorderSizePixel=0
	canvas.ClipsDescendants=true
	canvas.Parent=map
	corner(canvas,10)
	local grid=Instance.new("UIStroke")
	grid.Color=Deco.Bronze
	grid.Thickness=1.25
	grid.Parent=canvas
	-- Draw bridges before islands, keeping them behind colored island surfaces.
	for _,b in World.Bridges do
		bridge(canvas,b.From,b.To,b.Accent)
	end
	local info=label(map,"Select an island to see its recommended level and enemies.",
		UDim2.new(0,17,1,-74),UDim2.new(1,-34,0,28),13,MUTE,false)
	local function choose(id)
		if id==World.Hub.Id then
			info.Text="HAVEN DISTRICT  •  SAFE  |  Shops planned, training, quest hub, fast travel"
		else
			for _,zone in World.Zones do
				if zone.Id==id then
					info.Text=zone.Name.."  •  LV "..zone.MinLevel.."-"..zone.MaxLevel.."  |  "..zone.Subtitle
					break
				end
			end
		end
	end
	entry(canvas,World.Hub.Name,World.Hub.Center,World.Hub.Radius,SAFE,
		"SAFE HUB",function()choose(World.Hub.Id)end)
	for _,zone in World.Zones do
		entry(canvas,zone.Name,zone.Center,zone.Radius,zone.Color,
			"LV "..zone.MinLevel.."-"..zone.MaxLevel,function()choose(zone.Id)end)
	end
	local marker=Instance.new("Frame")
	marker.Name="YOUR POSITION"
	marker.AnchorPoint=Vector2.new(0.5,0.5)
	marker.Size=UDim2.fromOffset(13,13)
	marker.Position=nodePos(0,0)
	marker.BackgroundColor3=Deco.PaleGold
	marker.BorderSizePixel=0
	marker.ZIndex=4
	marker.Parent=canvas
	local dot=Instance.new("UICorner")
	dot.CornerRadius=UDim.new(1,0)
	dot.Parent=marker
	local markerEdge=Instance.new("UIStroke")
	markerEdge.Color=Color3.new(1,1,1)
	markerEdge.Thickness=2
	markerEdge.Parent=marker
	label(map,"GOLD DOT = YOU   •   [N] OPEN/CLOSE   •   E = FAST TRAVEL AT PORTALS",
		UDim2.new(0,17,1,-39),UDim2.new(1,-34,0,21),11,MUTE,false)
	local function toggleMap()
		map.Visible=not map.Visible
	end
	toggle.Activated:Connect(toggleMap)
	ContextActionService:BindAction("RiftMapView",function(_,state)
		if state==Enum.UserInputState.Begin then toggleMap() end
		return Enum.ContextActionResult.Pass
	end,false,Enum.KeyCode.N)
	task.spawn(function()
		while gui.Parent do
			local world=workspace:FindFirstChild(World.WorldName)
			local char=player.Character
			local root=char and char:FindFirstChild("HumanoidRootPart")
			if root and world then
				local x=root.Position.X-(world:GetAttribute("SpawnX") or 0)
				local z=root.Position.Z-(world:GetAttribute("SpawnZ") or 0)
				marker.Position=nodePos(x,z)
				marker.Visible=x>=minX and x<=maxX and z>=minZ and z<=maxZ
			end
			task.wait(0.3)
		end
	end)
end
return Map
