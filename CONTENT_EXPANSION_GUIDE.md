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
| J | Quest Journal: accept, abandon, claim missions |
| M | Equip Ashley Simmons or earned Void Disciple |
| B | World Guide |
| N | Island Map |
| Z X C V G | Equipped Spec abilities; C/V/G have mastery thresholds |
| E near a named NPC | Dialogue or dungeon entrance |

Black-and-gold panels are styled with an Art Deco theme inspired by the provided image: dark gradients, thin gold borders, corner diamonds and gilded controls. The exact reference texture does **not** render as a Roblox image yet because it needs a valid uploaded Roblox ImageId. This implementation uses native UI primitives instead.

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

## Spec mastery

NPC defeats count toward mastery only while you have that Spec equipped. Mastery persists, separately for Ashley Simmons and Void Disciple.

- Z and X: available immediately after equipping the Spec.
- C: 3 confirmed NPC defeats with that Spec.
- V: 10 confirmed NPC defeats.
- G: 25 confirmed NPC defeats.

The new gilded HUD shows current mastery and skill locks. The server rejects attempts to use a locked skill.

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
- [ ] I opens the inventory; shop prompts for Dr. Liora and Gilded Broker work
- [ ] Buying a bandage removes exactly 35 Rift Coins and adds one bandage
- [ ] Damaged player can use bandage; full-health player cannot waste it
- [ ] Equip Iron Grips and verify damage is increased
- [ ] Defeat NPCs; confirm randomized material drops and mastery increments
- [ ] C unlocks after 3 Spec kills, V after 10, G after 25; locks enforced by server
- [ ] Accept The First Spark, talk to Dr. Liora, claim quest
- [ ] Verify chained quests must be completed in order
- [ ] Enter Abyss Citadel at level 25; dodge slam markers; fight the Warden
- [ ] Verify quest kill credit, guaranteed sigil, loot, and Abyss clear count
- [ ] Leave/rejoin (with Studio API access) and confirm items, gear and mastery are restored
- [ ] Confirm basic M1, heavy, blocking, dash, Ashley and Void Disciple still work

Known initial limitations: generated NPC character models are simple mannequins; UI is reference-inspired rather than using the original texture image, merchants have no full shop interiors, and dungeon co-op loot sharing is not implemented. Report Output errors after Studio testing for a focused fix.
