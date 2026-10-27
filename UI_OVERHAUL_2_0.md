# RIFTBOUND UI Overhaul 2.0

This update fixes misleading or indefinite profile/quest loading indicators and improves layout. It **does not reset progression**, erase existing assets, modify the flat-grass map, remove any Spec, or change the user's `src/server/GreatSwordMoves.luau` reference.

## Startup and save-safety behavior

The UI previously showed `RIFTBOUND / LOADING PROGRESS` and `QUESTS LOADING` until `ProgressLoaded` was published by the server. A slow/stalled `DataStoreService:GetAsync` or a progression-module failure could leave both looking frozen.

The server now publishes:

- `ProgressLoadState = "Loading"` while the profile read is pending.
- `ProgressLoadState = "Saved"` after a successful read and safe initialization.
- `ProgressLoadState = "Session"` when DataStore read fails, its initialization raises an error, or the read takes over **18 seconds**.
- `ProgressLoadState = "Offline"` if the progression service fails to load/start entirely.
- `ProgressLoadNote` with a human-readable reason. `ProgressLoaded` now becomes `true` in session-only fallback, so the game remains playable.
- `ProgressSavingEnabled` remains **false** for any unsaved fallback. Existing saved profiles are never overwritten on a failed, pending, or timed-out read.

**Important data-safety rule:** An exceptionally slow `GetAsync` that finishes **after** the 18-second timeout is ignored for the current session. The game does **not** apply stale data late or write its fallback progress over an existing save. Restarting the session can attempt to connect again. Session progress gained while saving is unavailable is temporary.

All existing saved profile keys remain unchanged: `RIFTBOUND_Progression_v1` and `Player_<UserId>`. No migrations or destructive datastore operations were introduced.

## New interface

- **Progression card**: restrained gold/ink theme retained; shows level, XP, coins, defeats, plus a visible status: `CONNECTING`, `SAVED`, `UNSAVED`, or `OFFLINE`. Expanded slightly to fit a clear one-line explanation.
- **Quest journal & tracker**: tells the difference between connecting, offline, saved, and unsaved. Unsaved play is explicitly labeled; story quests remain selectable in the flat-field testing mode. Previous active quests remain recoverable/abandonable.
- **Main menu & Character panel**: shows load/save status alongside the existing character information, Specs, Quests, Inventory, Mastery and Dungeons.
- **Responsive arrangement**: top-left progression, bottom-left health/shield/mastery on roomy viewports, or vertically stacked on smaller viewports. Menu and quest tracker share a consistent top-right margin. Quest tracker hides only on very narrow viewports (width under 550px), where the M menu and J/P keys still open quests.
- **Vitals fix**: expired shields display 0 instead of the stale shield attribute. All three Specs, including Great Sword, update mastery correctly.
- **No unwanted bottom-left control-hint strip or M1 counter UI** added back.

## How to update Studio

1. Stop Play and back up your current **RIFTBOUND place**.
2. Download the latest ZIP from https://github.com/MelonSeed-debug/RIFTBOUND and replace your local **entire `src` folder** (plus `default.project.json` if not already current).
3. Restart `.\\rojo.exe serve` in your local RIFTBOUND folder and reconnect the Rojo Studio plugin.
4. **Do not delete ReplicatedStorage/Workspace animation folders**: these were imported manually and are not part of `src`. Keep your original Great Sword assets and clips.
5. Start **Server & Clients** and watch the **Server Output** for any `[RIFTBOUND Progression]` errors.

## Playtest checklist

- [ ] With Studio API Services enabled and a reachable DataStore, the profile status progresses from `CONNECTING` to `SAVED`; quests change from `CONNECTING` to `STORY QUESTS AVAILABLE` (or show your active quest). Progress still saves across sessions.
- [ ] With Studio API Services disabled, the server logs why DataStore cannot be used. The profile status becomes `UNSAVED` rather than remaining on loading, and quests show `UNSAVED` (they can be tested, but those changes will not persist).
- [ ] If a DataStore request lasts over 18 seconds, session-only mode begins; late results do not overwrite the in-memory fallback or previously saved profile.
- [ ] With a deliberately missing or broken Progression module, the profile and quest panels show `OFFLINE` and the **Server Output** explains why. Combat and HUD remain accessible.
- [ ] Open **M → CHARACTER**: load status is visible. Change Specs and verify Main Menu, Inventory and Quest Journal still open.
- [ ] Test at desktop resolution and narrow/mobile viewports: no overlap between profile, vitals, menu and tracker. On screens under 550px use the M menu or J/P to open quests.
- [ ] Wait for shield expiration: the numeric shield label becomes 0. Equip Abyssal Covenant and confirm Great Sword mastery updates on the vitals panel.
- [ ] Test M1/heavy/parry against the practice dummy. Your Great Sword weapon attachment and real animations remain unchanged.
- [ ] With three Specs, inspect skill sidebar, health, shield, and menus. They should not disappear if an animation fails to load.

## Files changed

- `src/server/Progression.luau` — resilient, non-destructive startup and DataStore watchdog.
- `src/server/init.server.luau` — distinguish progression-service boot failure from ordinary save latency.
- `src/client/ProgressionHUD.luau` — visible save-state indicator and clearer XP card.
- `src/client/QuestBoard.luau` — quest statuses, unsaved warning and journal polish.
- `src/client/MainMenuUI.luau` — save status in menu and character panel.
- `src/client/UIManager.luau` — responsive HUD anchors and menu/tracker alignment.
- `src/client/VitalsHUD.luau` — shield-expiry accuracy and Great Sword mastery refresh.

**Testing note:** Code changes were inspected and statically checked, but full Roblox Studio and real DataStore integration testing must be performed locally before publishing.
