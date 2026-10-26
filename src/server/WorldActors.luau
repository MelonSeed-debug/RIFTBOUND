--!strict
-- Distinct interactive story NPCs. Prompts are authoritative: the client cannot
-- claim talk objectives merely by sending a RemoteEvent.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local World=require(ReplicatedStorage.Riftbound.Shared.WorldConfig)
local Actors=require(ReplicatedStorage.Riftbound.Shared.DialogueConfig)
local Progression=require(script.Parent.Progression)

local Service={}
local started=false

local function pointFromWorld(offset)
	local generated=Workspace:FindFirstChild(World.WorldName)
	if generated then
		return Vector3.new((generated:GetAttribute("SpawnX") or 0)+offset.X,
			(generated:GetAttribute("GroundY") or 0)+offset.Y,
			(generated:GetAttribute("SpawnZ") or 0)+offset.Z)
	end
	local spawn=Workspace:FindFirstChildWhichIsA("SpawnLocation",true)
	return (spawn and spawn.Position or Vector3.zero)+offset
end

local function piece(model,name,pos,size,tint,shape)
	local p=Instance.new("Part")
	p.Name=name
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=false
	p.Material=Enum.Material.SmoothPlastic
	p.Color=tint
	p.Size=size
	p.Position=pos
	if shape then p.Shape=shape end
	p.Parent=model
	return p
end

local function makeActor(folder,id,info,remote)
	if folder:FindFirstChild(id) then return end
	local location=pointFromWorld(info.Position)
	local model=Instance.new("Model")
	model.Name=id
	model:SetAttribute("DialogueActorId",id)
	local root=piece(model,"HumanoidRootPart",
		location+Vector3.new(0,3,0),Vector3.new(2,5,2),info.Color)
	root.Transparency=1
	local torso=piece(model,"Tailored Coat",location+Vector3.new(0,3,0),
		Vector3.new(2.8,3.1,1.5),Color3.fromRGB(26,26,35))
	piece(model,"Golden Lapel",location+Vector3.new(0,3.5,-0.78),
		Vector3.new(0.22,1.7,0.12),info.Color)
	piece(model,"Golden Lapel",location+Vector3.new(0.4,3.5,-0.78),
		Vector3.new(0.22,1.7,0.12),info.Color)
	for _,side in {-1,1} do
		piece(model,"Sleeve",location+Vector3.new(side*1.68,3,0),
			Vector3.new(0.7,2.8,1.1),Color3.fromRGB(32,32,42))
		piece(model,"Boot",location+Vector3.new(side*0.6,0.8,0),
			Vector3.new(0.85,1.6,1.1),Color3.fromRGB(31,31,42))
	end
	local head=piece(model,"Head",location+Vector3.new(0,5.42,0),
		Vector3.new(1.6,1.6,1.6),Color3.fromRGB(227,199,166),Enum.PartType.Ball)
	for _,side in {-1,1} do
		piece(model,"Glowing Eyes",location+Vector3.new(side*0.34,5.53,-0.73),
			Vector3.new(0.21,0.16,0.14),info.Color)
	end
	local brim=piece(model,"Hat Brim",location+Vector3.new(0,6.14,0),
		Vector3.new(2.4,0.19,2),Color3.fromRGB(27,28,37))
	piece(model,"Hat Crown",location+Vector3.new(0,6.65,0),
		Vector3.new(1.65,0.9,1.55),Color3.fromRGB(27,28,37))
	piece(model,"Hat Gold Band",location+Vector3.new(0,6.4,0),
		Vector3.new(1.69,0.17,1.6),info.Color)
	local billboard=Instance.new("BillboardGui")
	billboard.Name="Actor Nameplate"
	billboard.Size=UDim2.fromOffset(250,67)
	billboard.StudsOffsetWorldSpace=Vector3.new(0,5.2,0)
	billboard.MaxDistance=85
	billboard.AlwaysOnTop=true
	billboard.Parent=root
	local title=Instance.new("TextLabel")
	title.Size=UDim2.fromScale(1,1)
	title.BackgroundTransparency=1
	title.Text=info.Name.."\n"..info.Role
	title.TextColor3=info.Color
	title.TextStrokeTransparency=0.18
	title.Font=Enum.Font.GothamBold
	title.TextScaled=true
	title.Parent=billboard
	local prompt=Instance.new("ProximityPrompt")
	prompt.ActionText="Talk"
	prompt.ObjectText=info.Name
	prompt.KeyboardKeyCode=Enum.KeyCode.E
	prompt.HoldDuration=0.1
	prompt.MaxActivationDistance=11
	prompt.RequiresLineOfSight=false
	prompt.Parent=root
	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("ProgressLoaded")~=true then return end
		Progression.AdvanceObjective(player,"Talk:"..id)
		remote:FireClient(player,"Open",id)
	end)
	model.PrimaryPart=root
	model.Parent=folder
end

function Service.Start()
	if started then return end
	started=true
	local remotes=ReplicatedStorage:WaitForChild("Riftbound"):WaitForChild("Remotes")
	local remote=remotes:FindFirstChild("DialogueFX")
	if not remote then
		remote=Instance.new("RemoteEvent")
		remote.Name="DialogueFX"
		remote.Parent=remotes
	end
	local folder=Workspace:FindFirstChild("RIFTBOUND Story Characters")
	if not folder then
		folder=Instance.new("Folder")
		folder.Name="RIFTBOUND Story Characters"
		folder.Parent=Workspace
	end
	for _,id in Actors.Order do
		local info=Actors.Actors[id]
		if info then
			local ok,err=pcall(makeActor,folder,id,info,remote)
			if not ok then warn("[RIFTBOUND Actors] Failed:",id,err) end
		end
	end
	print("[RIFTBOUND Actors] "..#Actors.Order.." characters are ready for story dialogue.")
end
return Service
