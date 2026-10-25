--!strict
-- RIFTBOUND Spec #1: Ashley Simmons
-- DESIGN DATA ONLY. Abilities require server-side implementations.
-- The initial five Pill Projectile effects and the alternate Frenzy effects are kept distinct.
return {
	Id = "AshleySimmons",
	Name = "Ashley Simmons",
	Theme = "Retro Y2K neon / chaotic pharmaceutical fantasy",
	Rig = "R15",
	Role = "Unpredictable control / support / skirmisher",
	Passive = {
		Name = "Pill Projectile",
		Damage = 10,
		Ammo = 10,
		AutoReload = true,
		Trigger = "SuccessfulMeleeHit", -- automatic on unblocked M1/heavy hits; no extra button
		TriggerCooldown = 0.8, -- provisional balance value
		ReloadOnEmptyOnly = true,
		ReloadSeconds = 2.5, -- provisional: original concept did not specify reload time
		Effects = {
			ChillPill = {Duration = 1.5, Kind = "Slow", Amount = 0.25}, -- slow percentage provisional
			Euphoria = {Duration = 2.5, Kind = "AimDisruption"},
			AdrenalineRush = {Duration = 4, Kind = "DamageAmplifyWithVulnerability", OutgoingMultiplier = 1.20, IncomingMultiplier = 1.10},
			AntiInflammatory = {Duration = 5, Kind = "OutgoingDamageReduction", Amount = 0.05},
			MoodStabilizer = {Duration = 3, Kind = "HealOverTimeWithAttackSlow", HealMaxHealthFraction = 0.05, AttackSpeedReduction = 0.03},
		},
	},
	Abilities = {
		Z = {Name = "Pill Shield", Cooldown = 12, ShieldHP = 150, Duration = 8},
		X = {Name = "Buzz Boost", Cooldown = 15, DamageResistance = 0.30, Duration = 6},
		C = {Name = "Rave Rush", Cooldown = 7, MoveSpeedMultiplier = 1.50, Duration = 4, ClearsSlows = true},
		V = {Name = "Trippy Toss", Cooldown = 18, Damage = 5, BlindDuration = 2, AOE = true},
	},
	Ultimate = {
		Name = "Frenzy",
		Cooldown = 60,
		ProjectileCount = 5,
		DamagePerProjectile = 15,
		Effects = {
			Drowsiness = {Duration = 3, Kind = "Slow"},
			Confusion = {Duration = 5, Kind = "VisualDisruptionAndControlInvert"},
			Overdose = {Duration = 3, Kind = "DamageOverTime", DamagePerSecond = 1},
			Euphoria = {Duration = 5, Kind = "OutgoingDamageReductionZone"},
			Nausea = {Kind = "MissNextAttack"},
		},
	},
	AlternativeEffectIdeas = {
		Drowsiness = {Duration = 3, Kind = "Slow"},
		Confusion = {Duration = 0.5, Kind = "ControlInvert"},
		Overdose = {Duration = 3, Kind = "DamageOverTime"},
		Euphoria = {Duration = 5, Kind = "OutgoingDamageReduction"},
		Nausea = {Kind = "MissNextAttack"},
	},
}
