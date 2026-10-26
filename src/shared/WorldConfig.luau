--!strict
-- RIFTBOUND Practice Field v3.
-- Temporary world while the full game's direction moves away from bandit grinding.
-- All saved progression, Specs, purchases, skill mastery and story quests remain intact.
local World = {
	WorldName = "RIFTBOUND World",
	Version = 3,
	Mode = "PracticeField",
	PracticeMode = true,
	GenerateIfMissing = true,
	FieldSize = 900,
	GrassColor = Color3.fromRGB(95, 158, 74),

	-- Positions are relative to the original SpawnLocation, not world origin.
	TrainingDummy = Vector3.new(0, 0, -22),
	QuestStations = {
		Archivist = Vector3.new(-23, 0, -24),
		-- The Void trial is paused until its one-off boss challenge is redesigned.
		VoidTrial = Vector3.new(40, 0, -43),
	},

	-- No open-world bandit patrols, districts, bridges, or fast-travel pads.
	EnemySpawns = {},
	Travel = {},
	Zones = {},
	Bridges = {},
	Hub = {
		Id = "PracticeField",
		Name = "RIFTBOUND TRAINING FIELD",
		Center = Vector3.zero,
		SafeRadius = 0,
		MinLevel = 1,
		MaxLevel = 50,
	},
}

-- The temporary field is an open PvP/combat test space: it has no safe-radius
-- combat suppression. Permanent duel rules can be added separately later.
function World.GetZoneAt(_localPosition)
	return "PracticeField", false
end

return World
