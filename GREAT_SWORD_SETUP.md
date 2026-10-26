# RIFTBOUND / Abyssal Covenant Great Sword Spec

**Status:** Implementation committed. Third playable starter Spec; Great Sword visible (actual model if imported, safe built-in fallback otherwise); five mastery-gated abilities, four basic sword combo clips, server-validated damage and cooldowns, UI and persistence.

## What was found in your original animation pack

I inspected **150+ Weapon Animations & Models.rbxm** directly. The Great Sword is here:

```text
150+ Weapon Animations & Models (Folder)
└── Great Sword Animations (Model)
    ├── Abyssal Covenant (Model)
    │   ├── Main (Part, sword attachment root)
    │   ├── Blade (MeshPart, actual sword blade)
    │   └── BladeSparkDetector / attachments / effects
    └── AnimSaves (Model)
        ├── M1 / M2 / M3 / M4 / M5
        ├── Greatsword Heavy
        ├── Blocking / Parry / Parried
        ├── DashAttack
        ├── TitanBladeUpTilt
        ├── TitanBladeAirSlam
        ├── Idle
        ├── WalkWeaponShouldered
        └── RunWeaponShouldered
```

The project does **not** contain published Roblox IDs for these clips. Studio can preview imported KeyframeSequences; publishing them under your game's owner/group is required for the live experience.

## Install it (no extra ZIP needed!)

These are **two separate items**: code from GitHub, and the original `.rbxm` asset pack.

1. Open your **existing RIFTBOUND place** in Roblox Studio. **Stop Play**.
2. Download latest source from [MelonSeed-debug/RIFTBOUND](https://github.com/MelonSeed-debug/RIFTBOUND), replace the entire local `src` directory and `default.project.json`, restart `.\\rojo.exe serve`, and connect Rojo to that place. This updates the game scripts.
3. If your **original 150+ Weapon Animations & Models.rbxm** is *not already inserted* in the place, insert it into `ReplicatedStorage` or `Workspace` by right-clicking that service in **Explorer → Insert from File**. Do **not** use File → Open: that opens a different place/model and can make your old UI seem to vanish.
4. Open the following GitHub file, copy **all its Lua text**, paste into **Studio's Command Bar** in Edit mode, press Enter: [tools/INSTALL_GREAT_SWORD.lua](tools/INSTALL_GREAT_SWORD.lua).
5. The script finds the true Abyssal Covenant model and copies it under `ReplicatedStorage > RIFTBOUND Weapon Assets > GreatSword`; it also clones **15 Great Sword KeyframeSequences** under `ReplicatedStorage > RIFTBOUND Animation Clips`. It does not delete the original pack, your UI, or your other animations.
6. **Save/publish your place** to persist the manually imported asset folders.
7. Run **Server & Clients** and press **M → SPECS → EQUIP SWORD**. The original sword mesh should appear attached to your R15 character's right hand. Test M1 combo, R heavy, F block, Q dash, and Z/X/C/V/G skills.
8. After confirming the two new ReplicatedStorage folders are present, you **may remove the very large original imported pack** from Workspace/ReplicatedStorage to reduce place size. Keep the source file safely on your PC for future weapon development.

## Controls and skills

| Input | Great Sword action | Requirement |
|---|---|---|
| Left click | Sword M1 (4-hit combo) | Available immediately |
| R | Greatsword Heavy | Available immediately |
| F | Weapon block / parry | Available immediately |
| Q | Dash attack animation | Available immediately |
| Z | Covenant Guard (45% resistance for 3s, 14s cooldown) | 0 mastery XP |
| X | Rending Lunge (short controlled forward rush + slash, 9s cooldown) | 10 mastery XP |
| C | Titan Uplift (upward launcher, 13s cooldown) | 25 mastery XP |
| V | Falling Covenant (area slam, 19s cooldown) | 40 mastery XP |
| G | Abyssal Execution (long heavy finishing slash, 58s cooldown) | 60 mastery XP |

Great Sword has its own saved mastery XP under `SpecMastery_GreatSword`. The Sword is a **starter Spec** for grass-field testing, so you don't need to farm bandits or run an unavailable Void Trial.

All skills are authorized server-side. Hitboxes, cooldowns, damage reduction, and mastery rewards are never decided by animation events or user-provided damage numbers. The M1 and heavy sword normals have distinct range/damage/cooldown tuning from barehanded combat.

### Hit marker timing calibration

From actual Great Sword KeyframeSequence `Hit` markers in the original file:
- M1: 0.65 seconds → 0.12s server hitbox (5.42x playback)
- M2: 0.65 → 0.12s (5.42x)
- M3: 0.583 → 0.12s (4.86x)
- M4: 0.633 → 0.12s (5.28x)
- Greatsword Heavy: first 1.233 → 0.36s (3.43x)
- DashAttack: 0.40 → 0.16s (2.5x)
- TitanBladeUpTilt: 0.54 → 0.26s (2.08x)
- TitanBladeAirSlam: 0.422 → 0.42s (1.0x)
- M5 finisher: 0.633 → 0.62s (1.02x)

The timings are *derived from the source clips*, not yet visually playtested in Studio. Adjust for feel after testing.

## Important notes

- **The sword models require R15**. A simple fallback blade is displayed if the original sword model isn't installed. Check Roblox Studio game settings if your avatar is R6.
- The uploaded `.rbxm` is an asset **model**, not a new game place. You must insert it inside the existing RIFTBOUND place.
- The bundled animation pack's **Idle/Walk/Run** sequences are extracted for future locomotion blending, but this first build focuses on actual combat and skills. Normal Roblox walking animations are otherwise unchanged.
- **Live/published experience:** Use the Animation Editor to publish the 15 sequences under the appropriate experience owner/group, then copy their new `rbxassetid://...` values into `src/shared/AnimationConfig.luau`. Blank IDs use temporary Studio preview IDs; those will *not* work in the live game.
- Don't publish another creator's assets without appropriate rights/licensing. Verify that the animation pack permits reuse in your experience.

## If animations or UI still don't appear

Open [tools/DIAGNOSE_RIFTBOUND.lua](tools/DIAGNOSE_RIFTBOUND.lua) in GitHub, copy-paste into Studio Edit-mode Command Bar, and inspect View → Output. Check `StarterPlayerScripts > RiftboundClient`, `ReplicatedStorage > Riftbound > Shared > AnimationConfig`, and `RIFTBOUND Animation Clips`.

An animation import failure **must not prevent the UI from starting**. The sword and skills use server-validated combat even when animation preview fails. If your animation plays but the blade alignment needs adjusting, the grip orientation is the `targetGrip` CFrame in `src/server/GreatSwordMoves.luau`.

**Not run in Roblox Studio in this environment**. Static checks and the source pack's exact animation names/hit marker data have been verified; test in a local server session before publishing.
