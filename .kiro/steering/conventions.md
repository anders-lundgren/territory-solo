---
inclusion: always
---
# Conventions

## Namespaces
Mirror assemblies: `Game.Core.*`, `Game.Presentation.*`, `Game.App.*`

## Testing
- Every Game.Core rule gets an edit-mode test (Unity Test Framework, EditMode assembly)
- Coverage required: movement, trail-laying, collision (wall + boundary), win condition, state serialization round-trip
- Tests run without a headset or scene — Core is designed for this; use that

## Commits
Reference the milestone and exit criterion being advanced:
- `M0: state snapshot round-trips in edit-mode test`
- `M2: walls regenerate dirty chunk only`
- `M3: round resets and re-seeds after double death`

## Walls / voxels
- Never instantiate a GameObject per voxel — ever
- Greedy-mesh coplanar faces within fixed-size chunks; regenerate only dirty chunks when trail grows
- Chunk size recommendation: 8×8×8 cells

## XR API — no OVR** in game code
Game code (Game.Core, Game.Presentation, Game.App) must not use `OVRCameraRig`, `OVRManager`, `OVRPassthroughLayer`, `OVRSpatialAnchor`, `OVRInput`, `OVRScene`, or any other `OVR*` class.
See `xr-stack.md` for the approved replacements. MRUK's internal code uses OVR** — that is fine and invisible to game code.

Before using any Meta or XR class not listed in `xr-stack.md`: fetch the current docs.
The package versions in this project (`com.unity.xr.meta-openxr` 2.5.0, MRUK 203.0.0) are recent; training-data APIs may be outdated.

## Safety (hard requirement, not polish)
- Walls are obstacles to the **snake** and pure visuals to the **player**
- Player body has no collision with walls — no Collider on wall meshes (or trigger-only if needed for other purposes)
- Play volume must fit comfortably within guardian

## Decisions
- Do not silently reverse any decision in DECISIONS.md
- If implementation reveals a decision is wrong, stop and surface it explicitly:
  what broke / which decision (D#) / what you propose instead
- Settled decisions are not open for re-litigation; post-M1 decisions record outcomes (D4, double-death tiebreak)
