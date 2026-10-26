--!strict
-- RIFTBOUND quest board v0.1. Quest IDs never depend on display names.
-- "Any" means any NPC with a reward entry in LevelConfig.Rewards.
return {
	Order = {"FirstSteps", "ShieldWall", "StreetPatrol", "RiftInitiation", "VoidTrial",
		"FoundrySweep", "ForgeLockdown", "RiftRecon", "RavagerHunt",
		"FirstSpark", "MarketWhispers", "FoundrySecret", "VeilVoices", "AbyssHeart"},
	Quests = {
		FirstSpark = {
			Name="The First Spark",Description="Speak with Dr. Liora in Haven to learn about supplies.",
			RequiredLevel=1,Target="Talk:DrLiora",Count=1,
			XP=90,Coins=65,Repeatable=false,Category="Story",
		},
		MarketWhispers = {
			Name="Shadows on the Market",Description="Find Kestrel in the Old Quarter night market.",
			RequiredLevel=3,PrerequisiteQuest="FirstSpark",Target="Talk:Kestrel",Count=1,
			XP=220,Coins=90,Repeatable=false,Category="Story",
		},
		FoundrySecret = {
			Name="The Foundry Secret",Description="Question Foreman Brass in Ironworks.",
			RequiredLevel=10,PrerequisiteQuest="MarketWhispers",Target="Talk:ForemanBrass",Count=1,
			XP=470,Coins=155,Repeatable=false,Category="Story",
		},
		VeilVoices = {
			Name="Voices of the Veil",Description="Find Oracle Nyx in the Rift Expanse.",
			RequiredLevel=25,PrerequisiteQuest="FoundrySecret",Target="Talk:OracleNyx",Count=1,
			XP=920,Coins=275,Repeatable=false,Category="Story",
		},
		AbyssHeart = {
			Name="Heart of the Abyss",Description="Defeat the Abyss Warden inside the Rift Citadel dungeon.",
			RequiredLevel=25,PrerequisiteQuest="VeilVoices",Target="Abyss Warden",Count=1,
			XP=2400,Coins=850,Repeatable=false,Category="Story",
		},
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
			Name = "Street Patrol", Description = "Defeat four hostile enemies in any district.",
			RequiredLevel = 5, Target = "Any", Count = 4,
			XP = 265, Coins = 100, Repeatable = true,
		},
		RiftInitiation = {
			Name = "Rift Initiation", Description = "Defeat eight enemies to earn the Rift Initiate permit.",
			RequiredLevel = 10, Target = "Any", Count = 8,
			XP = 650, Coins = 220, Repeatable = false,
			Permit = "RiftInitiate",
		},
		FoundrySweep = {
			Name = "Foundry Sweep",
			Description = "Defeat three Scrap Enforcers in Ironworks.",
			RequiredLevel = 10, Target = "Scrap Enforcer", Count = 3,
			XP = 600, Coins = 165, Repeatable = true,
		},
		ForgeLockdown = {
			Name = "Forge Lockdown",
			Description = "Defeat two Forge Marauders in Ironworks.",
			RequiredLevel = 16, Target = "Forge Marauder", Count = 2,
			XP = 850, Coins = 230, Repeatable = true,
		},
		RiftRecon = {
			Name = "Rift Recon",
			Description = "Defeat three Rift Stalkers in the Rift Expanse.",
			RequiredLevel = 25, Target = "Rift Stalker", Count = 3,
			XP = 1750, Coins = 450, Repeatable = true,
		},
		RavagerHunt = {
			Name = "Ravager Hunt",
			Description = "Defeat two Void Ravagers in the Rift Expanse.",
			RequiredLevel = 40, Target = "Void Ravager", Count = 2,
			XP = 3500, Coins = 900, Repeatable = true,
		},
		VoidTrial = {
			Name = "Trial of the Void",
			Description = "Defeat the Rift Sentinel to unlock Void Disciple.",
			RequiredLevel = 10, RequiredPermit = "RiftInitiate",
			Target = "Rift Sentinel", Count = 1,
			XP = 850, Coins = 275, Repeatable = false,
			UnlockSpec = "VoidDisciple",
		},
	},
}
