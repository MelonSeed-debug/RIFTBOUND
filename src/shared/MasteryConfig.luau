--!strict
-- Mastery is earned through confirmed NPC defeats while the Spec is equipped.
-- Existing level unlocks remain intact; only C / V / G have mastery gates.
return {
	MaxMastery = 100,
	SkillRequirements = {Z=0,X=0,C=3,V=10,G=25},
	SkillActions = {
		PillShield={Spec="AshleySimmons",Key="Z"},
		BuzzBoost={Spec="AshleySimmons",Key="X"},
		RaveRush={Spec="AshleySimmons",Key="C"},
		TrippyToss={Spec="AshleySimmons",Key="V"},
		Frenzy={Spec="AshleySimmons",Key="G"},
		VoidGuard={Spec="VoidDisciple",Key="Z"},
		VoidStep={Spec="VoidDisciple",Key="X"},
		VoidGrasp={Spec="VoidDisciple",Key="C"},
		VoidCleave={Spec="VoidDisciple",Key="V"},
		VoidNova={Spec="VoidDisciple",Key="G"},
	},
}
