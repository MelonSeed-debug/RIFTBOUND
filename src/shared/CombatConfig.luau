--!strict
-- RIFTBOUND Phase 1: shared, server-authoritative combat tuning.
local CombatConfig = {
	BaseWalkSpeed = 16,

	M1 = {
		Damages = {7, 7, 9, 12},
		ComboResetTime = 1.20,
		HitCooldown = 0.33,
		FinisherCooldown = 0.70,
		Windup = 0.12,
		Recovery = 0.22,
		Range = 6,
		Width = 5.2,
		Height = 5.2,
		FinisherKnockback = 42,
	},

	Heavy = {
		Damage = 18,
		Cooldown = 1.65,
		Windup = 0.36,
		Recovery = 0.54,
		Range = 6.4,
		Width = 5.5,
		Height = 5.2,
		GuardBreakStun = 1.2,
		Knockback = 28,
	},

	Block = {
		WalkSpeed = 8,
		FrontDot = 0.25,
		ParryWindow = 0.25,
		ParryCooldown = 1.2, -- Prevent block-tap parry spam.
		ParryStun = 0.9,
	},

	Dash = {
		Speed = 72,
		Duration = 0.17,
		Cooldown = 1.8,
	},

	NPC = {
		Enabled = true,
		StudioOnly = false, -- Real world encounters now spawn in the published world too.
		DetectRange = 40,
		LeashRange = 58,
		AttackRange = 5.6,
		AttackWindup = 0.55,
		AttackCooldown = 2.1,
		AttackDamage = 9,
		WalkSpeed = 12,
		GuardWalkSpeed = 6,
		GuardDuration = 1.1,
		DecisionInterval = 2.6,
		RespawnDelay = 5,
		ThinkInterval = 0.25,
		Health = 160,
	},
	
	Trainer = {
		AttackWindup = 0.55,
		AttackInterval = 3.3,
		AttackDamage = 5,
		DetectionRange = 8,
	},
}

return CombatConfig
