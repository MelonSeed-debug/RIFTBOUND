# RIFTBOUND — Instructions for AI coding agents

Read this file and `docs/AI_COLLABORATION.md` **before editing code**.

## Project identity
- RIFTBOUND is an anime-inspired **Specs-based** Roblox action RPG with original and anime-inspired Specs, hybrid combat, and long-term progression.
- The immediate development priority is **PvE** (enemy AI, bosses, quests, interconnected open world, stable combat and progression). PvP is explicitly deferred until the PvE build is stable.
- Avoid a repetitive bandit-beater loop. Do not introduce a new story, new NPC dialogue, equipment progression, or PvP without the owner's request.
- Current working/test world and world plans may differ. Do not replace a flat-grass test environment with a large map without approval.

## Existing project and constraints
- Source is Luau, synced via **Rojo** using `default.project.json`; use Roblox Studio for live playtesting.
- Server code: `src/server/`; client UI/input: `src/client/`; shared configs: `src/shared/`.
- Existing systems include combat, Specs, mastery, quests, progression/DataStore, UI, enemy AI, and world generation. Inspect actual modules before assuming anything is missing or broken.
- Preserve `src/server/GreatSwordMoves.luau` and the user's GreatSwordMoves reference; do not overwrite, delete, or refactor it unless expressly approved.
- Preserve existing Specs, animations/assets (including Studio-only imported assets), DataStore keys and saves. Never change persistence format without a reversible migration and explicit approval.
- Keep damage, hit detection, combat cooldowns and authority on the **server**. Treat client RemoteEvent requests as untrusted.
- Follow user preferences: R15, directional dash, M inventory/menu concepts as already implemented, no M1 counter/control-hint overlay, readable non-overlapping UI, skill unlock/mastery thresholds and level cap 50. Verify key bindings and current implementation before changing controls.
- Respect current code over stale README claims; `README.md` describes an earlier Phase 1 snapshot and may be out of date. Read the more specific docs and implementation.

## Mandatory Git safety
1. NEVER commit or push directly to `main`.
2. Use one issue/task per branch and pull request; examples: `arena/fix-m1-lockup`, `chatgpt/audit-progression`.
3. Pull latest `main` at task start; before finalizing, reconcile upstream changes. Do not force-push over another agent's work.
4. Limit changes to requested scope. If another branch touches the same modules, coordinate through the owner and sequence merges.
5. Before each PR, report changed files, reasoning, tests run, Roblox Studio tests still needed, and any migration/data-risk.
6. Do not merge your own PR. The owner reviews diffs, tests in Studio and merges.
7. Never commit passwords, API keys, private data, licensed animation pack files or other assets that lack redistribution rights (the repo is public).

## Highest-priority issues to reproduce and verify
- M1 attacks reportedly stop dealing damage after extended play. Reproduce, investigate combo/attack state, debounce/reset, respawn, hitbox and animation timing; do not rewrite combat without evidence.
- Progression/quest loading previously stalled. `UI_OVERHAUL_2_0.md` documents a session-only fallback; verify saved vs unsaved status and no overwrite of existing DataStore records.
- Then PvE AI reliability, bosses, meaningful quests, open-world architecture, animations/VFX, UI polish and regression tests.
- Preserve all existing functionality while addressing defects.

## Required end-of-task report
- Summary of changes
- Exact paths changed
- Evidence of cause (for bugfixes)
- Automated/static tests run and results
- Roblox Studio playtest steps and outcomes (never claim Studio testing without it)
- PR link and known risks
