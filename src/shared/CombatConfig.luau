--!strict
-- Phase 1 test values. Balance after playtesting.
local CombatConfig = {
	BaseWalkSpeed = 16,
	M1 = {
		Damages = {8, 8, 10, 13},
		ComboResetTime = 1.25,
		HitCooldown = 0.30,
		FinisherCooldown = 0.60,
		Range = 6.5,
		Width = 5.5,
		Height = 5.0,
		FinisherKnockback = 42,
	},
	Block = {
		WalkSpeed = 8,
		FrontDot = 0.25, -- Attack must come from the defender's front.
	},
	Dash = {
		Speed = 72,
		Cooldown = 1.8,
	},
}

return CombatConfig
