--!strict
-- RIFTBOUND Spec #3: Abyssal Covenant / Great Sword.
-- Based on the GREAT SWORD set from the user's "150+ Weapon Animations & Models".
-- Combat is server-authoritative; animation clips are strictly cosmetic.
return {
	Id = "GreatSword",
	Name = "Abyssal Covenant",
	Weapon = "GreatSword",
	Role = "Heavy melee / close-range duelist",
	Rig = "R15",
	Passive = {
		Name = "Covenant Edge",
		-- M1/Heavy remain the existing four-hit combo, with extra blade reach
		-- and slower recovery. No auto-passive damage stacking or kill grind.
		M1Damage = {9, 10, 11, 16},
		M1Range = 9,
		M1Width = 7,
		M1HitCooldown = 0.49,
		M1FinisherCooldown = 0.92,
		M1Windup = 0.24,
		M1Recovery = 0.44,
		HeavyDamage = 27,
		HeavyRange = 10,
		HeavyWidth = 8,
		HeavyCooldown = 2.20,
		HeavyWindup = 0.55,
		HeavyRecovery = 1.56,
	},
	Abilities = {
		Z = {
			Name = "Covenant Guard",
			Cooldown = 14,
			Duration = 3,
			DamageMultiplier = 0.55, -- 45% reduction during guard
		},
		X = {
			Name = "Rending Lunge",
			Cooldown = 9,
			Damage = 19,
			Range = 12,
			Width = 8,
			Windup = 0.16,
			Travel = 7,
		},
		C = {
			Name = "Titan Uplift",
			Cooldown = 13,
			Damage = 24,
			Range = 11,
			Width = 10,
			Windup = 0.26,
			Launch = 36,
		},
		V = {
			Name = "Falling Covenant",
			Cooldown = 19,
			Damage = 31,
			Radius = 12,
			Windup = 0.42,
			Knockback = 30,
		},
		G = {
			Name = "Abyssal Execution",
			Cooldown = 58,
			Damage = 48,
			Range = 16,
			Width = 14,
			Windup = 0.62,
			Knockback = 55,
		},
	},
}
