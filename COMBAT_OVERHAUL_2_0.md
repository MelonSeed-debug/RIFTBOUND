# RIFTBOUND — Combat Overhaul 2.0

This is an **incremental improvement**, not a replacement for the RPG, three Specs, imported animation pack or flat-grass field. Changes are in server-owned scripts and do not reset saved profiles.

## The changes

**Server-authoritative swept hitboxes** — `src/server/CombatHitbox.luau` now gathers unique valid Humanoid targets across three slightly rotated hitboxes along a short arc at the server's impact frame. This handles near-edge sidesteps and weapon models nested inside an R15 character. Its query does not accept client-supplied target lists, damage, coordinates or timing. Each target can be hit only once per attack.

**Combo rhythm and input buffering** — Unarmed keeps a quicker four-hit chain and a shorter reset window. Great Sword uses its tuned 0.24-second M1 swing hit marker and longer combo window; its heavy windup is 0.55 seconds with a longer recovery. A single M1 click within the **final 240ms of recovery** can be buffered to continue a chain without dropped inputs; earlier button mashing cannot queue infinite auto-attacks. The buffer cancels on stun, Spec change or respawn. Extra sword range/damage remains server-only. Attacks carry an internal serial so a stunned character cannot finish a previously scheduled swing.

**True server hitstun** — Valid M1 and heavy damage temporarily block the victim's M1, R, F, Q and Z/X/C/V/G starts. The defender's combat state is cancelled, and movement is briefly slowed. Repeated hits refresh the stun deadline without permanently capturing the reduced walk speed. NPCs also honor the hitstun. A Studio training dummy remains an endlessly reusable practice target and does not become permanently stunned.

**Parry / block / guard break** — Press F just before a real incoming strike to earn a perfect parry (default 0.25s). A perfect parry staggers the attacking player; holding F protects against normal M1 strikes, while a heavy strike breaks the guard and briefly staggers the defender. Direction and hit timing are validated by the server; repeated F taps do not reset the parry window until its cooldown ends.

**Counterattack** — After a successful perfect parry, the defender has a **1.05-second punish window**. The next accepted M1 or heavy consumes that window and gains a small damage bonus (**1.25× unarmed / 1.18× Great Sword**). The client receives a `COUNTER!` indicator, but never authorizes the damage increase. Whiffing your punish still consumes the reward.

**Weapon identity** — Great Sword has wider reach, greater damage, slower recovery and a heavier stagger than unarmed/Ashley/Void's basic moves. All three Specs retain their existing skill abilities and separate mastery tracks.

## How to update

1. Stop Play in Roblox Studio.
2. Download the latest ZIP from https://github.com/MelonSeed-debug/RIFTBOUND .
3. Replace the **entire** local `src` folder, including the new `src/server/CombatHitbox.luau` and updated `src/shared/CombatConfig.luau`.
4. Restart `.\\rojo.exe serve`, reconnect the Rojo plugin and verify the modules are visible in Studio.
5. Use **Server & Clients** with **two players** to test real PvP and guard timing. The optional 500 HP practice dummy has infinite refills for solo-hitbox tests. Keep original .rbxm animations already imported into the place.

## Tests to run

- [ ] With no Spec equipped, left-click four times: normal hits deal 7/7/9/12 base damage. The fourth attack has a finisher delay and knockback.
- [ ] Click M1 up to 240ms before its next swing is ready: the input should buffer **once** and fire at the correct time. Hold/click-spam rapidly: it must not bypass normal attack cooldowns or queue an endless combo.
- [ ] Equip Great Sword from M → SPECS. Its sword M1 should have longer reach and slower recovery than unarmed. It should still only damage one target once per swing, even though the query sweeps three slightly different angles.
- [ ] Swing at another player who moves sideways slightly. A clearly in-range attack near the side of the arc should hit more reliably than the old single-box version.
- [ ] Hold F before being attacked head-on: regular M1 shows BLOCKED and deals no damage. Attack from directly behind: guard should not work.
- [ ] Tap F within a quarter-second before the attack lands: the defender shows PARRY and the attacker staggers. Immediately release F and press M1 within ~1 second for a COUNTER indicator and bonus damage.
- [ ] Try spamming F: repeated taps within the parry cooldown do **not** grant new perfect-parry windows.
- [ ] Hold F against a heavy attack: the defender suffers GUARD BREAK / temporary stagger instead of permanent blocked status. Test Great Sword and unarmed separately.
- [ ] While staggered, try M1/R/F/Q or a Spec ability: the server rejects the action. Once stagger has ended, normal inputs work again.
- [ ] Stun a player mid-heavy windup: their pending hitbox should **not** inflict damage afterward.
- [ ] Attack the dummy for over 500 cumulative damage: the test target should continue accepting hits after the health refill. Normal NPC/dungeon hit registration remains available.
- [ ] Repeat with two clients at different ping levels if possible; all hit validation should remain on the server, never the client.
- [ ] Unequip/equip Great Sword and respawn while fighting: no permanently stuck weapon animations, attack state, guard or movement.
- [ ] Verify the UI still loads even with no published animation IDs. Animation failures retain procedural fallback and never gate UI startup.

## Current limitations

- This patch improves server hit detection, but **has not yet been playtested inside Roblox Studio**. Animation feel, collision with detailed scenery, hitstun balance, player latency and weapon gripping should be tuned after live testing.
- Hits are validated at the server impact frame with a brief arc sweep; this is not full client-predicted rollback/netcode. High latency can still affect perceived timing.
- Z/X/C/V/G abilities keep their existing ability-specific hitboxes. Their cast starts are now blocked by hitstun, and Great Sword skill damage also applies stagger; this overhaul concentrates on the shared M1/heavy/block/parry loop.
- No new bandit spawns, kill-grind quests, PvP ranking, duels, new map or saved-data resets are introduced.

## Files

- New `src/server/CombatHitbox.luau` — authoritative arc query and shared hitstun.
- Changed `src/server/init.server.luau` — combo sequencing, PvP state, defense, parry, punish and knockback.
- Changed `src/shared/CombatConfig.luau` — combat balance options.
- Changed `src/server/CombatNPCs.luau` — NPC parry reward and stun connection.
- Changed `src/server/GreatSwordMoves.luau`, `src/server/AshleyMoves.luau` and `src/server/VoidDiscipleMoves.luau` — stun-aware skills.
- Changed `src/client/init.client.luau` and `src/client/CombatAnimations.luau` — stagger and counter presentation.
