--!strict
-- RIFTBOUND quest board v0.1. Quest IDs never depend on display names.
-- "Any" means any NPC with a reward entry in LevelConfig.Rewards.
return {
	Order = {"FirstSteps", "ShieldWall", "StreetPatrol", "RiftInitiation"},
	Quests = {
		FirstSteps = {
			Name = "First Steps", Description = "Clear two Street Brawlers.",
			RequiredLevel = 1, Target = "Street Brawler", Count = 2,
			XP = 125, Coins = 45, Repeatable = false,
		},
		ShieldWall = {
			Name = "Breaking the Line", Description = "Defeat two Street Guards.",
			RequiredLevel = 3, Target = "Street Guard", Count = 2,
			XP = 220, Coins = 70, Repeatable = false,
		},
		StreetPatrol = {
			Name = "Street Patrol", Description = "Defeat four street enemies of either type.",
			RequiredLevel = 5, Target = "Any", Count = 4,
			XP = 265, Coins = 100, Repeatable = true,
		},
		RiftInitiation = {
			Name = "Rift Initiation", Description = "Defeat eight street enemies to earn the Rift Initiate permit.",
			RequiredLevel = 10, Target = "Any", Count = 8,
			XP = 650, Coins = 220, Repeatable = false,
			Permit = "RiftInitiate",
		},
	},
}
