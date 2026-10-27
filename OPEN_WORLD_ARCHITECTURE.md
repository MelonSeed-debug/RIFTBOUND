# RIFTBOUND — Open World 1.0

## Scope

**Build one continuous, playable PvE world** with meaningful geographical regions and reliable, bounded enemy encounters. This is the first world/AI *foundation*, **not** the final authored environment or finished boss roster.

No story chapters, new named dialogue characters, custom conversations, PvP mechanics, equipment or gear progression were added. Prior scripts/saved fields remain in the repository for compatibility. The user-supplied **`GreatSwordMoves.luau` reference is unchanged**.

## Region topology

The world is roughly **2,400 × 2,400 studs**, centered on the place's existing SpawnLocation (or the previous generated world's `SpawnX` / `SpawnZ`). A single physical ground and six road corridors link four visually distinct regions. Walking between them requires no teleport, portal, loading screen, or region instance.

```text
                       NORTH (+Z)

      HIGHLAND RIDGE  ←──Northern Traverse──→  SHATTERED VERGE
            ╲                                    ╱
             ╲ Ridge Trail        Verge Causeway╱
              ╲                                ╱
                      HAVEN (safe hub)
              ╱                                ╲
             ╱ Woodland Path         Ember Road ╲
            ╱                                    ╲
     WHISPERING WOODS ←──Southern Traverse──→ CINDERFALL

                       SOUTH (−Z)
```

Coordinates are **local offsets** from the original spawn anchor. Areas are stylistic/encounter regions, not collision walls. The base between circular biome surfaces is traversable wilderness.

| Area | Local center (X, Z) | Recommended level | Initial identity |
|---|---|---|---|
| Haven | (0, 0) | Any | safe circular origin, beacon pillars, preparation/training |
| Whispering Woods | (-485, -205) | 1+ | forest canopy, fallen-ridge trees, rooted scouts and guardians |
| Cinderfall | (510, -225) | 12+ | ash colors, basalt outcrops, glowing embers, speedy hunters and blockers |
| Highland Ridge | (-490, 525) | 23+ | weathered stone landmarks, rock formations, defensive sentinels and agile hunters |
| Shattered Verge | (520, 550) | 36+ | violet fracture crystals and high-threat enemies |

The terrain is a **simple procedural Block/Part-based first pass**: biome pads, road slabs, trees, stone props, ash outcrops, crystal groups and region signs. It is not yet a sculpted Roblox Terrain landscape, final art, water/river system or complete navigation mesh. Later visual passes can replace geometry while keeping **WorldConfig zone IDs** stable.

## Server architecture

- `src/shared/WorldConfig.luau` — world version 4, biome data, safe radius, paths, fixed enemy coordinates, reserved future boss arenas and a pure `GetZoneAt(localPosition)` function.
- `src/server/WorldBuilder.luau` — creates/reuses the versioned generated world folder, resolves spawn-relative origin and ground height, builds one continuous floor, biome overlays, roads and seeded scenery, marks `Version=4` **only after generation succeeds**, and tracks zone/safety on players every 0.45 seconds.
- `src/server/CombatNPCs.luau` — the existing server-owned R15 enemy rig/combat service, now using 12 curated world spawns and two baseline archetypes, **Skirmisher** (sidesteps, faster windup) and **Guardian** (more blocking, slower windup). Targets must be nearby and within the spawn leash. Safe Haven prevents NPC pursuit/attacks against protected characters.
- `src/shared/CombatConfig.luau` — enables these curated encounters and uses a 15-second respawn pause (no rapid ambient swarm).
- `src/shared/LevelConfig.luau` — defines eight enemy reward entries, without adding equipment drops or changing level/save formats.
- `src/shared/QuestConfig.luau`, `src/server/Progression.luau`, `src/client/QuestBoard.luau` — four one-time exploration quests. The server's **RiftZone** attribute drives discovery credit; no client-sent completion requests are accepted. Quests are available at level 1; recommended region levels express danger, not physical gating. The old saved quest list is **not deleted**, and a previously active legacy quest can still be abandoned.
- `src/server/QuestService.luau` — retains the secure J/M quest-journal RemoteEvents and request validation; disables old prewritten physical quest stations for this world.
- `src/client/ZoneHUD.luau` — unobtrusive region name, safe status and recommended level indicator. Zone identity remains server-owned.
- `src/server/init.server.luau` — pauses boot of prewritten story characters and legacy off-map dungeon portals while leaving their modules available for later approved content.
- `src/client/init.client.luau` — optionally loads ZoneHUD without blocking combat or core menu initialization.

### Future-ready flags in WorldConfig

```lua
EnableStoryActors = false
EnableQuestStations = false
EnableWorldEnemies = true
EnableDungeon = false
```

Do not switch story/dialogue/dungeon flags back on until those systems are intentionally located and integrated into this world. The existing legacy dungeon entrance and its coordinates belong to the former testing map.

## Content roadmap after this foundation

1. **World Playtest and Navigation** — validate Roblox Studio physics, existing spawn/ground height, safe Haven radius, cross-region travel, performance, waypoint navigation and collision-free encounter areas. Replace crude road junctions and props with authored terrain/meshes.
2. **Enemy AI 2.0** — add obstacle-aware/pathfinding pursuit, enemy attack sets, defensive reactions, better telegraphs, leash reset, threat scaling and reliable combat regression tests for all three Specs.
3. **Boss AI 1.0** — implement one boss encounter in an existing arena with server-owned phases, readable telegraphs, punish windows, health reset rules, arena boundaries and persistent reward hooks. Only after testing, populate the other two reserved arenas.
4. **World content, then quest breadth** — after the user defines NPCs/dialogue, add them intentionally. Build quests around exploration, interaction and boss trials, not repeated bandit farming. No required story at this stage.
5. **Final PvE build** — optimize geometry/enemy activation radius, finalize Spec mastery and leveling, playtest saved profiles, add polish/UX/accessibility and then revisit PvP only afterward.

## How to install and test

1. **Back up your place** (.rbxl/.rbxlx) and stop Play.
2. Download the latest **whole repository ZIP** at https://github.com/MelonSeed-debug/RIFTBOUND .
3. Replace the **entire** local `src` folder and ensure `default.project.json` is current; **do not** replace the Studio-imported `150+ Weapon Animations & Models` or `RIFTBOUND Weapon Assets` folders.
4. Restart `.\\rojo.exe serve` from that folder and reconnect Rojo in Roblox Studio.
5. Use a fresh Play session. `Workspace/RIFTBOUND World` should report `Version = 4`, `WorldMode = OpenWorld` and `WorldStyle = Contiguous Open World`. The old v3 **generated** grass folder is replaced. The character should spawn at Haven.
6. Verify the server Output prints `[RIFTBOUND World] OPEN WORLD READY` and `[RIFTBOUND NPC] Starting 12 curated enemies...`. NPC visual models can take extra time to create in Studio because Roblox may need to generate R15 humanoid appearances.
7. Confirm `RiftZone = Haven` and `RiftSafeZone = true` in the character. Walk the western road into the Woods and check it changes to `WhisperingWoods` and `false`.
8. Open **J** (or M → QUESTS), accept **Into the Woods**, enter/stand in Whispering Woods; the quest count should become 1/1. Claim reward. Repeat other exploration quests. Quests are **not a story** and require no dialogue actor.
9. Fight Rootbound Scouts and Thornback Guardians. Check hitstun, guard, sidesteps, death rewards and respawns after 15 seconds. Try leaving combat: NPC should not chase beyond its configured home leash. Return to Haven and confirm enemies do not attack there.
10. Visit Ash Crater, Skyhold Circle and Rift Sanctum. They are **empty arena foundations**, not playable boss fights yet.
11. Equip **Abyssal Covenant**; check the imported model stays equipped and M1, R and Z/X/C/V/G still work. Great Sword source code was untouched.
12. Test a narrow viewport and 2-player Studio session if possible. Check the optional zone banner doesn't obstruct menus.

### Known limitations and safeguards

- **No Roblox Studio runtime testing has been performed here.** Static source checks cannot prove platform API behavior, replication, pathfinding, spawn collision or device frame rates. If Output shows an exception, share its exact line and message.
- Parts/biome discs are intentionally a **prototype**. Long-distance streaming, terrain LOD, water, vertical traversal, navigation meshes and actual boss attacks have not been completed yet.
- Dialogue modules, inventory/economy data and saved old quest IDs remain for compatibility; their previous named actors and old quest stations are not newly spawned in this build. No new gear or shop content was introduced.
- Map code replaces only the folder named `RIFTBOUND World` when it has an outdated world version. Manual scenery **outside** that generated folder is retained. If you previously baked personal scenery **inside** the generated folder, back it up before testing the version upgrade.
- Global player PvP is not implemented or expanded by this milestone. Existing combat remote architecture is retained so future PvP can be intentionally designed after PvE is finished.
- The saved DataStore key and existing Spec unlock/progression profile format are unchanged.
- If you want to make this procedural world permanent in the Studio place, use the **Server Command Bar in Edit mode** after Rojo sync:
  `require(game.ServerScriptService.RiftboundServer.WorldBuilder).Bake()`
  Then save/publish the place. Otherwise the same map is generated automatically on server start.
