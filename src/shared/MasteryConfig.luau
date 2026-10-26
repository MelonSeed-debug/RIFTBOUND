--!strict
-- Mastery v0.2: earned ONLY on a successful server-validated Spec ability cast.
-- Mastery XP is per-Spec; thresholds for skills are TOTAL earned mastery XP.
-- Every next mastery level costs 5 XP more than the previous level.
local Mastery = {}

Mastery.MaxLevel = 50
Mastery.SkillOrder = {"Z","X","C","V","G"}
Mastery.SkillRequirements = {
	Z = 0,  -- first ability is available immediately
	X = 10, -- second unlocks at ten total mastery XP
	C = 25, -- third at twenty-five
	V = 40, -- fourth at forty
	G = 60, -- fifth (ultimate) at sixty
}
Mastery.XPPerCast = {
	Z = 2,
	X = 3,
	C = 4,
	V = 5,
	G = 7,
}
Mastery.SkillActions = {
	PillShield = {Spec="AshleySimmons", Key="Z"},
	BuzzBoost = {Spec="AshleySimmons", Key="X"},
	RaveRush = {Spec="AshleySimmons", Key="C"},
	TrippyToss = {Spec="AshleySimmons", Key="V"},
	Frenzy = {Spec="AshleySimmons", Key="G"},
	VoidGuard = {Spec="VoidDisciple", Key="Z"},
	VoidStep = {Spec="VoidDisciple", Key="X"},
	VoidGrasp = {Spec="VoidDisciple", Key="C"},
	VoidCleave = {Spec="VoidDisciple", Key="V"},
	VoidNova = {Spec="VoidDisciple", Key="G"},
}

function Mastery.XPForLevel(level)
	level = math.clamp(math.floor(level),0,Mastery.MaxLevel)
	return 10*level + math.floor((5*level*(level-1))/2)
end

Mastery.MaxMasteryXP = Mastery.XPForLevel(Mastery.MaxLevel)
-- Kept as a compatibility alias for any earlier mastery displays.
Mastery.MaxMastery = Mastery.MaxMasteryXP

function Mastery.LevelForXP(totalXP)
	totalXP = math.clamp(math.floor(totalXP),0,Mastery.MaxMasteryXP)
	local low,high=0,Mastery.MaxLevel
	while low<high do
		local middle=math.ceil((low+high)/2)
		if totalXP >= Mastery.XPForLevel(middle) then
			low=middle
		else
			high=middle-1
		end
	end
	return low
end

function Mastery.LevelDetails(totalXP)
	totalXP=math.clamp(math.floor(totalXP),0,Mastery.MaxMasteryXP)
	local level=Mastery.LevelForXP(totalXP)
	local currentFloor=Mastery.XPForLevel(level)
	local target=level>=Mastery.MaxLevel and currentFloor or Mastery.XPForLevel(level+1)
	local within=totalXP-currentFloor
	local required=level>=Mastery.MaxLevel and 0 or target-currentFloor
	return level,within,required
end

return Mastery
