--!strict
-- RIFTBOUND animation set: adapted from the user's 150+ Weapon Animations pack.
-- The companion RIFTBOUND_Combat_Animation_Clips.rbxm contains 21 genuine
-- KeyframeSequences (mostly Gauntlets, plus four directional dashes).
--
-- STUDIO: Import that lightweight Folder into ReplicatedStorage and test.
-- The client generates temporary preview IDs with AnimationClipProvider.
-- LIVE GAME: publish clips using the game's owner/group and paste numeric IDs
-- below as rbxassetid://...; Studio-local preview IDs DO NOT work in live games.
return {
	PreviewFolder = "RIFTBOUND Animation Clips",
	StudioPreview = true,
	-- Measured from the uploaded pack's "Hit" animation markers.
	-- Speeds align visual impact with existing SERVER hitbox timing:
	-- 0.12 s for M1, 0.36 s for Heavy, ~0.17 s for a dash.
	PlaybackSpeeds = {
		M1_1 = 3.61, M1_2 = 1.67, M1_3 = 1.67, M1_4 = 1.25,
		Heavy = 2.92,
		Dash = 4.0, DashLeft = 4.3, DashRight = 4.3, DashBack = 3.43,
		Parry = 1.5,
		-- Great Sword marker timings measured from the source KeyframeSequences:
		-- M1: 0.65/0.65/0.583/0.633s, Heavy: first hit 1.233s,
		-- DashAttack: 0.4s, UpTilt: 0.54s, AirSlam: 0.422s, M5: 0.633s.
		SwordM1_1 = 5.42, SwordM1_2 = 5.42,
		SwordM1_3 = 4.86, SwordM1_4 = 5.28,
		SwordHeavy = 3.43, SwordDashAttack = 2.5,
		SwordUplift = 2.08, SwordSlam = 1.0,
		SwordExecution = 1.02,
	},
	Moves = {
		M1_1 = "",
		M1_2 = "",
		M1_3 = "",
		M1_4 = "",
		M1_5 = "", -- reserved for possible five-hit combo expansion
		Heavy = "",
		Block = "",
		Parry = "",
		Hit = "",
		GuardBreak = "",
		Dash = "",
		DashLeft = "",
		DashRight = "",
		DashBack = "",
		DashAttack = "",
		JumpAttack = "",
		Uppercut = "",
		AirSlam = "",
		Clash = "",
		Idle = "",
		Walk = "",
		-- Abyssal Covenant Great Sword: original R15 sword animations.
		SwordM1_1 = "",
		SwordM1_2 = "",
		SwordM1_3 = "",
		SwordM1_4 = "",
		SwordHeavy = "",
		SwordBlock = "",
		SwordParry = "",
		SwordParried = "",
		SwordDashAttack = "",
		SwordUplift = "",
		SwordSlam = "",
		SwordExecution = "",
		SwordIdle = "",
		SwordWalk = "",
		SwordRun = "",
	},
}
