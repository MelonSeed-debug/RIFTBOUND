-- RIFTBOUND Studio Command Bar diagnostics. Paste while Play is STOPPED.
-- Makes no changes to your game.
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerScriptService")
local SP=game:GetService("StarterPlayer")
local W=game:GetService("Workspace")

local function status(label,object,where)
	print((object and "[OK] " or "[MISSING] ")..label..
		" / expected: "..where)
end

print("========== RIFTBOUND CHECK ==========")
local client=SP.StarterPlayerScripts:FindFirstChild("RiftboundClient")
local server=SS:FindFirstChild("RiftboundServer")
local project=RS:FindFirstChild("Riftbound")
local shared=project and project:FindFirstChild("Shared")
local remotes=project and project:FindFirstChild("Remotes")
status("Rojo client LocalScript",client,"StarterPlayer/StarterPlayerScripts/RiftboundClient")
status("Rojo server Script",server,"ServerScriptService/RiftboundServer")
status("Game shared folder",shared,"ReplicatedStorage/Riftbound/Shared")
status("CombatRequest",remotes and remotes:FindFirstChild("CombatRequest"),"ReplicatedStorage/Riftbound/Remotes")
for _, name in {"AnimationConfig","CombatConfig","WorldConfig","MasteryConfig"} do
	status(name,shared and shared:FindFirstChild(name),"ReplicatedStorage/Riftbound/Shared")
end
for _, name in {"CombatAnimations","ArtDecoUI","MainMenuUI","UIManager","VitalsHUD","ProgressionHUD","SpecAbilityHUD","InventoryUI"} do
	status(name,client and client:FindFirstChild(name),"StarterPlayerScripts/RiftboundClient")
end

local clips=RS:FindFirstChild("RIFTBOUND Animation Clips",true)
	or W:FindFirstChild("RIFTBOUND Animation Clips",true)
local gauntlets=RS:FindFirstChild("Gauntlets Animations",true)
	or W:FindFirstChild("Gauntlets Animations",true)
status("Curated 21-clip animation folder",clips,"ReplicatedStorage/RIFTBOUND Animation Clips")
status("Original weapon animation pack (Gauntlets)",gauntlets,"ReplicatedStorage (or Workspace) > Gauntlets Animations")
if clips then
	local count=0
	for _, object in clips:GetDescendants() do
		if object:IsA("KeyframeSequence") then count+=1 end
	end
	print("Imported KeyframeSequence count:",count)
end

if not client or not shared or not remotes then
	warn("RIFTBOUND isn't synced. Open the RIFTBOUND PLACE, start .\\rojo.exe serve in the RIFTBOUND folder, then reconnect the Rojo Studio plugin.")
elseif not clips and not gauntlets then
	warn("Scripts are synced but animation model isn't imported. INSERT .rbxm under ReplicatedStorage in Explorer; don't use File > Open.")
else
	print("Scripts and animation source found. Test in Play mode. Check View > Output for [RIFTBOUND Animations].")
end
print("========== END ==========")
