-- RIFTBOUND / No-download alternative for the animation bundle.
-- Paste into Roblox Studio's Command Bar while NOT in Play mode,
-- after inserting the ORIGINAL "150+ Weapon Animations & Models.rbxm"
-- somewhere under Workspace or ReplicatedStorage.
-- This copies exactly 21 KeyframeSequences into ReplicatedStorage,
-- matching src/shared/AnimationConfig.luau's StudioPreview mappings.
--
-- Your original pack must contain these folders (verified against the upload):
-- Gauntlets Animations > AnimSaves
-- Dual Axes Animations > AnimSaves

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sourceNames = {
    Gauntlets = "Gauntlets Animations",
    DualAxes = "Dual Axes Animations",
}
local sourceFolders = {}

for category, name in pairs(sourceNames) do
    local rigFolder = game:FindFirstChild(name, true)
    assert(rigFolder, "Import the original pack first: missing " .. name)
    local saves = rigFolder:FindFirstChild("AnimSaves")
    assert(saves, "Missing " .. name .. " > AnimSaves")
    sourceFolders[category] = saves
end

local mapping = {
    {"M1_1",       "Gauntlets", "M1 - 1"},
    {"M1_2",       "Gauntlets", "M1 - 2"},
    {"M1_3",       "Gauntlets", "M1 - 3"},
    {"M1_4",       "Gauntlets", "M1 - 4"},
    {"M1_5",       "Gauntlets", "M1 - 5"},
    {"Heavy",      "Gauntlets", "Gauntlet Heavy"},
    {"Block",      "Gauntlets", "blocking idle"},
    {"Parry",      "Gauntlets", "parry 1"},
    {"GuardBreak", "Gauntlets", "Gauntlets_Parried"},
    {"DashAttack", "Gauntlets", "Dash Attack"},
    {"JumpAttack", "Gauntlets", "Jump Attack"},
    {"Uppercut",   "Gauntlets", "FistsUpTilt"},
    {"AirSlam",    "Gauntlets", "FistsAirSlam"},
    {"Clash",      "Gauntlets", "Gauntlets_Clashing"},
    {"Idle",       "Gauntlets", "idle"},
    {"Walk",       "Gauntlets", "walk"},
    {"Dash",       "DualAxes",  "front dash"},
    {"DashLeft",   "DualAxes",  "dash left"},
    {"DashRight",  "DualAxes",  "dash right"},
    {"DashBack",   "DualAxes",  "back dah"},
    {"Hit",        "DualAxes",  "Flinch"},
}
local output = Instance.new("Folder")
output.Name = "RIFTBOUND Animation Clips"
for _, entry in ipairs(mapping) do
    local targetName, category, sourceName = entry[1], entry[2], entry[3]
    local sequence = sourceFolders[category]:FindFirstChild(sourceName)
    assert(sequence and sequence:IsA("KeyframeSequence"),
        "Missing animation " .. category .. " > " .. sourceName)
    local clone = sequence:Clone()
    clone.Name = targetName
    clone.Parent = output
end

assert(#output:GetChildren() == 21, "Expected exactly 21 animations")
local existing = ReplicatedStorage:FindFirstChild(output.Name)
if existing then
    warn("Replacing existing RIFTBOUND Animation Clips with new 21-clip set")
    existing:Destroy()
end
output.Parent = ReplicatedStorage
print("RIFTBOUND: Installed 21 KeyframeSequences into ReplicatedStorage!")
print("Save the place. The latest GitHub scripts can preview them in Studio.")
