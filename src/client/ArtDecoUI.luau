--!strict
-- RIFTBOUND visual language, interpreted from the provided Art Deco sprite sheet:
-- black-marble feel, antique gold trims, ivory type, angular corner ornaments.
-- No external ImageId needed. Replace the background with a published Roblox asset
-- later if the original texture sheet is uploaded and given a verified asset ID.
local Theme={}
Theme.Ink=Color3.fromRGB(11,12,16)
Theme.Slate=Color3.fromRGB(27,29,35)
Theme.Paper=Color3.fromRGB(245,235,209)
Theme.Muted=Color3.fromRGB(186,174,146)
Theme.Gold=Color3.fromRGB(212,174,75)
Theme.PaleGold=Color3.fromRGB(249,219,131)
Theme.Bronze=Color3.fromRGB(111,78,32)
Theme.Red=Color3.fromRGB(197,70,66)
Theme.Green=Color3.fromRGB(114,187,125)
Theme.Blue=Color3.fromRGB(91,167,189)

local function stroke(target,weight,tint)
	local old=target:FindFirstChild("RiftDecoBorder")
	if old then return old end
	local line=Instance.new("UIStroke")
	line.Name="RiftDecoBorder"
	line.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	line.Thickness=weight or 1.5
	line.Color=tint or Theme.Gold
	line.Transparency=0.06
	line.Parent=target
	return line
end

local function pin(parent,name,position,size,tint)
	local piece=Instance.new("Frame")
	piece.Name=name
	piece.Position=position
	piece.Size=size
	piece.BackgroundColor3=tint
	piece.BorderSizePixel=0
	piece.Active=false
	piece.Parent=parent
	return piece
end

local function trim(parent)
	-- Slim architectural inlays; intentionally do not cover labels/buttons.
	pin(parent,"Art Deco Top Inlay",UDim2.new(0,12,0,6),
		UDim2.new(1,-24,0,1),Theme.Bronze)
	pin(parent,"Art Deco Bottom Inlay",UDim2.new(0,12,1,-8),
		UDim2.new(1,-24,0,1),Theme.Bronze)
	for _,side in {-1,1} do
		local isLeft=side<0
		local x=isLeft and 8 or -8
		local diamond=pin(parent,"Gold Corner Diamond",
			isLeft and UDim2.new(0,x,0,7) or UDim2.new(1,x,0,7),
			UDim2.fromOffset(7,7),Theme.PaleGold)
		diamond.AnchorPoint=Vector2.new(0.5,0.5)
		diamond.Rotation=45
		local foot=pin(parent,"Bottom Corner Diamond",
			isLeft and UDim2.new(0,x,1,-8) or UDim2.new(1,x,1,-8),
			UDim2.fromOffset(7,7),Theme.Gold)
		foot.AnchorPoint=Vector2.new(0.5,0.5)
		foot.Rotation=45
	end
end

function Theme.Panel(frame)
	-- UIGradient MULTIPLIES the frame's BackgroundColor3. Combining an
	-- almost-black color with a dark gradient makes the panel pitch black.
	-- Use white as the un-tinted base so the gradient displays its real shades.
	frame.BackgroundColor3=Color3.new(1,1,1)
	frame.BackgroundTransparency=0.02
	frame.BorderSizePixel=0
	stroke(frame,1.7,Theme.Gold)
	local grad=frame:FindFirstChild("DecoPanelGradient") or Instance.new("UIGradient")
	grad.Name="DecoPanelGradient"
	grad.Rotation=90
	grad.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromRGB(47,43,42)),
		ColorSequenceKeypoint.new(0.46,Color3.fromRGB(22,24,31)),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(34,30,28)),
	})
	grad.Parent=frame
	if not frame:FindFirstChild("Art Deco Top Inlay") then trim(frame) end
	return frame
end

function Theme.Button(b)
	b.BackgroundColor3=Color3.fromRGB(35,32,29)
	b.TextColor3=Theme.PaleGold
	b.Font=Enum.Font.GothamBold
	b.BorderSizePixel=0
	stroke(b,1.1,Theme.Gold)
	return b
end

function Theme.Heading(text)
	text.TextColor3=Theme.PaleGold
	text.Font=Enum.Font.GothamBold
	text.TextStrokeColor3=Color3.fromRGB(20,13,7)
	text.TextStrokeTransparency=0.7
	return text
end

function Theme.Body(text)
	text.TextColor3=Theme.Paper
	return text
end

function Theme.Progress(track,fill)
	track.BackgroundColor3=Color3.fromRGB(34,31,27)
	stroke(track,1,Theme.Bronze)
	fill.BackgroundColor3=Theme.Gold
	local grad=Instance.new("UIGradient")
	grad.Name="DecoMetalGradient"
	grad.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Theme.Bronze),
		ColorSequenceKeypoint.new(0.45,Theme.PaleGold),
		ColorSequenceKeypoint.new(1,Theme.Gold),
	})
	grad.Parent=fill
end

function Theme.Section(parent,title,y)
	local header=Instance.new("TextLabel")
	header.Name=title
	header.Position=UDim2.new(0,14,0,y)
	header.Size=UDim2.new(1,-28,0,28)
	header.Text=string.upper(title)
	header.BackgroundTransparency=1
	header.TextColor3=Theme.PaleGold
	header.Font=Enum.Font.GothamBold
	header.TextSize=15
	header.TextXAlignment=Enum.TextXAlignment.Left
	header.Parent=parent
	pin(parent,"Divider "..title,UDim2.new(0,14,0,y+28),
		UDim2.new(1,-28,0,1),Theme.Bronze)
	return header
end

function Theme.Card(parent,name,position,size)
	local card=Instance.new("Frame")
	card.Name=name
	card.Position=position
	card.Size=size
	card.BackgroundColor3=Theme.Slate
	card.BackgroundTransparency=0.11
	card.BorderSizePixel=0
	card.Parent=parent
	stroke(card,1,Theme.Bronze)
	return card
end

function Theme.MakeButton(parent,name,caption,position,size)
	local b=Instance.new("TextButton")
	b.Name=name b.Text=caption b.Position=position b.Size=size
	b.TextSize=14 b.AutoButtonColor=true
	b.Parent=parent
	Theme.Button(b)
	return b
end

function Theme.Text(parent,name,caption,position,size,fontSize,accent)
	local t=Instance.new("TextLabel")
	t.Name=name t.Text=caption t.Position=position t.Size=size
	t.TextColor3=accent and Theme.PaleGold or Theme.Paper
	t.BackgroundTransparency=1
	t.Font=accent and Enum.Font.GothamBold or Enum.Font.Gotham
	t.TextSize=fontSize or 14
	t.TextWrapped=true
	t.TextXAlignment=Enum.TextXAlignment.Left
	t.Parent=parent
	return t
end

return Theme
