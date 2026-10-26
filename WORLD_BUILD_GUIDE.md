# RIFTBOUND / Flat Grass Practice Field v3

RIFTBOUND is temporarily stepping away from its old four-island world and from repetitive NPC bandit grinding. The **current playground is simple grass**, designed for combat, animations, Specs, movement and future PvP testing.

## What is active

- One 900 × 900 stud anchored Grass floor centered on the original SpawnLocation.
- Bright daytime lighting, no distant district scenery, bridges, or crystal citadel.
- The 500 HP Studio training dummy, plus story and shop characters staged close to spawn for functional testing.
- M Main Menu (Specs, Quests, Inventory, Character, Mastery and Dungeons).
- Skill mastery, both existing Specs, saved level/coins/inventory, and story dialogue.
- No automatic bandit patrols. All old kill-contract quests are paused in practice mode and hidden in the Quest Journal, **except if one is already active**, so it can still be abandoned.
- The dungeon is an **optional, separately entered boss challenge**, not a roaming enemy on the field. Enter through the purple portal near spawn at Level 25.

## Update your ZIP-based Rojo installation

1. Download the latest ZIP from https://github.com/MelonSeed-debug/RIFTBOUND .
2. Replace the local `src` folder completely, **not just individual scripts**. This removes old world/UI files as intended. Keep any unrelated local non-repo files.
3. Replace `default.project.json` from the ZIP.
4. Stop `.\rojo.exe serve`, then run it again in `C:\Users\danie\Downloads\RIFTBOUND`.
5. Reconnect Rojo to Studio and start a **Server & Clients** session.

The server now removes an old generated folder named `Workspace > RIFTBOUND World` (v2) on game start and builds a v3 grass floor instead. It also removes old generated quest/actor staging folders so their NPCs respawn near the field. **This only changes the running Play session.** If the old islands were baked and saved into the place, they will reappear after stopping Play until the steps below are performed.

## Make flat grass permanent in Edit Mode

With Play **stopped**, Rojo connected, and the latest scripts synced:

1. Open **View > Command Bar** (or the equivalent Command Bar in Studio).
2. Run exactly:

```lua
require(game.ServerScriptService.RiftboundServer.WorldBuilder).Bake()
```

3. In Explorer, inspect `Workspace > RIFTBOUND World > FLAT GRASS — EDITABLE FIELD`. The old generated islands/bridges under `RIFTBOUND World` have been replaced with the grass part.
4. **Save or Publish the place**. This is what makes the change persist in Studio Edit Mode and the published experience.

The Bake command **deletes the older generated `RIFTBOUND World` folder**, including manual changes inside it; save a backup place first if you want to recover that previous island map. It does not delete unrelated Workspace models.

### If the old island models are still visible

- Check whether they are inside a separate manually created folder, not `RIFTBOUND World`. This updater only removes the generated RIFTBOUND folder.
- If your previous island edits were not saved and are only appearing while playing, replace the entire `src` folder and restart Rojo.
- The script hides an existing default large Baseplate to prevent it from covering the grass part. The floor itself is directly under the generated folder.
- If you've baked the field already, rerunning Bake does not delete your manually edited v3 field; remove `Workspace > RIFTBOUND World` yourself **only when you intentionally want to regenerate it**.

## Current limitations / direction

- **This is not the final game world**; a larger environment can be designed later around combat and actual player activities rather than simple NPC-kill grinding.
- Open-world enemy contracts, Void Trial and Rift Sentinel wandering encounter are paused. Your saved progression and Spec ownership have **not** been reset.
- Some story chapters still require levels originally balanced around PvE. This will need a redesigned progression loop (e.g., training challenges, narrative objectives, duels, exploration) rather than farming bandits.
- The optional dungeon still has a dedicated instance-like arena far away from the grass field, using the existing server NPC code.
- Code is committed but **has not been tested inside Roblox Studio**. Inspect Output for `[RIFTBOUND Field]` or script errors after syncing.
