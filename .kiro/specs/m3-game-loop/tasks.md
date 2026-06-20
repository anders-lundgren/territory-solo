# M3 Tasks: Collision, AI, Game Loop

- [ ] 1. Add Snake wrapper and SnakeStatus to Game.Core
  - Create `SnakeOwner` enum (Player, AI) and `SnakeStatus` enum (Alive, Dead)
  - Create `Snake` class wrapping `SnakeHead` with `Kill()` and `Revive()` methods
  - Add `PeekNextPosition()` to `SnakeHead` (returns next position without modifying state)
  - _Requirements: REQ-M3-1_

- [ ] 2. Implement per-tick collision in TickSimulation
  - Before advancing any snake: check each alive snake's `PeekNextPosition()` against `occupiedCells` and boundary
  - Flag any snake whose next cell is occupied or out-of-bounds as dead
  - Dead snakes do not advance and do not lay trail this tick
  - _Requirements: REQ-M3-1_

- [ ] 3. Write collision edit-mode tests
  - Test: snake advances into occupied cell → `SnakeStatus.Dead`
  - Test: snake advances into boundary → `SnakeStatus.Dead`
  - Test: snake advances into empty in-bounds cell → `SnakeStatus.Alive`
  - Test: collision check is O(1) — uses `HashSet.Contains`, not iteration (assert via code inspection)
  - _Requirements: REQ-M3-1, REQ-M3-5_

- [ ] 4. Add RoundStatus and EvaluateOutcome to Game.Core
  - Add `RoundStatus` enum (Playing, PlayerWins, AIWins, Draw) to `GameState`
  - `EvaluateOutcome()`: one alive → that snake wins; zero alive → Draw; two alive → Playing
  - Raise `OnRoundEnd(RoundStatus)` event when status leaves Playing
  - _Requirements: REQ-M3-3_

- [ ] 5. Implement ResetRound in TickSimulation
  - Clear `occupiedCells` and `occupiedCellsList`
  - Reset `roundStatus` to Playing, `tick` to 0
  - Revive both snakes and re-seed to starting positions
  - _Requirements: REQ-M3-3_

- [ ] 6. Write round lifecycle edit-mode tests
  - Test: player snake hits wall → `roundStatus == AIWins`
  - Test: AI snake hits wall → `roundStatus == PlayerWins`
  - Test: both snakes hit wall same tick → `roundStatus == Draw`
  - Test: `ResetRound()` → `occupiedCells.Count == 0`, both snakes alive at seed positions
  - _Requirements: REQ-M3-3, REQ-M3-5_

- [ ] 7. Record double-death tiebreak in DECISIONS.md
  - Add a new decision entry: same-tick double death = Draw
  - _Requirements: REQ-M3-3_

- [ ] 8. Implement AiController in Game.Core
  - `ChooseHeading(SnakeHead head, GameState state, Vector3Int gridMax) → Axis6`
  - Logic: 20% random open direction; else prefer current heading if clear 2 cells; else first open direction
  - Use `System.Random` with a fixed seed for determinism
  - Wire into `TickSimulation.Tick()`: call `ChooseHeading`, pass result to `aiSnake.Head.SetIntent()`
  - _Requirements: REQ-M3-2_

- [ ] 9. Write AI smoke tests
  - Test: AI in an empty grid, heading toward boundary → turns away before hitting (first ~5 ticks)
  - Test: AI with all directions blocked → does not throw; stays on current heading (graceful death)
  - _Requirements: REQ-M3-2, REQ-M3-5_

- [ ] 10. Expand GameLoop in Game.App for two snakes
  - Add AI intent computation call before each tick
  - Subscribe to `TickSimulation.OnRoundEnd`; stop ticking and raise own `OnRoundEnd` event
  - Add `RequestReset()`: calls `sim.ResetRound()`, restarts tick loop
  - _Requirements: REQ-M3-3_

- [ ] 11. Implement RoundResultUI in Game.Presentation
  - World-space Canvas at top of play volume; `TextMeshPro` label
  - Show "You Win!" / "AI Wins" / "Draw" on round end; hide on reset
  - Auto-reset after 2.5s (or on A-button press)
  - _Requirements: REQ-M3-3_

- [ ] 12. Confirm safety: no wall colliders
  - Verify `ChunkRenderer` GameObjects have no `Collider` components (or trigger-only)
  - Walk through walls on-device; confirm zero obstruction
  - Confirm volume boundary fits within guardian
  - _Requirements: REQ-M3-4_

- [ ] 13. Verify v1 Definition of Done (full on-device acceptance test)
  - [ ] Play volume anchors and is stable across the session
  - [ ] Human snake moves volumetrically; heading changes respond correctly
  - [ ] Vacated cells become permanent walls via chunked greedy meshing
  - [ ] Walls are see-through enough to read structure from inside
  - [ ] Visible world-frame is present and makes steering legible when turned
  - [ ] AI snake plays a full round (present and functional)
  - [ ] Collision ends the round; winner declared
  - [ ] Game resets and replays without relaunching
  - [ ] Player walks through walls bodily; volume fits guardian
  - [ ] Game.Core has no rendering/XR dependency; all edit-mode tests pass
  - **v1 is shipped when all boxes are checked**
