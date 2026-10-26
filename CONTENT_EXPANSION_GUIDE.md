# RIFTBOUND / Content Expansion v0.2

**Scope:** inventory, consumables, equipment, merchants, story NPC dialogue, a five-chapter main quest arc, one dungeon and Abyss Warden mechanics, per-Spec mastery, Art Deco interface.

Everything is written in Luau and committed to this repository. **It has not been run in Roblox Studio by the assistant**; the scripts and connections were inspected statically.

## Install for the non-git ZIP workflow

1. Open https://github.com/MelonSeed-debug/RIFTBOUND and download the latest ZIP.
2. Replace the old `src` folder with the latest `src`, and replace `default.project.json` too.
3. Stop Rojo in the PowerShell window, then from `C:\Users\danie\Downloads\RIFTBOUND` execute `.\rojo.exe serve`.
4. Reconnect the Rojo plugin in Roblox Studio **New Beginning**.
5. Test in **Server & Clients**. If an error appears, open **View > Output** and copy the first red error with its line number.

If you've already baked the island world (Workspace / RIFTBOUND World), keep it; these features reuse the existing baked world.

## New controls and UI

| Key | Panel / action |
| --- | --- |
| I | Inventory: use healing items, equip gear, view materials |
| J or P | Quest Journal: accept, abandon, claim missions |
| M | Open the Main Menu (Specs, Quests, Inventory, Map, World Guide, Character, Mastery, Dungeons) |
| B | World Guide |
| N | Island Map |
| Z X C V G | Equipped Spec abilities; C/V/G have mastery thresholds |
| E near a named NPC | Dialogue or dungeon entrance |

Black-and-gold panels are styled with an Art Deco theme inspired by the provided image: dark gradients, thin gold borders, corner diamonds and gilded controls. A **three-bar combat HUD** uses red health, blue active shielding, and green equipped-Spec mastery. The exact reference texture does **not** render as a Roblox image yet because it needs a valid uploaded Roblox ImageId. This implementation uses native UI primitives instead.

## Shops and inventory (server-validated)

- **Dr. Liora**: E to talk; select Visit Shop for Apothecary.
  - Field Bandage (35 coins, +45 HP).
  - Rift Tonic (100 coins, +125 HP, level 5).
  - Ember Draught (160 coins, +15% outgoing damage for 45s, level 10).
  - Ward Vial (135 coins, 20% less incoming damage for 40s, level 8).
- **Gilded Broker**: E to talk; Visit Shop for Gear.
  - Iron Grips (260 coins, +8% equipped damage, level 5).
  - Gilded Crest (850 coins, +15% equipped damage, level 20).
  - Sell materials at either merchant (Forged Scrap, Rift Shards, Abyss Sigils).
- Enemy drops are random. There is a 24-stack inventory cap, 99 items per stack, and a 2-second consumable cooldown.
- Prices, ownership, coins, inventory and effects are all checked on the **server**. Shops must be used near the actual NPCs in Haven.

## Story NPCs and chapter quests

Five story quests are sequential and saved with the existing quests:

1. **The First Spark** (Lv 1): accept from Warden Vale or journal, talk to Dr. Liora, claim reward.
2. **Shadows on the Market** (Lv 3): speak to Kestrel in Old Quarter.
3. **The Foundry Secret** (Lv 10): find Foreman Brass in Ironworks.
4. **Voices of the Veil** (Lv 25): find Oracle Nyx in Rift Expanse.
5. **Heart of the Abyss** (Lv 25): defeat the Abyss Warden and claim the story quest.

**Important:** Accept a Talk objective *before* interacting with the requested NPC. If you accepted the quest during a conversation, talk to that NPC once more to credit the objective. Quest claim remains in J.

Non-story quests and the Void Disciple acquisition trial remain available.

## Spec mastery v0.2 — uses, XP and rising level costs

Mastery is now gained by **successful skill activations**, not enemy kills. Each Spec has its own saved mastery XP and level. Skill casts rejected by the server (wrong Spec, dead, on cooldown, below required mastery) award **zero XP**.

| Skill slot | Key | Total mastery XP needed | XP gained per successful cast |
| --- | --- | ---: | ---: |
| First | Z | 0 | 2 |
| Second | X | 10 | 3 |
| Third | C | 25 | 4 |
| Fourth | V | 40 | 5 |
| Fifth / ultimate | G | 60 | 7 |

**Mastery level progression:**
- Level 0 → 1 needs **10 XP**.
- Level 1 → 2 needs another **15 XP** (25 total).
- Level 2 → 3 needs another **20 XP** (45 total).
- Level 3 → 4 needs another **25 XP** (70 total).
- Subsequent levels add **5 XP more** than the last; max mastery level is 50.

Skill unlocks are based on **total earned mastery XP**, not mastery level directly. This makes X unlock at the first level milestone (10 XP), C at 25 XP and so on.

The previous v4 saved mastery generated from NPC defeats is migrated once at **2 XP per legacy mastery point**, so existing progress is not abruptly discarded. New saves store `masteryXP` in profile version 5.

## Main Menu & UI contrast fix

- **M** now opens the centralized 8-section Main Menu. Choose Specs there to equip Ashley Simmons or earned Void Disciple.
- The **SPECS** quick toggle, Quests toggle, Inventory toggle, and Map quick toggle are hidden; direct keyboard shortcuts still work, including I, J/P, B and N.
- The central menu displays character, mastery and dungeon information without duplicating persistent profile state.
- Art Deco panels use a white tint base for their dark color gradient (UIGradient multiplies the tint), and the ScreenGui uses Sibling ZIndex layering so modal text/buttons are not hidden beneath their own background.
- Old Spec selection no longer automatically pops up on spawn.
- Existing shop dialogue still opens the Buy tab, while the main menu Inventory entry opens the bag.

## Interface overlap fixes

- Large panels (Inventory, Quests, Specs, Map, World Guide, Story Dialogue) are **mutually exclusive**. Opening one closes the others.
- The Void Disciple cooldowns now occupy a **five-slot center-top dock**, not the same bottom-left space as the health bars.
- Mastery and health/shield displays have separate positions. Small viewport scaling reduces panel crowding, and the large dock is hidden in especially compact viewports.
- Keys **I**, **J or P**, **M**, **B**, and **N** remain available; P is an additional quest shortcut.
- Black/gold/Art Deco style remains active.


## Abyss Citadel — first playable dungeon

The **Rift Expanse** contains the purple Abyss Citadel entrance. At Level 25 or higher, press E to enter the shared dungeon. An E prompt near the room entrance allows you to leave.

**Abyss Warden:** 1,650 HP, close-range attacks, visible circular ground warnings. Dodge away before its timed slam lands. Below 50% HP it accelerates the slams and spawns an Abyss Echo.

- Boss XP: 1,600, Rift Coins: 520.
- Clear count is saved; the last verified killer gets a guaranteed Abyss Sigil trophy plus the normal random boss drops.
- Warden does not automatically respawn on death. After a 35-second cooldown, entering the dungeon again starts a new encounter.
- First version is a **shared arena**, not a private party instance. Co-op participation credit and drop sharing are future work; boss clear rewards currently belong to the credited killer.

## Persistent profile

Saved together in the existing `RIFTBOUND_Progression_v1` DataStore: level/XP, coins, defeats, quest progress and claimed quests, Spec ownership/equipped Spec, **inventory, equipped gear, mastery for both Specs and Abyss clear count**.

Storage uses the same key and upgrades the snapshot version to 4 without resetting old players. Roblox Studio must have **Enable Studio Access to API Services** enabled to test persistence in a published experience. Otherwise saving is session-only. Never test important live saved profiles without a separate testing experience.

## Test checklist

- [ ] Red/yellow Output free of module errors at startup
- [ ] M opens the new main menu and its eight entries work; I opens Inventory and J/P open Quests. Shop prompts for Dr. Liora and Gilded Broker still open the Buy tab.
- [ ] Buying a bandage removes exactly 35 Rift Coins and adds one bandage
- [ ] Damaged player can use bandage; full-health player cannot waste it
- [ ] Equip Iron Grips and verify damage is increased
- [ ] Defeat NPCs; confirm randomized loot. Verify a kill ALONE does not increase mastery
- [ ] Cast Z five times (respect its cooldown): 10 total mastery XP, mastery level 1, X unlocks. Then use X (+3 XP) to work toward C (25 XP), V (40 XP), G (60 XP)
- [ ] Accept The First Spark, talk to Dr. Liora, claim quest
- [ ] Verify chained quests must be completed in order
- [ ] Enter Abyss Citadel at level 25; dodge slam markers; fight the Warden
- [ ] Verify quest kill credit, guaranteed sigil, loot, and Abyss clear count
- [ ] Leave/rejoin (with Studio API access) and confirm items, gear and skill-earned mastery XP are restored
- [ ] Confirm windows no longer overlap: open Specs, Quests, Inventory and Map one after another; verify only one remains open. Confirm basic combat still works

Known initial limitations: generated NPC character models are simple mannequins; UI is reference-inspired rather than using the original texture image, merchants have no full shop interiors, and dungeon co-op loot sharing is not implemented. Report Output errors after Studio testing for a focused fix.
