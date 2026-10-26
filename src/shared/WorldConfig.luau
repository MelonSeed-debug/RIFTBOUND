--!strict
-- RIFTBOUND World Design v2: four stylized islands connected by bridges.
-- All coordinates are offsets from the existing SpawnLocation.
-- This is a functional, stylized Roblox recreation of the approved concept art,
-- not a pixel-perfect import of the illustration.
local World = {
	WorldName = "RIFTBOUND World",
	Version = 2,
	StudioOnly = false,
	GenerateIfMissing = true,
	HideDefaultBaseplate = true,
	WaterLevel = -12,
	Hub = {
		Id = "Haven",
		Name = "HAVEN DISTRICT",
		Subtitle = "Central plaza / spawn / quest hub / fast travel",
		Center = Vector3.new(0, 0, 0),
		Radius = 105,
		SafeRadius = 95,
		MinLevel = 1, MaxLevel = 50,
	},
	Zones = {
		{
			Id = "OldQuarter",
			Name = "OLD QUARTER",
			Subtitle = "Neon streets / street fighters / black market",
			Center = Vector3.new(-215, 0, -175),
			Radius = 122,
			MinLevel = 1, MaxLevel = 10,
			Color = Color3.fromRGB(76, 230, 151),
		},
		{
			Id = "Ironworks",
			Name = "IRONWORKS",
			Subtitle = "Foundries / scrap yards / Sentinel arena",
			Center = Vector3.new(225, 0, -185),
			Radius = 124,
			MinLevel = 10, MaxLevel = 25,
			Color = Color3.fromRGB(255, 148, 76),
		},
		{
			Id = "RiftExpanse",
			Name = "RIFT EXPANSE",
			Subtitle = "Corrupted wastes / ruins / abyss citadel",
			Center = Vector3.new(390, 0, -400),
			Radius = 139,
			MinLevel = 25, MaxLevel = 50,
			Color = Color3.fromRGB(196, 97, 255),
		},
	},
	Bridges = {
		{ Name = "Haven - Old Quarter", From = Vector3.new(-73, 0, -50),
			To = Vector3.new(-148, 0, -119), Width = 20, Accent = Color3.fromRGB(99, 225, 177) },
		{ Name = "Haven - Ironworks", From = Vector3.new(73, 0, -53),
			To = Vector3.new(152, 0, -123), Width = 22, Accent = Color3.fromRGB(255, 151, 85) },
		{ Name = "Ironworks - Rift Expanse", From = Vector3.new(292, 0, -263),
			To = Vector3.new(333, 0, -312), Width = 20, Accent = Color3.fromRGB(183, 99, 250) },
		{ Name = "Old Quarter - Ironworks Skyway", From = Vector3.new(-145, 0, -235),
			To = Vector3.new(114, 0, -230), Width = 12, Accent = Color3.fromRGB(111, 192, 232) },
	},
	QuestStations = {
		Archivist = Vector3.new(-29, 0, 31),
		VoidTrial = Vector3.new(192, 0, -229),
	},
	TrainingDummy = Vector3.new(-45, 0, 47),
	EnemySpawns = {
		{ Name="Street Brawler", Id="OldQuarter", Offset=Vector3.new(-212,0,-145),
			Health=160, Damage=9, GuardChance=0.13, WalkSpeed=12,
			Color=Color3.fromRGB(234,112,86), RecommendedLevel=1 },
		{ Name="Street Guard", Id="OldQuarter", Offset=Vector3.new(-186,0,-195),
			Health=200, Damage=10, GuardChance=0.58, WalkSpeed=12,
			Color=Color3.fromRGB(90,167,246), RecommendedLevel=3 },
		{ Name="Scrap Enforcer", Id="Ironworks", Offset=Vector3.new(208,0,-159),
			Health=290, Damage=14, GuardChance=0.34, WalkSpeed=12,
			Color=Color3.fromRGB(223,136,80), RecommendedLevel=10 },
		{ Name="Forge Marauder", Id="Ironworks", Offset=Vector3.new(265,0,-179),
			Health=360, Damage=17, GuardChance=0.29, WalkSpeed=13,
			Color=Color3.fromRGB(202,74,72), RecommendedLevel=16 },
		{ Name="Rift Sentinel", Id="Ironworks", Offset=Vector3.new(228,0,-236),
			Health=450, Damage=17, GuardChance=0.38, WalkSpeed=13, Cooldown=1.65,
			Color=Color3.fromRGB(157,79,242), RecommendedLevel=10 },
		{ Name="Rift Stalker", Id="RiftExpanse", Offset=Vector3.new(362,0,-372),
			Health=630, Damage=23, GuardChance=0.22, WalkSpeed=16,
			Color=Color3.fromRGB(150,76,209), RecommendedLevel=25 },
		{ Name="Void Ravager", Id="RiftExpanse", Offset=Vector3.new(424,0,-429),
			Health=920, Damage=32, GuardChance=0.46, WalkSpeed=14, Cooldown=1.7,
			Color=Color3.fromRGB(233,65,189), RecommendedLevel=40 },
	},
	Travel = {
		{ Id="OldQuarter", Name="OLD QUARTER",
			Destination=Vector3.new(-162,0,-135), ReturnPad=Vector3.new(-178,0,-145),
			RequiredLevel=1 },
		{ Id="Ironworks", Name="IRONWORKS",
			Destination=Vector3.new(176,0,-140), ReturnPad=Vector3.new(172,0,-154),
			RequiredLevel=10 },
		{ Id="RiftExpanse", Name="RIFT EXPANSE",
			Destination=Vector3.new(348,0,-334), ReturnPad=Vector3.new(353,0,-349),
			RequiredLevel=25 },
	},
}

function World.GetZoneAt(localPosition)
	local dHub = (Vector2.new(localPosition.X,localPosition.Z)
		- Vector2.new(World.Hub.Center.X,World.Hub.Center.Z)).Magnitude
	if dHub <= World.Hub.SafeRadius then return World.Hub.Id, true end
	for _, zone in World.Zones do
		local dist = (Vector2.new(localPosition.X,localPosition.Z)
			- Vector2.new(zone.Center.X,zone.Center.Z)).Magnitude
		if dist <= zone.Radius then return zone.Id, false end
	end
	return "Causeway", false
end

return World
