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
	},
}
