# RIFTBOUND PvE AI 2.0 — Navigation stabilization

The repository already had server-only NPCNavigation and pathfinding-aware CombatNPCs when this task began. This pass **stabilizes the existing system** instead of creating a duplicate AI controller.

## Fixes committed

1. **State transitions**: remove a stray `RiftNPCState="Spawning"` statement that was being run during disengagement, and instead set the spawning state once when an enemy rig is created. Observable states now reflect actual AI transitions: `Spawning`, `Return`, `Idle`, `Chase`, `Fight`, `Stunned`.
2. **Navigation visibility**: use `RaycastParams.RespectCanCollide = true` to ignore non-collidable VFX and scenery when checking if NPCs can travel directly to a target. Obstacles are checked as solid geometry rather than treating a decorative object as proof the entire route is clear.
3. **Pathfinding fallback**: while `PathfindingService:ComputeAsync` is pending, or if a route is unavailable, NPCs stop rather than pushing straight into the very wall that required pathfinding. Retry requests remain throttled and canceled when a pursuit becomes invalid.
4. **Combat wall checks**: line-of-sight attack hits also ignore non-collidable objects that are not valid physical walls.
5. **Windup leash safety**: target distance from the NPC's home position is checked **again when an attack lands**, so leaving the NPC's engagement territory cancels a pending hit.

## Preserved

- `GreatSwordMoves.luau` is unchanged.
- Existing Ashley Simmons, Void Disciple, Abyssal Covenant, combat/mastery/quests/progression and DataStore keys are unchanged.
- No PvP, equipment, storyline, dialogue NPCs or new boss character.
- `NPCNavigation` is still a single server-side module. NPCs still use `Navigation.GoTo/Stop/Clear`.

## Studio regression checklist

Run a fresh **Server & Clients** test after updating the Rojo `src` folder.

- [ ] NPC starts `RiftNPCState = "Spawning"`, then transitions to `Idle` or `Return`.
- [ ] Approaching a Rootbound Scout in Whispering Woods transitions it to `Chase` and then `Fight`.
- [ ] NPC attacks when unobstructed, with a readable windup; no damage when a solid wall is between you and the NPC.
- [ ] Walk behind trees, stones and outcrops: enemy either takes a valid path around the obstacle or waits rather than charging straight into it.
- [ ] Run beyond its home leash during an attack windup: the attack is canceled even if its target was initially valid.
- [ ] Retreat into Haven: enemy should disengage and never damage players inside the safe hub.
- [ ] Parry and hitstun interrupt enemy attacks, including while pathfinding is in progress.
- [ ] NPC returns home, clears `RiftNPCEngaged` and changes state back to `Idle`.
- [ ] Defeated NPC respawns at its original region point and does not inherit an old navigation route.
- [ ] Switching between all three Specs and using the Great Sword's model and Z/X/C/V/G still works.
- [ ] Server Output contains no script runtime errors, especially `NPCNavigation` or `CombatNPCs`.

### Note

These changes passed static source checks, **not** live Roblox Studio testing. Navigation around very large/dynamic obstacles still depends on Roblox's PathfindingService successfully generating a path. A full boss AI system is a *separate next milestone*.
