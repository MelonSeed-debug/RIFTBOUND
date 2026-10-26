--!strict
-- All blockout geography is relative to the experience's existing SpawnLocation.
-- X and Z offsets are shared by the world builder, quest stations, NPC spawns and HUD.
return {
	WorldName = "RIFTBOUND World",
	Version = 1,
	StudioOnly = true, -- Avoid overriding a future published/hand-built map.
	Hub = {
		Id = "Haven",
		Name = "HAVEN DISTRICT",
		Subtitle = "Safe hub / quests / future shops",
		MinLevel = 1,
		MaxLevel = 50,
		StartZ = -40,
		EndZ = 66,
		HalfWidth = 72,
	},
	Zones = {
		{
			Id = "OldQuarter",
			Name = "OLD QUARTER",
			Subtitle = "Lantern Streets / street fighters",
			MinLevel = 1, MaxLevel = 10,
			StartZ = -150, EndZ = -40,
			Color = Color3.fromRGB(255, 155, 94),
		},
		{
			Id = "Ironworks",
			Name = "IRONWORKS",
			Subtitle = "Foundries / raiders / Rift Sentinel",
			MinLevel = 10, MaxLevel = 25,
			StartZ = -280, EndZ = -150,
			Color = Color3.fromRGB(89, 202, 231),
		},
		{
			Id = "RiftExpanse",
			Name = "RIFT EXPANSE",
			Subtitle = "Rift creatures / endgame territory",
			MinLevel = 25, MaxLevel = 50,
			StartZ = -450, EndZ = -280,
			Color = Color3.fromRGB(187, 107, 255),
		},
	},
	QuestStations = {
		Archivist = Vector3.new(-18, 0, 12),
		VoidTrial = Vector3.new(32, 0, -237),
	},
	EnemySpawns = {
		{ Name="Street Brawler", Id="OldQuarter", Offset=Vector3.new(-13,0,-79),
			Health=160, Damage=9, GuardChance=0.13, WalkSpeed=12, Color=Color3.fromRGB(234,112,86), RecommendedLevel=1 },
		{ Name="Street Guard", Id="OldQuarter", Offset=Vector3.new(16,0,-119),
			Health=200, Damage=10, GuardChance=0.58, WalkSpeed=12, Color=Color3.fromRGB(90,167,246), RecommendedLevel=3 },
		{ Name="Scrap Enforcer", Id="Ironworks", Offset=Vector3.new(-17,0,-190),
			Health=290, Damage=14, GuardChance=0.34, WalkSpeed=12, Color=Color3.fromRGB(223,136,80), RecommendedLevel=10 },
		{ Name="Forge Marauder", Id="Ironworks", Offset=Vector3.new(17,0,-220),
			Health=360, Damage=17, GuardChance=0.29, WalkSpeed=13, Color=Color3.fromRGB(202,74,72), RecommendedLevel=16 },
		{ Name="Rift Sentinel", Id="Ironworks", Offset=Vector3.new(0,0,-256),
			Health=450, Damage=17, GuardChance=0.38, WalkSpeed=13, Cooldown=1.65,
			Color=Color3.fromRGB(157,79,242), RecommendedLevel=10 },
		{ Name="Rift Stalker", Id="RiftExpanse", Offset=Vector3.new(-17,0,-348),
			Health=630, Damage=23, GuardChance=0.22, WalkSpeed=16, Color=Color3.fromRGB(150,76,209), RecommendedLevel=25 },
		{ Name="Void Ravager", Id="RiftExpanse", Offset=Vector3.new(18,0,-401),
			Health=920, Damage=32, GuardChance=0.46, WalkSpeed=14, Cooldown=1.7,
			Color=Color3.fromRGB(233,65,189), RecommendedLevel=40 },
	},
	-- Fast travel only skips the walk; players may still explore physically.
	Travel = {
		{ Id="OldQuarter", Name="OLD QUARTER", Destination=Vector3.new(0,0,-53), RequiredLevel=1 },
		{ Id="Ironworks", Name="IRONWORKS", Destination=Vector3.new(0,0,-164), RequiredLevel=10 },
		{ Id="RiftExpanse", Name="RIFT EXPANSE", Destination=Vector3.new(0,0,-295), RequiredLevel=25 },
	},
}
