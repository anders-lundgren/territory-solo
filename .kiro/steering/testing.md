---
inclusion: always
---
# Testing Principles

## Goal
The headset is used for **verification only** — specifically for things that require real-world
data or hardware rendering. Everything else runs without one, locally or in CI.

## Test layers (in order of cost)

| Layer | Mode | Assembly | Runs without headset | CLI |
|---|---|---|---|---|
| 1 — Core unit | Edit Mode | `Game.Core.Tests` | ✓ | ✓ |
| 2 — Simulation scenarios | Edit Mode | `Game.Core.Tests` | ✓ | ✓ |
| 3 — Pure algorithms | Edit Mode | `Game.Core.Tests` | ✓ | ✓ |
| 4 — Presentation integration | Play Mode (headless) | `Game.Presentation.Tests` | ✓ (MRUK JSON rooms) | ✓ |
| 5 — On-device | Quest only | — | ✗ | ✗ |

**Layer 5 (on-device) is reserved for:**
- Passthrough rendering quality and color accuracy
- Real MRUK room data (guardian fit, real floor/wall detection)
- 72 fps performance under real load
- M1 turn-around test (subjective feel — cannot be automated)
- Comfort/safety (body walk-through, no physical obstruction)

## TDD workflow

Write the test first, then the implementation. For Core logic this is always possible.
For Presentation: write the test against the extracted plain-C# class before writing the MonoBehaviour shell.

## The "Humble Object" rule for Presentation

MonoBehaviours are thin shells. Logic is extracted into plain C# classes that have no MonoBehaviour dependency:

```
ChunkMeshBuilder (plain C#) ← tested in Edit Mode
  └── ChunkManager (MonoBehaviour) — thin wrapper, tested in Play Mode
```

If a class is hard to test, it has too much responsibility in the MonoBehaviour. Fix the design.

## SimulationRunner

`Game.Core` contains a `SimulationRunner` static class that runs N ticks with a scripted
input sequence. Use it for multi-tick scenario tests and AI behaviour verification.
See `testing-strategy/design.md` for the full API.

## MRUK test infrastructure

MRUK ships ready-to-use test rooms:
- **JSON rooms** (headless, no prefab load): `MeshBedroom1-3`, `MeshLivingRoom1-3`, `MeshOffice1-2`
- **Prefab rooms**: `Bedroom00-09` and others
- **Base class**: `MRUKTestBase` in `Meta.XR.MRUtilityKit.Tests` (already in `testables`)
- Use `MRUK.SceneDataSource.Json` for the fastest headless tests (no asset import)

Presentation tests that touch MRUK should inherit `MRUKTestBase` and load a JSON room.
They do not require a real Quest.

## Coverage targets

| Scope | Target |
|---|---|
| All `Game.Core` rules | 100% — every named rule has at least one test |
| Simulation scenarios (multi-tick) | One per milestone: start, wall death, double death, AI escape, full round |
| GreedyMesher algorithm | 100% of face-count and merge cases |
| Presentation–Core wiring | 1 integration test per M2/M3 system |
| On-device acceptance | Milestone exit criteria only |

## Running tests from the CLI

See `testing-strategy/design.md` for exact commands. Short form:

```powershell
# Edit Mode (Layer 1-3) — always available
.\runtests.ps1 -mode editmode

# Play Mode (Layer 4) — requires a GPU / display server
.\runtests.ps1 -mode playmode
```
