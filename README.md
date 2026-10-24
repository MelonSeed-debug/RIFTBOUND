# RIFTBOUND

RIFTBOUND is an original anime-inspired Roblox Spec fighting RPG. This repository contains its **Phase 1 combat prototype**, synchronized to Roblox Studio with [Rojo](https://rojo.space/).

## Implemented in Phase 1
- Server-validated four-hit M1 combo with increasing damage and a final-hit knockback.
- Directional F blocking with movement penalty.
- Q dash with a server-enforced cooldown.
- PC, gamepad, and touch controls (ContextActionService).
- Simple local hit/block effects and an on-screen control guide.
- A training dummy that appears **only when testing in Roblox Studio**.

No paid assets, anime IP, animations, Spec unlocks, progression, or DataStores are included yet.

## First-time setup

1. Install **Roblox Studio**, **Git**, and **Rojo CLI v7** (see https://rojo.space/docs/v7/getting-started/installation/).
2. Install the matching **Rojo Studio plugin**.
3. Clone this repository locally using GitHub Desktop (Repository > Clone) or:
   \`\`\`bash
   git clone https://github.com/MelonSeed-debug/RIFTBOUND.git
   cd RIFTBOUND
   \`\`\`
4. From the repository's root folder, run:
   \`\`\`bash
   rojo serve
   \`\`\`
5. Open Roblox Studio and create a **Baseplate** place. In the Rojo Studio plugin, connect to the local Rojo server. Confirm you are syncing this project, not an existing production place.
6. Press **Play** (not Run). Find the red **Training Dummy** near the center of the baseplate, walk into range, and click or tap Attack.

### Controls
| Action | Keyboard/mouse | Gamepad | Touch |
| --- | --- | --- | --- |
| M1 combo | Left mouse button | R2 | Attack button |
| Block | Hold F | Hold L2 | Hold Block |
| Dash | Q | B | Dash button |

## Roblox instance layout
- \`ReplicatedStorage/Riftbound/Shared/CombatConfig\`: shared combat values.
- \`ReplicatedStorage/Riftbound/Remotes/CombatRequest\`: client-to-server requests.
- \`ReplicatedStorage/Riftbound/Remotes/CombatFX\`: server-to-client cosmetic effects.
- \`ServerScriptService/RiftboundServer\`: validation, damage, and training dummy.
- \`StarterPlayer/StarterPlayerScripts/RiftboundClient\`: inputs and effects.

## Security notes
All damage, combo counts, hitboxes, dash speed, and cooldowns are computed on the **server**. The client sends only a requested action; the server ignores unsupported actions or invalid combat states. Never place game-critical damage decisions in client scripts.

## Next phases
- Spec framework (base skills, passives, R/Z/X/C/V, awakenings).
- Proper character animations, VFX and audio.
- Stun, combo protection, parry / guard-break, PvP balancing.
- Persisted player data, quests, world and bosses.

## Debugging
Use Roblox Studio **View > Output** to inspect script errors. Rojo only synchronizes local source files into Studio; GitHub changes reach Studio after you pull them to your local clone. This code hasn't been playtested in your Roblox Studio installation yet.
