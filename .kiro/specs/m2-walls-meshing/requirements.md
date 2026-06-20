# M2 Requirements: Trail, Walls, Meshing, Legibility

## Overview
The head leaves a permanent, readable wall structure. Rendering must perform on-device. Legibility features (see-through walls, visible world-frame) are built here, not deferred.

---

## REQ-M2-1: Persistent trail in Game.Core
Each cell vacated by the snake head is added to the occupied-cell store as a permanent wall.

**Acceptance criteria:**
- `GameState` contains a `HashSet<Vector3Int> occupiedCells` (or equivalent O(1)-lookup collection)
- After N ticks from start, `occupiedCells.Count == N` (each vacated cell added exactly once)
- Re-entering an occupied cell is detectable via `Contains()` — used by M3 collision
- The occupied-cell set is included in state serialization and round-trips correctly

---

## REQ-M2-2: Chunked greedy meshing (no per-voxel GameObjects)
Walls are rendered by greedy-meshing coplanar faces within fixed-size chunks. Only dirty chunks regenerate when the trail grows.

**Acceptance criteria:**
- The volume is partitioned into fixed chunks (8×8×8 cells recommended)
- Adding a wall cell marks its chunk(s) dirty; only dirty chunks regenerate their mesh on the next frame
- Draw call count does not scale 1:1 with voxel count (verified in Unity frame debugger)
- Frame rate holds at 72 fps with a near-full volume on-device (50% and 90% fill tests)
- No GameObject is instantiated per voxel — ever

---

## REQ-M2-3: See-through wall material
Walls use a see-through or wireframe-ish material so the structure is readable from inside the embedded play volume.

**Acceptance criteria:**
- The player can read the overall wall structure — open corridors, dead ends, entrapment — while standing inside the volume
- Individual wall cells are visually distinct (not a single opaque block)
- Material works in passthrough without depth or blending artifacts against real-world content

---

## REQ-M2-4: Visible world-frame (required, not optional)
A persistent world-frame overlay makes world-axis directions findable when the player is rotated inside the volume. Required regardless of which control model passed M1.

**Acceptance criteria:**
- At least one world direction is unambiguously identifiable at a glance (e.g. distinctly colored boundary face or axis edges)
- The world-frame is present at all times during play
- Implementation does not materially obstruct the playfield or passthrough
