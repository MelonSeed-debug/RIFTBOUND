# RIFTBOUND Animation Pack Integration v0.1

## Emergency: UI disappeared / no animations after import

**First, open your real RIFTBOUND place.** Do NOT use **File > Open from File** on a `.rbxm`; that opens/imports it as a separate document rather than inserting the pack into your existing working place. If the Explorer no longer contains RIFTBOUND scripts and your UI vanished, reopen your previously saved or published RIFTBOUND place.

Then:

1. **Stop Play.** In Explorer, check `StarterPlayer > StarterPlayerScripts > RiftboundClient` (a LocalScript with children), `ServerScriptService > RiftboundServer`, and `ReplicatedStorage > Riftbound > Shared > AnimationConfig`.
2. If any is missing: download the **latest GitHub RIFTBOUND source ZIP**, replace your local **entire `src` directory** and `default.project.json`, restart `.\\rojo.exe serve` from your RIFTBOUND project folder, and reconnect the Rojo plugin. Do not replace the source files with an animation-only ZIP.
3. To verify in Studio **Edit Mode**, copy-paste the read-only [tools/DIAGNOSE_RIFTBOUND.lua](tools/DIAGNOSE_RIFTBOUND.lua) into the **Command Bar**, then open **View > Output** and look for `[MISSING]` entries.
4. For local animation preview, either insert the curated `.rbxm` model into **ReplicatedStorage** (using **Insert from File**, not Open) or insert your original `150+ Weapon Animations & Models.rbxm` into ReplicatedStorage or Workspace. The animation code will now recognize the original Gauntlets / Dual Axes clips automatically, or the curated clip folder, even if nested one level down.
5. Make sure your character is **R15**. Use **Server & Clients** and press left click, R heavy, F block and Q dash. Watch **View > Output** for `[RIFTBOUND Animations]`.
6. The animation loader is now completely **isolated from UI startup** and times out missing config lookups. A broken/missing animation should still leave the HUD, menu, health and inventory available.
7. If the original full pack causes frame drops, run [tools/IMPORT_ORIGINAL_ANIMATIONS.lua](tools/IMPORT_ORIGINAL_ANIMATIONS.lua) in **Edit Mode** to create a 21-clip `ReplicatedStorage > RIFTBOUND Animation Clips` folder. You can then remove the huge original imported model from Studio (but keep the original file on your PC).

Important: **Studio-local preview animations are not published Roblox assets.** You still need to publish them under the game's owner/group and fill in IDs in `AnimationConfig.luau` for your actual live game.


The uploaded **150+ Weapon Animations & Models.rbxm** contains **158 KeyframeSequences across 8 rig sets** (Dual Axes, Great Sword, Trident, Dual Great Shield, Gauntlets, Requiem, Oathkeeper and Lance).

The source model includes ~139,000 Roblox instances, mostly keyframes and poses. We extracted a smaller **21-clip R15 combat library** from its Gauntlets and Dual Axes animations, reducing the import from ~4.6 MB to ~540 KB. This keeps the basic fighting game fast and avoids importing weapon meshes until we actually add weapon gameplay.

**The curated file is supplied in the ChatGPT conversation as `RIFTBOUND_Combat_Animation_Clips.rbxm`.** The repository contains the code integration and upload slots, not the binary file itself.

## Test in Roblox Studio NOW (without uploading animation assets)

1. Download the curated **`RIFTBOUND_Combat_Animation_Clips.rbxm`** file from the ChatGPT reply. You do **not** need to import the original large weapon-model pack.
2. Download the latest RIFTBOUND GitHub ZIP, **replace your local `src` directory** and `default.project.json` (as usual), restart `.\rojo.exe serve`, and reconnect Studio.
3. In Studio **Edit mode**, open Explorer; **right-click `ReplicatedStorage` -> Insert -> Import Roblox Model**, then select the curated `.rbxm`. (If your Studio UI uses different wording, choose `Insert from File...`.)
4. Ensure Explorer now contains:

```text
ReplicatedStorage
├── Riftbound                       -- created by Rojo
│   └── Shared
│       └── AnimationConfig         -- created by Rojo
└── RIFTBOUND Animation Clips       -- import this curated model!
    ├── M1_1
    ├── M1_2
    ├── M1_3
    ├── M1_4
    ├── Heavy
    ├── Block
    ├── Parry
    ├── Dash
    ├── DashLeft
    ├── DashRight
    ├── DashBack
    ├── Hit
    └── ...                         -- 21 KeyframeSequences total
```

5. **Save/Publish your place** so the manually imported folder remains in Studio.
6. Launch **Server & Clients**. Test M1 (four hits), R heavy, F block, Q while moving forward/back/left/right, and a successful parry. The engine plays the imported KeyframeSequences using **temporary Studio-only preview IDs**.
7. If the animations do not play, inspect **View > Output** for `[RIFTBOUND Animations]` errors. If a clip can't load, the old procedural combat pose remains in place: gameplay should not stop.

### Expected integration

| In-game action | Animation source from your pack | Canonical KeyframeSequence |
|---|---|---|
| M1 steps 1–4 | Gauntlets Animations / M1 - 1…4 | M1_1 … M1_4 |
| R heavy | Gauntlets Animations / Gauntlet Heavy | Heavy |
| F block | Gauntlets Animations / blocking idle | Block |
| Parry | Gauntlets Animations / parry 1 | Parry |
| Getting hit | Dual Axes Animations / Flinch | Hit |
| Guard broken | Gauntlets Animations / Gauntlets_Parried | GuardBreak |
| Q forward / left / right / backward | Dual Axes Animations / directional dash clips | Dash, DashLeft, DashRight, DashBack |
| Future combo 5, jump, air slam, uppercut, clash, idle, walk | Gauntlets Animations | Already curated and named |

The M1/Heavy/Dash animation playback is **time-scaled to the pack's actual Hit markers** and the current server hitbox timings. No damage, hitbox, guard, mastery, XP or cooldown authority moved to the client.

## Publish animations for live servers

Roblox's temporary hash/active IDs work only in Studio preview. A real published game must use **uploaded animation asset IDs**, with animation permissions granted to the experience owner (or owning group).

1. In Studio's **Animation Editor**, load the selected KeyframeSequence on a matching **R15** rig and choose **Publish to Roblox** from the animation editor's menu; select the game owner/group. Alternatively, use the Explorer's animation Save/Export options if shown in your Studio version.
2. Copy each new numeric animation asset ID.
3. Edit **`src/shared/AnimationConfig.luau`** and fill in the matching `Moves` entries, e.g.:

```lua
Moves = {
    M1_1 = "rbxassetid://YOUR_REAL_ID_1",
    M1_2 = "rbxassetid://YOUR_REAL_ID_2",
    M1_3 = "rbxassetid://YOUR_REAL_ID_3",
    M1_4 = "rbxassetid://YOUR_REAL_ID_4",
    Heavy = "rbxassetid://YOUR_REAL_HEAVY_ID",
    Block = "rbxassetid://YOUR_REAL_BLOCK_ID",
    -- ... publish remaining clips as needed
}
```

Empty IDs are intentional until the upload step. The controller **prefers published IDs**, uses local KeyframeSequences in Studio, and falls back to its original procedural combat motion if neither is available.

The code does not need a data reset, a separate combat system, or new Spec acquisition rules. Ashley Simmons and Void Disciple continue using the same shared core fighting animations. Unique animations for the Z/X/C/V/G Spec skills can be assigned once suitable bespoke clips are available.

## Practical notes

- The input animation set is R15-based (includes R15 rigs and joint pose trees), but playback must still be checked against your actual R15 avatars in Studio.
- Imported clips are intended to stay in **ReplicatedStorage** as a sibling of the Rojo-managed `Riftbound` folder, not under ServerStorage (clients cannot preview there).
- The original source file can be kept on your PC for later weapon development; importing it wholesale to the game is unnecessary.
- If a permanent map or world is open in Edit mode, this import **does not change the environment**.
- Exact timing and animation fidelity have not yet been playtested in Roblox Studio; the timing calibration was calculated from encoded Hit-marker timestamps.
