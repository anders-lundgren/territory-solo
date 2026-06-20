# Testing Strategy Requirements

## Overview
Establish a test-driven development infrastructure that lets the vast majority of game logic
be verified from the CLI or editor without a headset. The headset is reserved for things that
genuinely require hardware: passthrough rendering, real room geometry, the M1 turn-around test,
and final 72fps performance validation.

---

## REQ-TEST-1: Edit Mode test suite for all Game.Core rules
Every named rule in `Game.Core` (movement, trail, collision, win condition, serialization, AI
behaviour) must have at least one passing edit-mode test. Tests must run without a scene,
without a headset, and without any rendering or XR dependency.

**Acceptance criteria:**
- `Game.Core.Tests` EditMode assembly compiles and all tests pass via CLI batchmode
- Coverage: `SnakeHead`, `TickSimulation`, `AiController`, `GameState` serialization, round lifecycle
- Running `unity -batchmode -runTests -testPlatform editmode` exits 0

---

## REQ-TEST-2: SimulationRunner for multi-tick scenario tests
A `SimulationRunner` utility in `Game.Core` drives `TickSimulation` for N ticks with a
scripted input sequence, enabling scenario-level tests (not just unit tests).

**Acceptance criteria:**
- `SimulationRunner.RunToCompletion(sim, inputs, maxTicks)` returns final `GameState`
- `SimulationRunner.RunCapturing(sim, inputs, maxTicks)` returns a `List<GameState>` for per-tick inspection
- Scenario tests cover: player drives into wall, AI drives into wall, simultaneous death (draw),
  full round played to completion, grid fills to boundary
- All scenario tests run in Edit Mode with no scene

---

## REQ-TEST-3: GreedyMesher tested as a pure algorithm
`GreedyMesher` is implemented as a pure static class (no MonoBehaviour, no Unity rendering API
calls) so it can be tested in Edit Mode. Tests cover face count, face merging, and chunk
boundary handling.

**Acceptance criteria:**
- Single occupied cell → output mesh has exactly 6 quads (one per face)
- Two adjacent cells sharing a face → 10 quads (shared face pair merged into one, not two)
- Chunk boundary: cell at chunk edge → faces on the boundary are included; no out-of-bounds access
- All tests run in Edit Mode (Edit Mode assembly, no scene)

---

## REQ-TEST-4: Coordinate math testable in isolation
`LogicalToWorld` (cell → world position) and `ChunkKeyFor` (cell → chunk key) are pure
functions in plain C# classes, testable without a MonoBehaviour or scene.

**Acceptance criteria:**
- `LogicalToWorld(Vector3Int.zero, ...)` returns play volume origin
- `LogicalToWorld((1,0,0), ...)` returns origin + (cellSize, 0, 0)
- `ChunkKeyFor` correctly classifies cells into chunks at and around chunk boundaries
- Tests run in Edit Mode

---

## REQ-TEST-5: Presentation integration tests using MRUK JSON rooms (no headset)
Presentation systems that depend on MRUK (specifically `PlayVolumeAnchor`) are tested in
Play Mode using MRUK's built-in JSON room data. No real Quest is needed.

**Acceptance criteria:**
- `Game.Presentation.Tests` PlayMode assembly compiles and tests pass headlessly
- `PlayVolumeAnchorTests` uses `MRUKTestBase` + a JSON room (e.g. `MeshOffice1.json`) to verify
  the play volume is positioned correctly relative to the floor center
- `ChunkManagerTests` verifies that adding cells to `TickSimulation` results in the correct number
  of dirty chunk rebuilds (in a lightweight scene with no XR rig)
- All Play Mode tests pass via `unity -batchmode -runTests -testPlatform playmode`

---

## REQ-TEST-6: CLI test runner script
A script (`runtests.ps1`) at the project root discovers the installed Unity executable and runs
the test suites without opening the editor UI.

**Acceptance criteria:**
- `.\runtests.ps1 -mode editmode` runs Layer 1-3 tests and outputs results to `TestResults/`
- `.\runtests.ps1 -mode playmode` runs Layer 4 tests similarly
- `.\runtests.ps1 -mode all` runs both suites sequentially, fails fast if editmode fails
- Exit code is non-zero on any test failure
- Works on Windows with Unity installed via Unity Hub

---

## REQ-TEST-7: Test fixtures and room data checked into the project
Game-specific test room data (a compact room fixture sufficient for the play volume) is stored
under `Assets/Tests/Rooms/`. This decouples tests from MRUK's shipped room data paths, which
may change between MRUK versions.

**Acceptance criteria:**
- At least one JSON room fixture exists at `Assets/Tests/Rooms/TestRoom.json`
- The fixture describes a room large enough to contain a 2m × 2m × 2m play volume
- Tests reference this fixture by project-relative path, not by package cache path

---

## REQ-TEST-8: Performance benchmark for GreedyMesher
A Unity Performance Testing benchmark asserts that `GreedyMesher.Build()` for a full
8×8×8 chunk completes within budget (target: < 2ms on the test machine).

**Acceptance criteria:**
- One `[Performance]` test using `Unity.PerformanceTesting` measures `GreedyMesher.Build()` throughput
- The median sample is < 2ms for a 512-cell chunk (all cells filled)
- Test runs in Edit Mode
