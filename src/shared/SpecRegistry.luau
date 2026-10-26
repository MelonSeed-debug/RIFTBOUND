--!strict
-- Public Spec catalogue. Ownership and equip authorization are decided on the server.
-- Add future Specs here when their gameplay implementations are ready.
return {
	Default = "None",
	Specs = {
		AshleySimmons = {
			Id = "AshleySimmons",
			Name = "Ashley Simmons",
			Subtitle = "Neon chaos / status control",
			Description = "Capsule effects, protection, speed boosts and a five-shot Frenzy.",
			Ready = true,
			StarterUnlocked = true, -- Prototype access; replace with progression unlocks later.
		},
		VoidDisciple = {
			Id = "VoidDisciple",
			Name = "Void Disciple",
			Subtitle = "Rift control / spatial strikes",
			Description = "Unlock by completing the Rift Sentinel trial.",
			Ready = true,
			StarterUnlocked = false,
			RequiredLevel = 10,
			RequiredPermit = "RiftInitiate",
		},
	},
	Order = {"AshleySimmons", "VoidDisciple"},
}
