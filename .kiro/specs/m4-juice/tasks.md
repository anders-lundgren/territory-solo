# M4 Tasks: Juice and Tuning

- [ ] 1. Add OnSnakeDied event to TickSimulation
  - Raise `OnSnakeDied(SnakeOwner owner, Vector3Int cell)` when a snake is flagged dead
  - Wire in `GameLoop` to receive the event and forward world position to the burst effect
  - _Requirements: REQ-M4-1_

- [ ] 2. Implement CrashBurstEffect in Game.Presentation
  - Create `CrashBurstEffect` MonoBehaviour with a child `ParticleSystem`
  - Configure burst: box shape, cube mesh renderer, 100–200 particles, 0.6–1.2s lifetime, radial velocity, gravity 0.3
  - `PlayAt(Vector3 worldPosition)`: reposition and call `particleSystem.Play()`
  - No Core state modified; effect is purely visual
  - _Requirements: REQ-M4-1_

- [ ] 3. Wire burst effect in Game.App
  - Subscribe to `GameLoop`'s forwarded `OnSnakeDied` event
  - Call `burstEffect.PlayAt(LogicalToWorld(cell))` on each death
  - Test: trigger both player and AI deaths; confirm burst fires at correct world position each time
  - _Requirements: REQ-M4-1_

- [ ] 4. Verify burst performance on-device
  - Trigger a death; observe frame rate during burst in OVR Metrics Tool or Unity Profiler
  - Confirm frame rate stays at 72 fps
  - If not: reduce particle count, switch to Approach B (pooled rigidbodies), or simplify particle shape
  - _Requirements: REQ-M4-1_

- [ ] 5. Create GameConfig ScriptableObject
  - Add `tickInterval` field (float, Range 0.05–1.0, default 0.25)
  - Add `TurnQueueMode` enum and field (default QueueOne)
  - Wire `GameLoop` to read `tickInterval` and apply `turnQueueMode` at startup
  - Expose config as `[SerializeField]` on `GameLoop` so it can be swapped in the Inspector
  - _Requirements: REQ-M4-2_

- [ ] 6. Tune tick feel (play-test task)
  - Play several rounds; adjust `tickInterval` until movement feels responsive
  - Compare `QueueOne` vs `LastWins`: pick whichever makes deliberate turns feel intentional
  - Record final values as defaults in `GameConfig`
  - _Requirements: REQ-M4-2_

- [ ] 7. Final M4 verification
  - [ ] Voxel burst fires on crash for both player and AI deaths
  - [ ] Burst is visually distinct and does not persist beyond ~1.5s
  - [ ] Frame rate holds at 72 fps during burst on-device
  - [ ] Tick rate and turn queuing feel responsive; final values set as defaults
  - [ ] No second juice item was added
  - [ ] All M3 acceptance criteria still pass
