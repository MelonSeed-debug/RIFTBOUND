# RIFTBOUND — Enemy AI 2.0 / PvE milestone

This milestone advances the **PvE world navigation and enemy combat** without adding any story, new dialogue characters, gear/equipment progression, or PvP content. No saved player profile fields, Spec files, animations, Great Sword attachments or imported Studio assets were modified.

## What changed

### Navigation

`src/server/NPCNavigation.luau` is a new **server-only** reusable mover for Humanoid enemies.

- **Direct path:** clear line of sight uses inexpensive `Humanoid:MoveTo`.
- **Obstacle path:** a blocking object triggers `PathfindingService:CreatePath` / `ComputeAsync` on a separate spawned task so NPC combat logic does not wait for a path calculation.
- **Throttled requests:** a given NPC recomputes at most about every 1.8 seconds while pursuing a blocked target; failed paths back off rather than hammering PathfindingService.
- **Stale routes:** changing from Chase to Return/Fight/Strafe invalidates an old path. Late async results do not control a new target or dead NPC.
- **Waypoints:** NPCs follow waypoints, including jump waypoints, and advance as they reach each location.
- **Fallback:** if an obstacle cannot be navigated, movement remains best effort; NPCs never teleport or receive destinations from a client.

### Behaviors

`src/server/CombatNPCs.luau` now uses the navigator for both **pursuit** and **return home**.

- **Guardian:** slower, more frequent blocks, recognizable windup and position holding during close combat.
- **Skirmisher:** quicker attack windup, lower guard chance, and short lateral strafes within its home boundary.
- **Leash:** a pursuer cannot continue chasing a player outside its spawn leash; overshooting its territory also triggers Return. No infinite map-wide chase.
- **Hitstun / parry:** an interrupted windup does not land a hit. NPCs stop pursuing temporarily when staggered.
- **Haven safety:** target selection and the **last moment before a hit** both recheck the world-safe-zone boundary. Walking into Haven during an enemy telegraph cancels the damage.
- **Vertical reach:** enemies avoid locking onto a player many studs above/below their level.
- **Old rig cleanup:** tagged generated NPC models left in a baked previous version are removed when the service starts, without destroying unrelated custom models.
- **Live debug state:** NPCs publish `RiftNPCState` only on changes. Expected values: `Spawning`, `Idle`, `Chase`, `Fight`, `Return`, `Stunned`. `RiftNPCEngaged` indicates aggro.

### World compatibility

`src/server/WorldBuilder.luau` now moves pre-existing generated `RIFTBOUND Story Characters` and `RIFTBOUND Quest Hub` folders to `ServerStorage/RIFTBOUND Archived World Objects` while those features are disabled. **It does not delete them.** This matters for players who had previously baked a v3 world into Studio; those old actors/stations would otherwise remain in Workspace despite the new no-story/no-dialogue direction.

`WorldConfig` stays version 4. The four contiguous regions, Haven safe area, exploration quests, 12 curated enemy spawn points, and three *empty future boss arenas* remain unchanged. No new boss NPC has been added.

## Update and smoke test

1. Back up your Studio place, especially any manually authored content inside `Workspace/RIFTBOUND World`.
2. Get the newest ZIP: https://github.com/MelonSeed-debug/RIFTBOUND and replace the **entire** local `src` directory. Restart `rojo serve` and reconnect the Studio Rojo plugin.
3. Start **Server & Clients** with two clients if possible.
4. In the **server Command Bar during Play**, run the contents of `tools/VERIFY_OPEN_WORLD.lua`, then `tools/VERIFY_ENEMY_AI_2.lua`. These scripts only inspect objects, attributes, and configuration.
5. Verify that the enemy folder has 12 NPC models, each with a Humanoid and HumanoidRootPart. R15 model creation can take time; if counts are short, check Server Output and rerun.
6. Approach a Rootbound Scout in Whispering Woods. It should change from `Idle` to `Chase` and `Fight` as you approach; nearby Guardian-type enemies should sometimes block.
7. Lead an enemy behind solid rocks. It should attempt to navigate around geometry instead of permanently walking into the obstacle. **This specifically needs live Studio testing.**
8. Run away beyond its spawn leash. It should enter `Return`, navigate to its home, and return to `Idle`. It should not chase into another region.
9. Block/parry an enemy attack and check telegraphed attacks cancel if the enemy is staggered before the hit frame.
10. Walk into Haven during an enemy windup (if one is close enough to the edge). The attack must not apply damage once Haven's zone check says protected.
11. Test the three Specs against NPCs. Verify M1, heavy, parry and each Spec ability still work; `GreatSwordMoves.luau` was not changed.
12. Confirm that the quest journal, exploration objectives and saved mastery data remain intact.

## Known limits / next stage

- Code was statically inspected; **Roblox Studio has not been run by the assistant**. The first live session is essential for identifying rig/path costs, line-of-sight corners, movement desync and animation timing.
- This is a foundation, not complete boss AI. Reserved arenas remain empty until the first boss can be properly authored and tested.
- Standard `PathfindingService` can return no valid path for some custom geometry or near-platform edges. Those cases currently back off and use best-effort movement rather than teleporting. A later world-art pass can improve navigation meshes or use authored traversal.
- No multiplayer threat-sharing, ranged projectiles, special boss phases, stealth, full animation packs, or complex coordinated AI has been added yet.
- The old NPC rig generator remains in place for compatibility. Rig appearance generation can take time during server startup.

**Recommended next step:** complete the Studio smoke test above, then implement **Boss AI 1.0** using the reserved Ash Crater arena with readable telegraphs, 2 phases and safe server-authoritative rewards.
