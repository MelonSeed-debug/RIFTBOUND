-- RIFTBOUND Great Sword installer (Studio Command Bar, EDIT MODE).
-- This takes the ACTUAL Abyssal Covenant model and 15 actual KeyframeSequences
-- from your ORIGINAL "150+ Weapon Animations & Models.rbxm".
-- It creates two SMALL folders under ReplicatedStorage WITHOUT deleting the
-- imported original pack or changing any game scripts.
--
-- 1. Open your RIFTBOUND PLACE, NOT the .rbxm file itself.
-- 2. Stop Play. Import ORIGINAL .rbxm into Workspace or ReplicatedStorage
--    using right-click "Insert from File".
-- 3. Paste this whole file into Studio's Command Bar and press Enter.
-- 4. Check Output. You can remove original huge import AFTER copying.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),
	"Run only in Roblox Studio EDIT MODE (stop Play first).")

local rig = ReplicatedStorage:FindFirstChild("Great Sword Animations", true)
	or Workspace:FindFirstChild("Great Sword Animations", true)
assert(rig and rig:IsA("Model"),
	"Original pack missing: insert '150+ Weapon Animations & Models.rbxm' " ..
	"into Workspace or ReplicatedStorage, then rerun this script.")

local saves = rig:FindFirstChild("AnimSaves")
assert(saves, "Original Great Sword Animations rig has no AnimSaves.")

local sourceSword = rig:FindFirstChild("Abyssal Covenant")
assert(sourceSword and sourceSword:IsA("Model"),
	"Missing original Abyssal Covenant sword model.")
assert(sourceSword:FindFirstChild("Main",true),
	"Original Abyssal Covenant needs a Main handle part.")

local mapping = {
	{"SwordM1_1", "M1"},
	{"SwordM1_2", "M2"},
	{"SwordM1_3", "M3"},
	{"SwordM1_4", "M4"},
	{"SwordHeavy", "Greatsword Heavy"},
	{"SwordBlock", "Blocking"},
	{"SwordParry", "Parry"},
	{"SwordParried", "Parried"},
	{"SwordDashAttack", "DashAttack"},
	{"SwordUplift", "TitanBladeUpTilt"},
	{"SwordSlam", "TitanBladeAirSlam"},
	{"SwordExecution", "M5"},
	{"SwordIdle", "Idle"},
	{"SwordWalk", "WalkWeaponShouldered"},
	{"SwordRun", "RunWeaponShouldered"},
}

local assets = ReplicatedStorage:FindFirstChild("RIFTBOUND Weapon Assets")
if not assets then
	assets = Instance.new("Folder")
	assets.Name = "RIFTBOUND Weapon Assets"
	assets.Parent = ReplicatedStorage
end
local oldWeapon = assets:FindFirstChild("GreatSword")
if oldWeapon then oldWeapon:Destroy() end
local clonedSword = sourceSword:Clone()
clonedSword.Name = "GreatSword"
clonedSword.Parent = assets

local library = ReplicatedStorage:FindFirstChild("RIFTBOUND Animation Clips")
if not library then
	library = Instance.new("Folder")
	library.Name = "RIFTBOUND Animation Clips"
	library.Parent = ReplicatedStorage
end
for _, pair in ipairs(mapping) do
	local targetName, sourceName = pair[1], pair[2]
	local source = saves:FindFirstChild(sourceName)
	assert(source and source:IsA("KeyframeSequence"),
		"Missing Great Sword KeyframeSequence: " .. sourceName)
	local old = library:FindFirstChild(targetName)
	if old then old:Destroy() end
	local clip = source:Clone()
	clip.Name = targetName
	clip.Parent = library
end

print("[RIFTBOUND GREAT SWORD] Installation succeeded!")
print("  Model: ReplicatedStorage > RIFTBOUND Weapon Assets > GreatSword")
print("  Clips: ReplicatedStorage > RIFTBOUND Animation Clips (15 new sword clips)")
print("  Now SAVE your place. Sync latest RIFTBOUND src through Rojo and test.")
print("  After verifying, you may remove the large ORIGINAL imported pack.")
