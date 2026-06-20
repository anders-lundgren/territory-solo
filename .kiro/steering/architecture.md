---
inclusion: always
---
# Architecture

Three assemblies with enforced dependency direction (asmdef files). This separation is structural, not stylistic — it is the exact seam a phone spectator (Phase 5) and remote peer (Phase 4) will attach to later.

## Game.Core
- Pure C#, **zero** dependency on UnityEngine rendering, physics, or XR
- Owns: logical grid (`HashSet<Vector3Int>` occupied-cell store), fixed-tick simulation, snake movement, trail-laying, collision, win/loss, round lifecycle, serializable state snapshot
- Must compile and be fully testable in edit-mode with no headset and no scene

## Game.Presentation
- MonoBehaviours, voxel meshing, XR rig, passthrough, effects
- Subscribes to Game.Core state/events; never owns game truth
- Renders a view of Core state; all authoritative state lives in Core

## Game.App
- Composition root: wires Core ↔ Presentation, owns scene and bootstrapping

## Key invariants (non-negotiable)
- **Logic/render separation**: Presentation talks to Core only through state snapshots and events. Core never knows rendering exists.
- **Collision is O(1) set membership**: `occupiedCells.Contains(nextCell)` — not a physics query.
- **Integer grid math**: cell coordinates are `Vector3Int`; no floats in authoritative state. No positional drift.
- **Fixed tick, frame-independent**: simulation runs on its own cadence regardless of render frame rate.
- **Deterministic**: same inputs → identical state on any machine.
- **Serializable state**: full round state (occupied cells, snake heads/headings, status) round-trips through serialize/deserialize.
- **No per-voxel GameObjects**: walls are rendered by greedy-meshing coplanar faces within fixed-size chunks.
