--!strict
-- RIFTBOUND Spec #2: Void Disciple (first playable balance draft).
-- All damage, targets, movement and cooldown checks are server-side.
return {
	Id = "VoidDisciple",
	Name = "Void Disciple",
	Passive = {Name = "Void Mark", HitsToBurst = 3, BurstDamage = 12, SelfHeal = 4, MarkDuration = 7},
	Abilities = {
		Z = {Name = "Abyss Guard", Cooldown = 15, ShieldHP = 100, Duration = 6},
		X = {Name = "Void Step", Cooldown = 8, Distance = 14},
		C = {Name = "Shadow Grasp", Cooldown = 12, Damage = 16, Range = 14, Radius = 6, SnareDuration = 1.6},
		V = {Name = "Rift Cleave", Cooldown = 16, Damage = 24, Range = 14, Radius = 9},
		G = {Name = "Abyss Nova", Cooldown = 55, Pulses = 3, DamagePerPulse = 15, Radius = 15, PulseInterval = 0.35},
	},
}
