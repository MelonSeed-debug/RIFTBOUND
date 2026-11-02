# RIFTBOUND — ChatGPT + Arena AI development workflow

**Repository:** https://github.com/MelonSeed-debug/RIFTBOUND  
**Default branch:** `main` (owner-reviewed, stable integration target)  
**Source of truth:** checked-in Luau code + `default.project.json`. The root README is an older Phase 1 description and needs later revision.

## Why this exists
Use ChatGPT and Arena Agent Mode on the same game without silently overwriting code or breaking Roblox Studio synchronization.

## Roles and ownership
| Participant | Preferred work | Responsibilities |
| --- | --- | --- |
| Project owner | Product direction and acceptance | Decide gameplay priorities; run Roblox Studio / Rojo tests; review and merge PRs |
| Arena AI (Agent Mode) | Focused coding tasks | Inspect repository, edit isolated working branch, run supported checks, open one PR per chat session |
| ChatGPT (GitHub connected) | Audit, architecture, code review, scoped fixes | Inspect repository, plan compatible changes, work on its own branch/PR where approved |
| GitHub | Integration and history | Track branches, commits, reviews, PRs and merges |

**Important:** AI agents cannot verify live Roblox character/physics/DataStore behavior just by reading or statically checking Luau. Owner playtests in Roblox Studio.

## Rules to avoid conflicts
1. No direct changes to `main`. Every task starts from the most recent `main`.
2. **One branch + one PR per task.** Suggested names: `arena/fix-m1-lockup`, `chatgpt/progression-audit`, `arena/pve-ai-navigation`. Arena may generate its own branch: keep that branch and use its PR.
3. Assign different files/features when possible. If both agents need `src/server/init.server.luau` or `src/server/Progression.luau`, complete and merge the first PR, then restart the next agent session from updated `main`.
4. Do not cherry-pick, merge, force-push or overwrite the other agent's work unless the owner asks.
5. Keep a PR small and reversible. Record changed modules, expected behavior, relevant diagnostics, static tests, and Studio reproduction steps.
6. The owner tests the PR in Studio before merging. Merge only after reviewing the full diff.
7. After a merge, fetch/pull latest `main` locally before starting the next task or syncing via Rojo.
8. Never introduce incompatible DataStore changes or erase existing player progress; use safe migrations only with owner approval.

## Arena setup
1. Open https://arena.ai/agent (regular Arena chat is not the same as GitHub-connected Agent Mode).
2. Connect GitHub, grant access to `MelonSeed-debug/RIFTBOUND`, select the repository and toggle GitHub **on**.
3. Give Arena a **single scoped task** and ask it to read this document, `AGENTS.md`, `default.project.json` and related source.
4. Ask for an audit / cause hypothesis first; approve the specific fix; ask for the PR link and changed-file summary.
5. Arena Agent Mode supports **one PR per conversation**. Start a new Agent Mode chat for each subsequent feature after the previous PR is merged or closed.

Arena documentation: https://help.arena.ai/articles/1655691990-how-to-use-coding-in-agent-mode

## ChatGPT setup
ChatGPT has GitHub repository access. Specify which existing feature to work on; ask for an audit or a branch/PR, not changes to `main`. Reference current Arena PRs before requesting overlapping changes. ChatGPT and Arena do **not** automatically share their chat histories; GitHub source, docs, issues and PR descriptions are the common record.

## Recommended issue ownership (initial sequence)
| Priority | Task | First agent | Likely source files |
| --- | --- | --- | --- |
| P0 | Reproduce M1 damage stopping over time; minimal server-authoritative fix | Arena | `src/server/init.server.luau`, `CombatHitbox.luau`, `src/client/init.client.luau`, `src/shared/CombatConfig.luau` |
| P0 | Audit startup, quests and save/load without overwriting saved data | ChatGPT reviews after M1 PR, or Arena in a fresh session | `src/server/Progression.luau`, `QuestService.luau`, `src/client/QuestBoard.luau`, `ProgressionHUD.luau` |
| P1 | NPC navigation and combat AI Studio regression | Either, after P0 fixes | `src/server/CombatNPCs.luau`, `NPCNavigation.luau` |
| P1 | Implement and validate boss AI; PvE combat variety | Either | New server modules + existing PvE services, by approved design |
| P2 | Open-world integration, quest variety, UI responsiveness, animation/VFX polish | Either | Scoping required first |

File lists are **starting points**; investigate dependencies before changes. The repo already has extensive docs including `COMBAT_OVERHAUL_2_0.md`, `UI_OVERHAUL_2_0.md`, `OPEN_WORLD_ARCHITECTURE.md`, and `PVE_AI_2_0_VALIDATION.md`.

## Design guardrails from the owner
- Anime-inspired, Specs-first, original + anime-inspired powers, hybrid combat.
- PvE before PvP; no new story or scripted dialogue until requested.
- Large interconnected exploration world is the long-term goal, but don't replace the flat test grass or generate unapproved maps.
- Avoid bandit-beater progression; encounters, enemies and bosses should be meaningful.
- No equipment RPG progression; maintain game systems already present rather than deleting the inventory/UI wholesale.
- Existing R15 movement and directional dash; existing Specs and GreatSwordMoves reference are protected.
- Level cap: 50; mastery-based skill unlock design, with first thresholds 0, 10, 25, 40. Follow implemented configs where details differ, and flag mismatches.
- No unwanted M1 counter or UI overlay; preserve usable quest/menu HUD.

## Safe PR acceptance checklist
- [ ] Branch is based on latest `main`; no unrelated rewrite.
- [ ] `GreatSwordMoves.luau` and existing Spec behavior preserved.
- [ ] RemoteEvent handling, combat damage and cooldowns remain server-authoritative.
- [ ] Respawn, death, Spec swap, interrupted actions, repeated input and long-session behavior covered.
- [ ] UI/menu/quest visibility, session-only save state and data preservation tested.
- [ ] Roblox Studio **Server & Clients** playtest done where relevant.
- [ ] No errors in Studio Output; negative/edge cases documented.
- [ ] Changes are understood; rollback is possible; owner approves merge.

## How to test a PR with Rojo
1. **Back up** your Roblox Studio place, especially animation clips and manually imported models not stored in Git.
2. Make sure you have committed/stashed any local changes before switching branches.
3. `git fetch origin`
4. `git switch <branch-name>` (or check out the PR locally through GitHub Desktop).
5. Run `rojo serve` from the repository root and connect the Roblox Studio Rojo plugin to the correct place.
6. Use Studio **Play** or **Server & Clients**, run relevant manual tests and read Studio Output.
7. Report results in PR comments. Only after approval, merge the PR in GitHub.
8. `git switch main` then `git pull --ff-only origin main` and reconnect/restart Rojo as needed.

## Ready-to-send Arena prompt
> This is RIFTBOUND, a Roblox Luau + Rojo Specs-based PvE action RPG. Read AGENTS.md, docs/AI_COLLABORATION.md and default.project.json, then inspect the relevant combat modules. Task: reproduce why M1 attacks eventually stop doing damage. Identify the root cause and propose the smallest server-safe fix. Preserve GreatSwordMoves and every existing Spec. Do not change main, quests, UI or DataStores without explicit approval. After making the scoped change, report the cause, file diff, static checks, Roblox Studio test checklist, and create a PR. Do not claim a live Studio test was run unless it was actually run.

## Synchronizing the two AI chats
After Arena opens a PR, give ChatGPT **the PR URL** and ask for a regression/security/design review. After ChatGPT opens a PR, give Arena that PR URL for a second review. If reviews disagree, the owner decides. Do not ask both to fix the same issue simultaneously.

## Repository privacy note
This repository is currently **public**. Keep credentials, personal data and third-party licensed animation/media files out of commits. Imported .rbxm assets may exist only in the Roblox Studio place and will not be included by Rojo unless intentionally managed in source.
