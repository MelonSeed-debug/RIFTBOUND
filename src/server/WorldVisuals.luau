--!strict
-- RIFTBOUND concept recreation: hand-authored procedural landmarks and set dressing.
-- All pieces are regular Studio Parts under Workspace/RIFTBOUND World, not image decals.
-- The geometry is intentionally modular so it can be baked and edited later.
local Visuals = {}
local C = {
	stone = Color3.fromRGB(52, 65, 93),
	white = Color3.fromRGB(215, 227, 245),
	slate = Color3.fromRGB(30, 38, 59),
	blue = Color3.fromRGB(92, 189, 255),
	aqua = Color3.fromRGB(76, 231, 235),
	gold = Color3.fromRGB(255, 173, 79),
	orange = Color3.fromRGB(241, 102, 54),
	purple = Color3.fromRGB(164, 75, 255),
	pink = Color3.fromRGB(255, 96, 198),
	green = Color3.fromRGB(91, 222, 137),
}

local function anchor(root, name, p, size, color, material)
	local obj = Instance.new("Part")
	obj.Name = name
	obj.Anchored = true
	obj.Size = size
	obj.Position = p
	obj.TopSurface = Enum.SurfaceType.Smooth
	obj.BottomSurface = Enum.SurfaceType.Smooth
	obj.Color = color
	obj.Material = material or Enum.Material.Concrete
	obj.Parent = root
	return obj
end

function Visuals.Build(api, root)
	local P, piece, glow, sign, walkway, light, group =
		api.P, api.Part, api.Neon, api.Sign, api.Path, api.Light, api.Group
	local function stylizedTower(parent, name, x, z, height, hue)
		local base = piece(parent, name .. " | Facade", P(x,height/2+1,z),
			Vector3.new(14,height,14), C.slate, Enum.Material.Slate)
		piece(parent,name .. " | Cornice",P(x,height+1.7,z),
			Vector3.new(17,2.5,17),C.stone,Enum.Material.Metal)
		glow(parent,name .. " | Spire",P(x,height+7,z),
			Vector3.new(2.8,12,2.8),hue)
		for tier=1,math.max(2,math.floor(height/13)) do
			glow(parent,name.." | Light Band",P(x,height/math.max(2,math.floor(height/13))*tier,z),
				Vector3.new(14.4,0.35,14.4),hue)
		end
		light(base, hue, 24, 1)
		return base
	end
	local function window(parent,name,x,y,z,size,tint)
		return glow(parent,name,P(x,y,z),size,tint)
	end
	local function building(parent,name,x,z,sx,sz,h,tint,accent,labelText,signSide)
		local body = piece(parent,name.." / Building",P(x,h/2+0.7,z),
			Vector3.new(sx,h,sz),tint,Enum.Material.Concrete)
		piece(parent,name.." / Roof",P(x,h+1,z),
			Vector3.new(sx+2,1.6,sz+2),C.slate,Enum.Material.Metal)
		for floor=1,math.min(6,math.floor((h-2)/8)) do
			local yy=4+floor*6
			for i=-1,1 do
				for _, side in {-1,1} do
					window(parent,name.." / Window X",x+side*(sx/2+0.08),yy,
						z+i*sz*0.26,Vector3.new(0.2,2.5,3.1),accent)
					window(parent,name.." / Window Z",x+i*sx*0.26,yy,
						z+side*(sz/2+0.08),Vector3.new(3,2.5,0.2),accent)
				end
			end
		end
		if labelText then
			local side = signSide or 1
			local plate=glow(parent,name.." / Sign",P(x,7,z+side*(sz/2+1)),
				Vector3.new(sx*0.7,2.5,0.4),accent)
			sign(plate,labelText,210,55,C.white)
		end
		return body
	end
	local function lamp(parent,x,z,tint)
		piece(parent,"Lamp Post",P(x,7,z),Vector3.new(0.5,13,0.5),
			C.stone,Enum.Material.Metal)
		local head=glow(parent,"Lamp Halo",P(x,13.7,z),
			Vector3.new(2.3,0.7,2.3),tint)
		light(head,tint,21,1.3)
	end
	local function tree(parent,x,z,scale)
		local trunk=piece(parent,"Haven Tree / Trunk",P(x,3*scale,z),
			Vector3.new(1.8*scale,6*scale,1.8*scale),
			Color3.fromRGB(77,69,64),Enum.Material.Wood)
		trunk.Shape=Enum.PartType.Cylinder
		trunk.CanCollide=false
		for _,offset in {Vector3.new(0,6.1,0),Vector3.new(2.2,7.2,1),Vector3.new(-2.0,7.2,-1)} do
			local crown=piece(parent,"Haven Tree / Crown",
				P(x+offset.X*scale,offset.Y*scale,z+offset.Z*scale),
				Vector3.new(9*scale,7*scale,9*scale),
				Color3.fromRGB(58,136,104),Enum.Material.Grass)
			crown.Shape=Enum.PartType.Ball
			crown.CanCollide=false
		end
	end
	local function arch(parent,name,x,z,width,h,accent)
		for _, side in {-1,1} do
			piece(parent,name.." / Column",P(x+side*width/2,h/2,z),
				Vector3.new(2.4,h,2.4),C.stone,Enum.Material.Metal)
			glow(parent,name.." / Column Strip",P(x+side*width/2,h/2,z-1.3),
				Vector3.new(0.6,h*0.76,0.26),accent)
		end
		local lintel=piece(parent,name.." / Header",P(x,h,z),
			Vector3.new(width+4,3,3.4),C.slate,Enum.Material.Metal)
		glow(parent,name.." / Header Glow",P(x,h-1.3,z-1.8),
			Vector3.new(width+1,0.35,0.3),accent)
		return lintel
	end
	local function cylinder(parent,name,x,y,z,radius,height,tint,material)
		local p=piece(parent,name,P(x,y,z),
			Vector3.new(height,radius*2,radius*2),tint,material)
		p.Shape=Enum.PartType.Cylinder
		p.CFrame=p.CFrame*CFrame.Angles(0,0,math.rad(90))
		return p
	end

	-- HAVEN: blue-and-white floating sanctuary, ring plaza and central nexus spire.
	local haven = group(root,"01 HAVEN DISTRICT / SAFE HUB")
	cylinder(haven,"Central Nexus Ring",0,0.88,31,47,0.45,
		Color3.fromRGB(79,108,158),Enum.Material.Marble)
	cylinder(haven,"Central Nexus Inner",0,1.15,31,37,0.5,
		Color3.fromRGB(41,63,109),Enum.Material.Slate)
	cylinder(haven,"Crystal Spire Base",0,3,31,10,4,
		C.white,Enum.Material.Marble)
	cylinder(haven,"Nexus Core",0,8.5,31,5,8,C.blue,Enum.Material.Neon)
	local central=glow(haven,"Nexus Heart",P(0,22,31),
		Vector3.new(7,24,7),C.aqua)
	central.Shape=Enum.PartType.Ball
	light(central,C.blue,55,3)
	for _,dir in {Vector2.new(1,0),Vector2.new(-1,0),Vector2.new(0,1),Vector2.new(0,-1)} do
		local theta=math.atan2(dir.Y,dir.X)
		local a=Vector2.new(math.cos(theta),math.sin(theta))
		local pillarX=a.X*16
		local pillarZ=31+a.Y*16
		stylizedTower(haven,"Spire Satellite",pillarX,pillarZ,19,C.blue)
	end
	local spireTip=glow(haven,"Nexus Obelisk Tip",P(0,48,31),
		Vector3.new(3,35,3),C.blue)
	light(spireTip,C.aqua,60,2.1)
	sign(spireTip,"HAVEN DISTRICT\nSAFE ZONE",360,76,C.blue)
	for index=0,13 do
		local t=math.pi*2*index/14
		local x=math.cos(t)*47
		local z=31+math.sin(t)*47
		local pl=glow(haven,"Nexus Perimeter Lamp",P(x,1.35,z),
			Vector3.new(2.5,0.28,2.5),C.blue)
		light(pl,C.blue,11,0.65)
	end
	walkway(haven,"City To Nexus",Vector3.new(0,0,-22),Vector3.new(0,0,-2),17,C.white)
	walkway(haven,"City Cross Avenue",Vector3.new(-91,0,-26),Vector3.new(91,0,-26),12,C.white)
	for _,side in {-1,1} do
		for _,z in {-42,-6} do
			building(haven,"Haven Terrace "..side.." "..z,side*76,z,
				20,22,side<0 and 22 or 26,
				Color3.fromRGB(57,73,105),side<0 and C.blue or C.aqua,
				z==-6 and (side<0 and "GEAR DEPOT\nCOMING SOON" or "APOTHECARY\nCOMING SOON") or nil,1)
		end
		for _,z in {-65,0,64} do
			lamp(haven,side*56,z,C.blue)
		end
		for _,z in {-58,9,74} do
			tree(haven,side*65,z,0.8)
		end
		stylizedTower(haven,"City Tower "..side,side*49,79,34,C.blue)
	end
	local trainer=piece(haven,"Training Ground Plaza",P(-48,0.9,48),
		Vector3.new(28,0.5,33),
		Color3.fromRGB(46,56,76),Enum.Material.Concrete)
	sign(trainer,"TRAINING GROUNDS",240,50,C.white)
	local questMark=glow(haven,"Quest House Landmark",P(-30,11,31),
		Vector3.new(1,13,1),C.gold)
	questMark.CanCollide=false
	sign(questMark,"QUEST HUB",185,43,C.gold)
	local havenGate=arch(haven,"Haven Gate",0,-82,39,19,C.blue)
	sign(havenGate,"HAVEN DISTRICT",310,59,C.blue)

	-- OLD QUARTER: cramped luminous city, shop fronts, alleys, and upper skyline.
	local old=group(root,"02 OLD QUARTER / LV 1-10")
	local oldCenter=Vector3.new(-215,0,-175)
	walkway(old,"Market Main Street",Vector3.new(-218,0,-280),Vector3.new(-218,0,-80),18,C.green)
	walkway(old,"Market Cross Street",Vector3.new(-309,0,-177),Vector3.new(-124,0,-177),15,C.gold)
	walkway(old,"Lantern Alley",Vector3.new(-298,0,-223),Vector3.new(-131,0,-223),9,C.pink)
	for _,side in {-1,1} do
		for i,z in {-257,-222,-134,-99} do
			local x=oldCenter.X+side*54
			local heights={26,33,23,39}
			local h=heights[i]
			local tint=(i%2==0) and Color3.fromRGB(63,67,85) or Color3.fromRGB(77,68,87)
			local neonTint=(i%2==0) and C.pink or C.green
			building(old,"Quarter Row "..side.." "..i,x,z,24,22,h,tint,
				neonTint,i==3 and (side==-1 and "NOODLES" or "BLACK MARKET") or nil,-1)
		end
		for _,z in {-250,-201,-149,-111} do lamp(old,-215+side*22,z,C.pink) end
	end
	for _,p in {Vector2.new(-299,-157),Vector2.new(-126,-148),Vector2.new(-280,-271),
		Vector2.new(-151,-278)} do
		stylizedTower(old,"Old Quarter Watchtower",p.X,p.Y,44,C.green)
	end
	local marketStall=piece(old,"Market Canopy",P(-262,8,-180),
		Vector3.new(24,1,15),Color3.fromRGB(150,57,114),Enum.Material.Fabric)
	sign(marketStall,"NIGHT MARKET\nFUTURE VENDORS",235,53,C.pink)
	for _,side in {-1,1} do
		glow(old,"Floating Neon Banner",P(-215+side*28,11,-172),
			Vector3.new(1,14,5),side==-1 and C.green or C.pink)
	end
	local oldGate=arch(old,"Market Gate",-215,-91,29,18,C.green)
	sign(oldGate,"OLD QUARTER\nLEVEL 1-10",290,72,C.green)

	-- IRONWORKS: furnaces, gantries, foundries and a real accessible arena.
	local iron=group(root,"03 IRONWORKS / LV 10-25")
	walkway(iron,"Iron Road",Vector3.new(136,0,-141),Vector3.new(225,0,-186),22,C.orange)
	walkway(iron,"Foundry Boulevard",Vector3.new(165,0,-190),Vector3.new(298,0,-190),19,C.orange)
	walkway(iron,"Sentinel Approach",Vector3.new(225,0,-187),Vector3.new(228,0,-237),20,C.orange)
	for _,b in {
		{160,-183,24,28,50},
		{295,-174,25,30,59},
		{171,-247,25,26,43},
		{290,-242,26,26,46},
	} do
		local x,z,sx,sz,h=table.unpack(b)
		local factory=building(iron,"Ironworks Furnace",x,z,sx,sz,h,
			Color3.fromRGB(74,73,72),C.orange,nil,nil)
		for _,offset in {-6,6} do
			local stack=piece(iron,"Smoke Stack",P(x+offset,h+15,z),
				Vector3.new(5,30,5),
				Color3.fromRGB(68,65,68),Enum.Material.Metal)
			stack.Shape=Enum.PartType.Cylinder
			local flame=glow(iron,"Furnace Ember",P(x+offset,h+31,z),
				Vector3.new(5,2,5),C.orange)
			light(flame,C.orange,35,1.4)
		end
	end
	for _,side in {-1,1} do
		for _,z in {-145,-215,-259} do lamp(iron,225+side*41,z,C.orange) end
	end
	for i=0,5 do
		local x=175+(i%3)*46
		local z=-126+math.floor(i/3)*11
		piece(iron,"Freight Container",P(x,4,z),Vector3.new(13,7,7),
			i%2==0 and Color3.fromRGB(145,80,62) or Color3.fromRGB(87,94,106),
			Enum.Material.Metal)
	end
	-- Industrial cranes are static silhouettes, avoiding obstructed NPC navmesh.
	for _,x in {145,306} do
		local z=-215
		piece(iron,"Crane Mast",P(x,30,z),Vector3.new(4,60,4),
			C.stone,Enum.Material.Metal)
		local arm=piece(iron,"Crane Arm",P(x+22,59,z),
			Vector3.new(48,2,3),C.gold,Enum.Material.Metal)
		piece(iron,"Crane Cable",P(x+37,40,z),Vector3.new(0.45,35,0.45),
			C.stone,Enum.Material.Metal)
		glow(iron,"Crane Warning Light",P(x,61,z),
			Vector3.new(2,2,2),C.orange)
	end
	-- Full open arena floor has a 66-stud diameter for Sentinel movement.
	cylinder(iron,"RIFT SENTINEL / ARENA",228,0.9,-236,40,0.5,
		Color3.fromRGB(87,53,56),Enum.Material.Slate)
	cylinder(iron,"Arena Combat Floor",228,1.22,-236,33,0.3,
		Color3.fromRGB(67,50,64),Enum.Material.Concrete)
	for i=0,11 do
		local theta=math.pi*2*i/12
		local x=228+math.cos(theta)*39
		local z=-236+math.sin(theta)*39
		local obelisk=piece(iron,"Arena Pylon",P(x,6.0,z),
			Vector3.new(2.4,11,2.4),C.slate,Enum.Material.Metal)
		glow(iron,"Arena Ember",P(x,12,z),
			Vector3.new(2.5,2.5,2.5),C.orange)
	end
	local bossSign=glow(iron,"Rift Sentinel Landmark",P(228,29,-260),
		Vector3.new(2.4,9,2.4),C.orange)
	bossSign.CanCollide=false
	sign(bossSign,"RIFT SENTINEL\nBOSS ARENA",330,68,C.orange)
	local trialSign=glow(iron,"Void Trial Banner",P(192,8,-229),
		Vector3.new(1.5,12,1.5),C.purple)
	sign(trialSign,"VOID TRIAL ALTAR",260,54,C.purple)
	local ironGate=arch(iron,"Foundry Gate",171,-134,34,19,C.orange)
	sign(ironGate,"IRONWORKS\nLEVEL 10-25",305,70,C.orange)

	-- RIFT EXPANSE: corrupted basalt, floating shards and a ruined abyss citadel.
	local rift=group(root,"04 RIFT EXPANSE / LV 25-50")
	walkway(rift,"Rift Wasteland Path",Vector3.new(333,0,-309),
		Vector3.new(383,0,-380),18,C.purple)
	walkway(rift,"Rift Citadel Path",Vector3.new(383,0,-380),
		Vector3.new(440,0,-471),17,C.purple)
	local rng=Random.new(90281)
	for index=1,49 do
		local theta=(index / 49) * math.pi*2
		local dist=rng:NextNumber(57,128)
		local x=390+math.cos(theta)*dist
		local z=-400+math.sin(theta)*dist
		local radius=rng:NextNumber(2.5,6.5)
		local h=rng:NextNumber(8,21)
		local crystal=glow(rift,"Rift Crystal Cluster",P(x,h/2+0.8,z),
			Vector3.new(radius,h,radius),
			index%4==0 and C.pink or C.purple)
		crystal.CFrame=crystal.CFrame*CFrame.Angles(math.rad(rng:NextNumber(-16,16)),
			0,math.rad(rng:NextNumber(-20,20)))
		light(crystal,crystal.Color,15,0.85)
	end
	for i=1,16 do
		local theta=math.pi*2*i/16
		local x=390+math.cos(theta)*rng:NextNumber(54,133)
		local z=-400+math.sin(theta)*rng:NextNumber(54,133)
		local boulder=piece(rift,"Floating Rift Rock",P(x,rng:NextNumber(29,70),z),
			Vector3.new(rng:NextNumber(8,18),rng:NextNumber(8,17),rng:NextNumber(10,20)),
			Color3.fromRGB(55,43,77),Enum.Material.Slate)
		boulder.Shape=Enum.PartType.Ball
		boulder.CanCollide=false
	end
	for _,d in {
		{424,-478,43},{454,-478,69},{478,-474,38},
		{440,-514,47},{475,-519,58},
	} do
		stylizedTower(rift,"Abyss Citadel Tower",d[1],d[2],d[3],C.purple)
	end
	local citadelGate=arch(rift,"Ruined Citadel Entrance",452,-460,35,25,C.purple)
	sign(citadelGate,"THE ABYSS CITADEL\nEXPLORE AT YOUR RISK",385,68,C.purple)
	local portal=glow(rift,"Abyss Portal",P(452,11,-465),
		Vector3.new(15,18,1),C.purple)
	portal.Transparency=0.43
	portal.CanCollide=false
	light(portal,C.purple,35,2.2)
	sign(portal,"HIDDEN RIFT\nFUTURE DUNGEON",244,55,C.pink)
	local riftGate=arch(rift,"Corruption Gate",348,-326,35,18,C.purple)
	sign(riftGate,"RIFT EXPANSE\nLEVEL 25-50",320,72,C.purple)
end

return Visuals
