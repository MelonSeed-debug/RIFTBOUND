--!strict
-- RIFTBOUND Open World 1.0: one contiguous overworld, no portals between zones.
-- All positions are LOCAL offsets from SpawnX / SpawnZ in the generated world.
-- This file is pure tuning/data. Never use it to grant XP or trust client hits.
local World = {
	WorldName = "RIFTBOUND World",
	Version = 4,
	Mode = "OpenWorld",
	PracticeMode = true, -- legacy grinding/story quests stay paused
	GenerateIfMissing = true,
	FieldSize = 2400,
	GrassColor = Color3.fromRGB(86, 137, 88),
	Seed = 18427,
	SafeRadius = 122,

	-- Only build world geometry + generic enemies this milestone.
	-- Old dialogue/story modules and saved quest data remain in the repo.
	EnableStoryActors = false,
	EnableQuestStations = false,
	EnableWorldEnemies = true,

	-- Used by the retained solo-combat test dummy, clear of the main road.
	TrainingDummy = Vector3.new(25, 0, -36),
	QuestStations = {
		Archivist = Vector3.new(-23, 0, -24),
		VoidTrial = Vector3.new(40, 0, -43),
	},

	Hub = {
		Id = "Haven",
		Name = "HAVEN",
		Center = Vector3.zero,
		SafeRadius = 122,
		MinLevel = 1, MaxLevel = 50,
	},

	-- Circle-shaped region footprints painted on a continuous physical floor.
	-- Recommended levels guide danger, not hard-gated map movement.
	Zones = {
		{
			Id = "WhisperingWoods", Name = "WHISPERING WOODS",
			Center = Vector3.new(-485, 0, -205), Radius = 360,
			RecommendedLevel = 1, MinLevel = 1, MaxLevel = 10,
			Color = Color3.fromRGB(62, 113, 79),
			Accent = Color3.fromRGB(145, 211, 126),
			Theme = "Forest", PropCount = 30,
		},
		{
			Id = "Cinderfall", Name = "CINDERFALL",
			Center = Vector3.new(510, 0, -225), Radius = 350,
			RecommendedLevel = 12, MinLevel = 10, MaxLevel = 22,
			Color = Color3.fromRGB(122, 91, 75),
			Accent = Color3.fromRGB(251, 149, 83),
			Theme = "Ash", PropCount = 26,
		},
		{
			Id = "HighlandRidge", Name = "HIGHLAND RIDGE",
			Center = Vector3.new(-490, 0, 525), Radius = 370,
			RecommendedLevel = 23, MinLevel = 20, MaxLevel = 35,
			Color = Color3.fromRGB(116, 143, 119),
			Accent = Color3.fromRGB(187, 211, 197),
			Theme = "Highlands", PropCount = 27,
		},
		{
			Id = "ShatteredVerge", Name = "SHATTERED VERGE",
			Center = Vector3.new(520, 0, 550), Radius = 375,
			RecommendedLevel = 36, MinLevel = 35, MaxLevel = 50,
			Color = Color3.fromRGB(80, 68, 111),
			Accent = Color3.fromRGB(179, 126, 244),
			Theme = "Rift", PropCount = 31,
		},
	},

	-- Entirely walkable roads: each named entry starts at Haven and ends in
	-- a region. The two northern routes connect around Haven's west/east rim.
	Roads = {
		{
			Id = "WoodlandPath", Width = 21,
			Points = {Vector3.new(-36,0,-25),Vector3.new(-185,0,-90),Vector3.new(-480,0,-185)},
		},
		{
			Id = "EmberRoad", Width = 23,
			Points = {Vector3.new(40,0,-25),Vector3.new(218,0,-110),Vector3.new(512,0,-220)},
		},
		{
			Id = "RidgeTrail", Width = 21,
			Points = {Vector3.new(-33,0,40),Vector3.new(-205,0,205),Vector3.new(-500,0,495)},
		},
		{
			Id = "VergeCauseway", Width = 24,
			Points = {Vector3.new(39,0,44),Vector3.new(215,0,220),Vector3.new(525,0,520)},
		},
		-- Mid-world cross-country links reinforce the connected-overworld feel.
		{
			Id = "SouthernTraverse", Width = 17,
			Points = {Vector3.new(-468,0,-205),Vector3.new(0,0,-315),Vector3.new(508,0,-220)},
		},
		{
			Id = "NorthernTraverse", Width = 18,
			Points = {Vector3.new(-490,0,510),Vector3.new(0,0,700),Vector3.new(520,0,550)},
		},
	},

	-- Architecture/arena foundations only. No named bosses spawn yet.
	BossSites = {
		{Id="AshCrater", Name="ASH CRATER", Zone="Cinderfall",
			Position=Vector3.new(715,0,-265), Radius=51},
		{Id="SkyholdCircle", Name="SKYHOLD CIRCLE", Zone="HighlandRidge",
			Position=Vector3.new(-550,0,765), Radius=53},
		{Id="RiftSanctum", Name="RIFT SANCTUM", Zone="ShatteredVerge",
			Position=Vector3.new(740,0,735), Radius=58},
	},

	-- Fixed spawn points, not limitless patrol farming. NPCs only look for
	-- players nearby, obey home leash, and have server-owned damage.
	EnemySpawns = {
		{Name="Rootbound Scout", Id="WhisperingWoods",
			Offset=Vector3.new(-545,0,-185), Color=Color3.fromRGB(104,171,93),
			GuardChance=0.08, Health=130, Damage=8, Cooldown=2.1,
			WalkSpeed=15, RecommendedLevel=2, Archetype="Skirmisher"},
		{Name="Rootbound Scout", Id="WhisperingWoods",
			Offset=Vector3.new(-630,0,-295), Color=Color3.fromRGB(104,171,93),
			GuardChance=0.08, Health=130, Damage=8, Cooldown=2.1,
			WalkSpeed=15, RecommendedLevel=2, Archetype="Skirmisher"},
		{Name="Thornback Guardian", Id="WhisperingWoods",
			Offset=Vector3.new(-375,0,-315), Color=Color3.fromRGB(88,135,84),
			GuardChance=0.55, Health=235, Damage=13, Cooldown=2.8,
			WalkSpeed=10, RecommendedLevel=8, Archetype="Guardian"},
		{Name="Cinder Strider", Id="Cinderfall",
			Offset=Vector3.new(425,0,-255), Color=Color3.fromRGB(219,114,77),
			GuardChance=0.13, Health=265, Damage=15, Cooldown=1.9,
			WalkSpeed=16, RecommendedLevel=12, Archetype="Skirmisher"},
		{Name="Cinder Strider", Id="Cinderfall",
			Offset=Vector3.new(610,0,-120), Color=Color3.fromRGB(219,114,77),
			GuardChance=0.13, Health=265, Damage=15, Cooldown=1.9,
			WalkSpeed=16, RecommendedLevel=12, Archetype="Skirmisher"},
		{Name="Ashforged Bulwark", Id="Cinderfall",
			Offset=Vector3.new(585,0,-355), Color=Color3.fromRGB(157,82,61),
			GuardChance=0.62, Health=430, Damage=23, Cooldown=2.9,
			WalkSpeed=10, RecommendedLevel=19, Archetype="Guardian"},
		{Name="Stonewatch Sentinel", Id="HighlandRidge",
			Offset=Vector3.new(-380,0,530), Color=Color3.fromRGB(163,178,164),
			GuardChance=0.60, Health=485, Damage=26, Cooldown=2.6,
			WalkSpeed=10, RecommendedLevel=24, Archetype="Guardian"},
		{Name="Stonewatch Sentinel", Id="HighlandRidge",
			Offset=Vector3.new(-620,0,420), Color=Color3.fromRGB(163,178,164),
			GuardChance=0.60, Health=485, Damage=26, Cooldown=2.6,
			WalkSpeed=10, RecommendedLevel=24, Archetype="Guardian"},
		{Name="Gale Hunter", Id="HighlandRidge",
			Offset=Vector3.new(-390,0,675), Color=Color3.fromRGB(164,202,210),
			GuardChance=0.08, Health=370, Damage=24, Cooldown=1.7,
			WalkSpeed=17, RecommendedLevel=29, Archetype="Skirmisher"},
		{Name="Riftstalker", Id="ShatteredVerge",
			Offset=Vector3.new(430,0,510), Color=Color3.fromRGB(176,91,232),
			GuardChance=0.20, Health=610, Damage=33, Cooldown=1.8,
			WalkSpeed=16, RecommendedLevel=36, Archetype="Skirmisher"},
		{Name="Riftstalker", Id="ShatteredVerge",
			Offset=Vector3.new(595,0,660), Color=Color3.fromRGB(176,91,232),
			GuardChance=0.20, Health=610, Damage=33, Cooldown=1.8,
			WalkSpeed=16, RecommendedLevel=36, Archetype="Skirmisher"},
		{Name="Voidbound Knight", Id="ShatteredVerge",
			Offset=Vector3.new(620,0,430), Color=Color3.fromRGB(133,82,181),
			GuardChance=0.68, Health=850, Damage=41, Cooldown=2.5,
			WalkSpeed=11, RecommendedLevel=44, Archetype="Guardian"},
	},

	Travel = {}, -- no portal/teleport links for the overworld
	Bridges = {},
}

-- Return region and safe-area status based on real world-relative position.
-- "Wilderness" is intentional between painted biomes: travel is contiguous.
function World.GetZoneAt(localPosition)
	local flat = Vector3.new(localPosition.X, 0, localPosition.Z)
	if (flat - World.Hub.Center).Magnitude <= World.SafeRadius then
		return World.Hub.Id, true
	end
	local nearestId, nearestDist
	for _, zone in World.Zones do
		local d = (flat - zone.Center).Magnitude
		if d <= zone.Radius and (not nearestDist or d < nearestDist) then
			nearestId, nearestDist = zone.Id, d
		end
	end
	return nearestId or "Wilderness", false
end

function World.ZoneById(id)
	for _, zone in World.Zones do
		if zone.Id == id then return zone end
	end
	return nil
end

return World
