# M3 Requirements: Collision, AI, Game Loop (v1 Ship)

## Overview
A complete, winnable, replayable game. This milestone is the v1 Definition of Done. The game is shipped when all acceptance criteria here pass on-device in passthrough.

---

## REQ-M3-1: Per-tick collision detection (O(1))
Each tick, every snake's next cell is checked against the occupied-cell store and the volume boundary. A hit flags that snake dead. Collision is set membership — no Unity physics.

**Acceptance criteria:**
- Collision check = `occupiedCells.Contains(nextCell) || IsOutOfBounds(nextCell)` per snake, per tick
- No `Physics.Raycast`, `Collider`, or physics query involved
- A snake hitting a wall or boundary is immediately flagged dead; it stops moving and stops laying trail
- Edit-mode tests cover: wall collision → dead, boundary collision → dead, clean advance → alive

---

## REQ-M3-2: AI snake (deliberately simple — present, not good)
A second snake is driven by a simple AI: look ahead 1–2 cells, turn toward open space, add randomness. It may die stupidly at v1.

**Acceptance criteria:**
- The AI snake moves on the same tick cadence as the player
- AI checks 1–2 cells ahead; if current heading is blocked, it turns toward an open direction
- AI has a randomness factor (~20% chance of choosing a random valid open direction instead)
- The AI is present and functional; competitive skill is not required at v1
- Edit-mode test: AI in an empty grid does not immediately self-collide on its first several ticks

---

## REQ-M3-3: Round lifecycle (start → play → death → winner → reset → replay)
The game has a complete, replayable round loop.

**Acceptance criteria:**
- Both snakes start at defined non-overlapping seed positions each round
- When one snake dies: round ends, surviving snake is declared winner
- Same-tick double death → a defined tiebreak is applied and recorded in DECISIONS.md (draw recommended)
- After declaring a result, the game resets: grid clears, snakes re-seed, a new round begins
- A minimal win/loss beat is displayed (floating text or simple overlay acceptable)
- Player can replay without relaunching the app

---

## REQ-M3-4: Player can walk through walls (hard safety requirement)
Walls have no collision with the player's physical body.

**Acceptance criteria:**
- The player can walk through all wall geometry without being pushed, slowed, or obstructed
- No `Collider` on wall chunk meshes (or trigger-only if needed for non-body purposes)
- Volume fits within guardian boundary

---

## REQ-M3-5: Full edit-mode test coverage of Game.Core
All Game.Core rules are covered by passing edit-mode tests.

**Acceptance criteria:**
- Tests cover: movement (advance, turn, 180° block), trail (cells added per tick), collision (wall + boundary), win (one dead → other wins), double-death tiebreak, round reset (state fully clears), state serialization round-trip
- All tests pass without a headset, without a scene, and without any Presentation or App code

---

## REQ-M3-6: v1 on-device acceptance (Definition of Done)
All SPEC.md §9 acceptance criteria pass on-device in passthrough, anchored to a real room.

**Acceptance criteria (on-device checklist):**
- [ ] Play volume anchors to real room and is stable across the session
- [ ] Human snake moves volumetrically on a fixed tick; heading changes respond correctly
- [ ] Vacated cells become permanent walls; walls render via chunked greedy meshing
- [ ] Walls are see-through enough to read the structure from inside the volume
- [ ] A visible world-frame is present and makes world-locked steering legible when turned
- [ ] One AI snake plays a full round
- [ ] Collision with any wall or the boundary ends the round; a winner is declared
- [ ] The game resets to a fresh round and can be replayed
- [ ] The player can walk through walls bodily; volume fits inside guardian
- [ ] Game.Core has no rendering/XR dependency; all edit-mode tests pass
