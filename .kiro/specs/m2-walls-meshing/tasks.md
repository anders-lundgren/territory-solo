# M2 Tasks: Trail, Walls, Meshing, Legibility

- [ ] 1. Add occupied-cell store to GameState
  - Add `HashSet<Vector3Int> occupiedCells` (runtime) and `List<Vector3Int> occupiedCellsList` (serialized)
  - Implement `BeforeSerialize()` / `AfterDeserialize()` conversion helpers
  - Expand serialization round-trip test to include a non-empty occupied set
  - _Requirements: REQ-M2-1_

- [ ] 2. Persist trail in TickSimulation
  - Record `previousPosition` before calling `head.Advance()`
  - Add `previousPosition` to `occupiedCells` after advance
  - Raise `OnCellAdded(Vector3Int)` event for Presentation to consume
  - Write edit-mode test: after N ticks from start, `occupiedCells.Count == N`
  - Write edit-mode test: state serialization round-trip preserves occupied set
  - _Requirements: REQ-M2-1_

- [ ] 3. Implement ChunkManager in Game.Presentation
  - Define `CHUNK_SIZE = 8` and `ChunkKeyFor(Vector3Int cell) → Vector3Int`
  - `ChunkManager` MonoBehaviour with `Dictionary<Vector3Int, ChunkRenderer>` and `HashSet<Vector3Int> _dirty`
  - Subscribe to `TickSimulation.OnCellAdded`; mark affected chunk key dirty
  - In `LateUpdate`: rebuild all dirty chunks, clear dirty set
  - _Requirements: REQ-M2-2_

- [ ] 4. Implement GreedyMesher
  - `GreedyMesher.Build(HashSet<Vector3Int> cells, Vector3Int chunkMin, int chunkSize, float cellSize) → Mesh`
  - For each of 6 face directions: iterate slices, build face mask, greedy-extend rectangles, emit quads
  - Return a `Mesh` with correct vertices, triangles, normals, and UVs
  - Unit test (edit-mode): single cell → 6 quads; two adjacent cells sharing a face → 10 quads (shared face merged)
  - _Requirements: REQ-M2-2_

- [ ] 5. Implement ChunkRenderer
  - `ChunkRenderer` owns a child GameObject with `MeshFilter` + `MeshRenderer`
  - `Rebuild(HashSet<Vector3Int> cells, Vector3Int chunkKey)` calls `GreedyMesher.Build()` and assigns result
  - Uses the see-through wall material (Task 6)
  - _Requirements: REQ-M2-2_

- [ ] 6. Create see-through wall material
  - Create a URP material: transparent surface, alpha blend, depth write off, base alpha ~0.35
  - Optionally add a rim/fresnel effect to highlight cell edges
  - Test in passthrough on-device: wall structure legible from inside, no depth artifacts
  - _Requirements: REQ-M2-3_

- [ ] 7. Performance verification on-device
  - Fill volume to ~50% capacity; check frame rate in Unity Profiler / OVR Metrics Tool
  - Fill volume to ~90% capacity; repeat
  - Confirm 72 fps holds; confirm draw calls in Frame Debugger do not scale 1:1 with cell count
  - If performance is insufficient: reduce cell size, reduce chunk size, or profile GreedyMesher rebuild cost
  - _Requirements: REQ-M2-2_

- [ ] 8. Implement WorldFrameRenderer
  - Create `WorldFrameRenderer` MonoBehaviour in Game.Presentation
  - Render the 12 boundary edges with per-axis color coding (X=red, Y=green, Z=blue) using LineRenderer or baked mesh
  - Use a solid unlit material so the frame is always visible through walls and passthrough
  - Verify on-device: world direction is identifiable at a glance when rotated 180°
  - _Requirements: REQ-M2-4_

- [ ] 9. Verify M2 exit criteria
  - [ ] Driving fills the volume with permanent walls rendered via chunked greedy meshing
  - [ ] Frame rate holds at 72 fps with near-full volume on-device
  - [ ] Wall structure is legible from inside (see-through material)
  - [ ] World-frame is present; world directions findable when player is rotated
