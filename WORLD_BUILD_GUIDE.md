# RIFTBOUND / World Design v2

This is a playable **stylized Roblox interpretation** of the four-island RIFTBOUND concept poster. It is not an exact reproduction of custom 3D models or textures.

## What's included

- **Haven District (safe):** central blue crystal nexus, city blocks, training courtyard, quest hub, three fast-travel portals.
- **Old Quarter (levels 1–10):** close-set neon shops, night market, city street grid, Street Brawler and Street Guard.
- **Ironworks (levels 10–25):** furnaces, smokestacks, cranes, containers, and an open **Rift Sentinel** boss arena.
- **Rift Expanse (levels 25–50):** purple crystals, floating rocks, and an unfinished abyss-citadel/dungeon gate.
- **Four bridges:** Haven to Old Quarter, Haven to Ironworks, Ironworks to Rift Expanse, and Old Quarter to Ironworks.
- **Press N** for the island map with your location marked, **B** for the World Guide, **E** to use nearby fast-travel pads.
- Enemy locations, XP rewards, Void Trial altar, Rift Archivist and training dummy have been moved with the map.

## Installation

You don't have a local git clone, so download the latest repository ZIP:

1. Download the current ZIP from https://github.com/MelonSeed-debug/RIFTBOUND .
2. Replace your local `src` folder with the new `src`; replace `default.project.json` if it changed.
3. Stop Rojo, then run `.\rojo.exe serve` from `C:\Users\danie\Downloads\RIFTBOUND`.
4. Reconnect the Rojo Studio plugin.
5. Run **Server & Clients**. The map auto-generates for a test when none is saved in the place.

## Make it permanent and editable in Studio

Do this **in Edit mode, not while Play is running**:

1. Connect Rojo with the latest project. Confirm `ServerScriptService > RiftboundServer > WorldBuilder` appears.
2. Open Studio **Command Bar** (via View / Window if hidden).
3. Run:

```lua
require(game.ServerScriptService.RiftboundServer.WorldBuilder).Bake()
```

4. In **Explorer**, expand `Workspace > RIFTBOUND World`. You can select and edit every building, crystal, bridge, and ground part.
5. **Save the place** (File > Save to File and/or Publish to Roblox). The map then stays in Edit mode and is reused when you press Play.

The generated map lives under Workspace, which our Rojo project does **not** synchronize, so it won't disappear when you reconnect Rojo.

**Regeneration:** If you want the exact generated map again, delete only the folder `Workspace > RIFTBOUND World` in Edit mode, then run the Bake command again. This will erase any manual edits to that generated folder.

The current map is made of Studio Parts and primitives, not imported meshes. Functional shops, interiors, water swimming, custom terrain sculpting, and proper bridge/pathfinding optimizations come later.

## Test list

- Spawn in Haven. There should be an accessible training dummy and a blue quest-giver.
- Verify Old Quarter and Ironworks are reachable by bridges.
- Press N to see your current location on the island map.
- Check fast travel: Old Quarter requires level 1, Ironworks level 10, Rift Expanse level 25.
- NPCs are currently Studio-only (CombatConfig.NPC.StudioOnly=true). Safe hub is not supposed to be attackable.
- At level 10 with Rift Initiation complete, use the Void Trial altar beside the Sentinel arena.

### Troubleshooting

**Old linear blockout:** Stop Play, sync all new `src` files; the v2 builder replaces old generated v1 worlds.

**No visible map:** Check Studio Output for `[RIFTBOUND World]` errors and whether the `WorldVisuals` and `WorldBuilder` ModuleScripts were synced.

**No permanent geometry:** Runtime-generated Parts disappear after stopping Play; use the Bake command above in Edit mode and save the place.

**Older Baseplate hidden:** The generator hides a large object literally named `Baseplate` to expose the surrounding ocean. To restore it, select that Baseplate and reset Transparency=0 and CanCollide=true. To disable automatic hiding, set `HideDefaultBaseplate=false` in `src/shared/WorldConfig.luau`.

**Important:** No in-Studio playtest has been performed by ChatGPT. Verify movement, NPC paths, and performance after syncing.
