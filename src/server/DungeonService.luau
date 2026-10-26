--!strict
-- First functional dungeon: the Abyss Citadel. Shared arena, solo/co-op combat,
-- boss phase hazards, rewards and an exit, all controlled by the server.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local Debris=game:GetService("Debris")
local World=require(ReplicatedStorage.Riftbound.Shared.WorldConfig)
local NPCs=require(script.Parent.CombatNPCs)
local Progression=require(script.Parent.Progression)
local Damage=require(script.Parent.PillShield)

local Service={}
local started=false
local dungeonRoot
local boss=nil
local bossHum=nil
local bossSerial=0
local nextAllowed=0
local specialSpawned=false
local arenaCenter=Vector3.new(1435,0,-235)
local entrance=Vector3.new(1435,0,-175)
local sigilGate=Vector3.new(86,0,-51) -- optional challenge portal near field edge
local rpc
local memberCheck=setmetatable({}, {__mode="k"})

local function loc(offset)
	local world=Workspace:FindFirstChild(World.WorldName)
	if world then
		return Vector3.new((world:GetAttribute("SpawnX") or 0)+offset.X,
			(world:GetAttribute("GroundY") or 0)+offset.Y,
			(world:GetAttribute("SpawnZ") or 0)+offset.Z)
	end
	local spawn=Workspace:FindFirstChildWhichIsA("SpawnLocation",true)
	return (spawn and spawn.Position or Vector3.zero)+offset
end

local function part(folder,name,where,size,tint,material,collide)
	local p=Instance.new("Part")
	p.Name=name p.Anchored=true p.Position=where p.Size=size
	p.Color=tint p.Material=material or Enum.Material.Slate
	p.CanCollide=collide~=false p.CanTouch=false p.CanQuery=collide~=false
	p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
	p.Parent=folder
	return p
end
local function rune(folder,where,diameter,tint,transparency)
	local p=part(folder,"Abyss Rune",where,
		Vector3.new(0.18,diameter,diameter),tint,Enum.Material.Neon,false)
	p.Shape=Enum.PartType.Cylinder
	p.CFrame=p.CFrame*CFrame.Angles(0,0,math.rad(90))
	p.Transparency=transparency or 0.27
	return p
end
local function sign(p,text)
	local b=Instance.new("BillboardGui")
	b.AlwaysOnTop=true
	b.Size=UDim2.fromOffset(320,80)
	b.StudsOffsetWorldSpace=Vector3.new(0,p.Size.Y/2+3,0)
	b.MaxDistance=120
	b.Parent=p
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=Color3.fromRGB(234,192,255)
	label.TextStrokeTransparency=0.17
	label.Font=Enum.Font.GothamBold
	label.TextScaled=true
	label.Parent=b
end
local function prompt(p,title,text,callback)
	local event=p:FindFirstChildOfClass("ProximityPrompt") or Instance.new("ProximityPrompt")
	event.ActionText=text event.ObjectText=title
	event.KeyboardKeyCode=Enum.KeyCode.E
	event.RequiresLineOfSight=false
	event.HoldDuration=0.15
	event.MaxActivationDistance=12
	event.Parent=p
	event.Triggered:Connect(callback)
end
local function send(player,event,message)
	if rpc then rpc:FireClient(player,event,message) end
end
local function teleport(player,at)
	local char=player.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health<=0 then return false end
	local arrival=loc(at)+Vector3.new(0,5,0)
	char:PivotTo(CFrame.lookAt(arrival,arrival+Vector3.new(0,0,-1)))
	root.AssemblyLinearVelocity=Vector3.zero
	return true
end
local function inDungeon(player)
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	return (root.Position-loc(arenaCenter)).Magnitude<93
end

local function pulseHazard(serial,where,radius,damage)
	if not dungeonRoot or serial~=bossSerial then return end
	-- A visible, 1.3 second warning circle before the AoE hits. Server
	-- snapshots positions at impact; standing outside of it dodges damage.
	local warning=rune(dungeonRoot,where+Vector3.new(0,1.9,0),
		radius*2,Color3.fromRGB(250,100,179),0.43)
	warning.Name="Boss Slam Warning"
	Debris:AddItem(warning,1.7)
	for _,plr in Players:GetPlayers() do
		if inDungeon(plr) then send(plr,"Warning","ABYSS SLAM — MOVE!") end
	end
	task.delay(1.3,function()
		if serial~=bossSerial or not bossHum or bossHum.Health<=0 then return end
		if warning.Parent then warning:Destroy() end
		local blast=rune(dungeonRoot,where+Vector3.new(0,2.2,0),
			radius*2,Color3.fromRGB(205,99,255),0.18)
		blast.Name="Boss Slam"
		Debris:AddItem(blast,0.35)
		for _,plr in Players:GetPlayers() do
			local char=plr.Character
			local hum=char and char:FindFirstChildOfClass("Humanoid")
			local root=char and char:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health>0 and root then
				local flat=Vector2.new(root.Position.X-where.X,root.Position.Z-where.Z)
				if flat.Magnitude<=radius then
					Damage.Damage(char,hum,damage)
				end
			end
		end
	end)
end

local function addEcho()
	if specialSpawned or not dungeonRoot then return end
	specialSpawned=true
	local echo=NPCs.SpawnCustom(dungeonRoot,loc(arenaCenter+Vector3.new(-24,0,8)),{
		Name="Abyss Echo",Health=340,AttackDamage=14,AttackCooldown=1.9,
		WalkSpeed=14,GuardChance=0.14,Color=Color3.fromRGB(128,88,216),
		RecommendedLevel=25,
	})
	if echo then
		echo:SetAttribute("DungeonAdd",true)
	end
end

local function spawnBoss()
	if not dungeonRoot or (boss and boss.Parent and bossHum and bossHum.Health>0) then return end
	if os.clock()<nextAllowed then return end
	bossSerial+=1
	local serial=bossSerial
	specialSpawned=false
	boss=NPCs.SpawnCustom(dungeonRoot,loc(arenaCenter),{
		Name="Abyss Warden",Health=1650,AttackDamage=26,AttackCooldown=1.9,
		WalkSpeed=13,GuardChance=0.3,Color=Color3.fromRGB(149,73,235),
		RecommendedLevel=25,
		OnDefeat=function(killer)
			nextAllowed=os.clock()+35
			Progression.RecordAbyssClear(killer)
			-- Guaranteed trophy on clear; random additional loot uses the
			-- existing NPC drop system. This is not duplicated on re-entry.
			Progression.GrantItem(killer,"AbyssSigil",1)
			for _,plr in Players:GetPlayers() do
				if inDungeon(plr) then
					send(plr,"Victory","ABYSS WARDEN DEFEATED — "..killer.DisplayName.." claimed the sigil!")
				end
			end
			for _,instance in dungeonRoot:GetChildren() do
				if instance:IsA("Model") and instance:GetAttribute("DungeonAdd") then
					instance:Destroy()
				end
			end
		end,
	})
	bossHum=boss and boss:FindFirstChildOfClass("Humanoid")
	if not bossHum then
		warn("[RIFTBOUND Dungeon] Failed to create Abyss Warden rig.")
		return
	end
	print("[RIFTBOUND Dungeon] Abyss Warden spawned.")
	task.spawn(function()
		while boss and boss.Parent and bossHum and bossHum.Health>0 and serial==bossSerial do
			local enraged=bossHum.Health<=bossHum.MaxHealth*0.5
			if enraged then addEcho() end
			local target
			local closest=math.huge
			for _,plr in Players:GetPlayers() do
				if inDungeon(plr) then
					local r=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					if r then
						local dist=(r.Position-loc(arenaCenter)).Magnitude
						if dist<closest then closest=dist target=r end
					end
				end
			end
			if target then
				pulseHazard(serial,Vector3.new(target.Position.X,loc(arenaCenter).Y,target.Position.Z),
					enraged and 16 or 12,enraged and 38 or 26)
			end
			task.wait(enraged and 5.8 or 8.5)
		end
	end)
end

local function buildRoom()
	local existing=Workspace:FindFirstChild("RIFTBOUND Abyss Dungeon")
	if existing then dungeonRoot=existing return end
	dungeonRoot=Instance.new("Folder")
	dungeonRoot.Name="RIFTBOUND Abyss Dungeon"
	dungeonRoot.Parent=Workspace
	local base=loc(arenaCenter)
	local stone=Color3.fromRGB(29,24,47)
	local metal=Color3.fromRGB(59,49,78)
	part(dungeonRoot,"Abyss Floor",base+Vector3.new(0,-1.25,0),
		Vector3.new(130,2.5,150),stone)
	for _,wall in {
		{Vector3.new(0,17,-75),Vector3.new(132,35,3)},
		{Vector3.new(0,17,75),Vector3.new(132,35,3)},
		{Vector3.new(65,17,0),Vector3.new(3,35,150)},
		{Vector3.new(-65,17,0),Vector3.new(3,35,150)},
	} do
		part(dungeonRoot,"Blackstone Citadel Wall",base+wall[1],wall[2],metal)
	end
	for index=0,11 do
		local theta=2*math.pi*index/12
		local x=base.X+math.cos(theta)*49
		local z=base.Z+math.sin(theta)*54
		local p=part(dungeonRoot,"Warden Crystal",
			Vector3.new(x,9.5,z),Vector3.new(3,18,3),
			index%2==0 and Color3.fromRGB(171,83,242) or Color3.fromRGB(235,94,195),
			Enum.Material.Neon,false)
		p.CFrame*=CFrame.Angles(0,0,math.rad(10))
	end
	rune(dungeonRoot,base+Vector3.new(0,0.3,0),68,
		Color3.fromRGB(75,45,121),0.65)
	for _,dir in {-1,1} do
		local column=part(dungeonRoot,"Warden Pillar",
			base+Vector3.new(dir*54,12,42),Vector3.new(5,24,5),metal)
		local torch=part(dungeonRoot,"Abyss Flame",
			column.Position+Vector3.new(0,13,0),Vector3.new(4,4,4),
			Color3.fromRGB(208,100,239),Enum.Material.Neon,false)
		local glow=Instance.new("PointLight")
		glow.Color=torch.Color glow.Range=35 glow.Brightness=2
		glow.Parent=torch
	end
	local exit=part(dungeonRoot,"Dungeon Exit",loc(entrance),
		Vector3.new(8,8,3),Color3.fromRGB(102,184,245),Enum.Material.Neon,false)
	sign(exit,"RETURN TO RIFT EXPANSE")
	prompt(exit,"ABYSS CITADEL","Leave Dungeon",function(player)
		if not inDungeon(player) then return end
		if teleport(player,Vector3.new(63,0,-49)) then
			send(player,"Message","Returned to the practice field.")
		end
	end)
end

function Service.Start()
	if started then return end
	started=true
	local remotes=ReplicatedStorage:WaitForChild("Riftbound"):WaitForChild("Remotes")
	rpc=remotes:FindFirstChild("DungeonFX")
	if not rpc then
		rpc=Instance.new("RemoteEvent")
		rpc.Name="DungeonFX"
		rpc.Parent=remotes
	end
	buildRoom()
	local folder=Workspace:FindFirstChild(World.WorldName)
	if not folder then folder=Workspace end
	local gate=part(folder,"ABYSS CITADEL / ENTRY GATE",loc(sigilGate)+Vector3.new(0,5,0),
		Vector3.new(8,11,3),Color3.fromRGB(170,71,238),Enum.Material.Neon,false)
	gate.Transparency=0.4
	sign(gate,"ABYSS CITADEL\nLV 25+ DUNGEON")
	prompt(gate,"ABYSS CITADEL","Enter Dungeon",function(player)
		if (player:GetAttribute("Level") or 1)<25 then
			send(player,"Message","The Abyss Citadel opens at Level 25.")
			return
		end
		if player:GetAttribute("ProgressLoaded")~=true then
			send(player,"Message","Progress is still loading.")
			return
		end
		if teleport(player,entrance) then
			send(player,"Message","ABYSS CITADEL — defeat the Warden and avoid its glowing slam markers.")
			task.delay(0.4,spawnBoss)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		memberCheck[player]=nil
	end)
	print("[RIFTBOUND Dungeon] Abyss Citadel gate, arena and phase boss ready.")
end
return Service
