---
inclusion: always
---
# Project: Voxel Territory (working title)

A mixed-reality territory-control game for Meta Quest 3-class devices. A snake-like head moves through a 3D voxel grid anchored to the player's real room, leaving permanent wall voxels. Colliding with any wall ends the round. v1 is solo vs. one AI.

## Platform
- Target: Meta Quest 3 / 3S (color passthrough required — confirmed)
- Engine: Unity 6 (Unity 6000.x), URP 17.5.0
- XR: OpenXR + Meta extensions — `com.unity.xr.openxr` 1.17.1 + `com.unity.xr.meta-openxr` 2.5.0
- Scene understanding: MRUK 203.0.0 (`com.meta.xr.mrutilitykit`)
- No legacy Oculus XR Plugin (`com.unity.xr.oculus` is absent from manifest)

> Meta's tooling evolves fast. Before using any XR class not covered in `xr-stack.md`, read the
> current docs first — do not rely on training-data assumptions about Meta APIs.
> See `.kiro/steering/xr-stack.md` for the approved API surface and forbidden patterns.

## XR decisions (M0 is done — stack confirmed)
The M0 XR stack decision is settled: OpenXR + `com.unity.xr.meta-openxr` + MRUK. Record this in DECISIONS.md if not already done. The "lead's existing anchor harness" that earlier docs referenced used `OVRSpatialAnchor`; with MRUK the room itself is the anchor — see `xr-stack.md` for the replacement pattern.

## v1 scope — nothing more
Build exactly the v1 Definition of Done (AGENTS.md). Everything in ROADMAP.md is deferred. Do not build ahead into multiplayer, phone spectator, or the Centipede showcase.

The only forward investments v1 makes are nearly free:
1. Deterministic, serializable simulation
2. Clean logic/render seam (Game.Core ↔ Game.Presentation interface)

## Key docs
| File | Purpose |
|---|---|
| `AGENTS.md` | Prime directives and operating instructions — read before writing any code |
| `SPEC.md` | Full v1 specification |
| `DECISIONS.md` | Settled decisions (ADR-lite) — do not reverse silently |
| `BUILD_PLAN.md` | Milestones M0–M4 with exit criteria |
| `ROADMAP.md` | Post-v1 phases — read for seam awareness; do not build |

## Build order
M0 → M1 (gate) → M2 → M3 (v1 ship) → M4 (buffer). Never skip or reorder. M1 is a hard gate.
