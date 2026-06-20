# BUILD PLAN — Voxel Territory v1

Milestones in strict order. **M1 is a gate** — do not begin M2 until M1's exit criteria
and decision point are resolved. The v1 ship is reached at the end of **M3**; **M4 is
buffer** (juice + tuning) and may be cut without un-shipping.

The original framing was a single weekend; these milestones preserve that
de-risk-first ordering but are written as agent-consumable units of work with explicit
exit criteria rather than wall-clock blocks.

---

## M0 — Scaffolding and the seam

**Goal:** an empty but correctly-structured project that boots into anchored passthrough,
with the logic/render separation enforced and a test harness in place.

Tasks:
- Pin Unity version and XR stack (Meta XR SDK vs. OpenXR + Meta features); record in
  `DECISIONS.md`. Confirm target device is Quest 3-class (color passthrough).
- Create the three assemblies — `Game.Core` (no rendering/XR refs), `Game.Presentation`,
  `Game.App` — with the dependency direction enforced by asmdef references.
- Boot into a passthrough scene; anchor a fixed-size, empty play volume to the real space
  (reuse the lead's anchor harness).
- Stand up an edit-mode test project that references `Game.Core` only.
- Add an empty deterministic tick loop and a serializable (empty) state snapshot in Core,
  with a serialize→deserialize round-trip test.

**Exit criteria:**
- App launches on-device into stable anchored passthrough with an empty volume.
- `Game.Core` compiles with no rendering/XR dependency; an edit-mode test runs against it.
- State snapshot round-trips in a passing test.

## M1 — Volumetric steering gray-box  ⟵ GATE

**Goal:** validate (or reject) the world-locked + embedded control pairing in isolation,
before anything is built on top of it. See `AGENTS.md` "The M1 gate."

Tasks:
- In `Game.Core`: a single head advancing one cell per fixed tick along a current heading;
  heading changes applied as discrete world-axis intents. No trail persisted yet (or
  persisted but not rendered — implementer's choice, kept minimal).
- In `Game.Presentation`: minimal rendering of just the head; map controller input to
  world-axis-locked heading intents. No walls, no AI, no effects.
- Run the **turn-around test** on-device: drive the head while physically walking and
  rotating inside the volume.

**Decision point (record outcome in `DECISIONS.md`, update D4):**
- World-locked survives the turn-around test → keep it; proceed to M2.
- World-locked feels persistently wrong-handed regardless of tuning → switch to
  **body-relative** steering (snake forward follows player facing) before proceeding.

**Exit criteria:**
- Steering the head feels correct *while the player is turned away from the start
  orientation* (under whichever control model passed).
- The control model for the rest of v1 is decided and recorded.

## M2 — Trail, walls, meshing, legibility

**Goal:** the head leaves a permanent, readable wall structure that performs on-device.

Tasks:
- In `Game.Core`: persist vacated cells into the occupied-cell store as permanent walls.
- In `Game.Presentation`: chunked greedy meshing of walls; regenerate only dirty chunks
  on growth. **Never** per-voxel GameObjects.
- Implement see-through / wireframe-ish wall material so the structure is readable from
  inside the embedded volume.
- Build the **visible world-frame** (tinted boundary face or colored axis edges) — the
  required mitigation for world-locked + embedded legibility.

**Exit criteria:**
- Driving around fills the volume with a permanent wall structure rendered via chunked
  greedy meshing, holding target frame rate on-device.
- The structure is legible from inside (see-through walls) and world directions are
  findable when turned (world-frame present).

## M3 — Collision, AI, game loop  ⟵ v1 SHIP

**Goal:** a complete, winnable, replayable game.

Tasks:
- In `Game.Core`: per-tick collision = occupied-set + boundary check per snake; a hit
  flags that snake dead. Define the same-tick double-death tiebreak (e.g. draw).
- Add the second snake driven by the **deliberately simple** AI (§8 of `SPEC.md`):
  advance, 1–2 cell lookahead, turn toward open space, a little randomness. Present, not
  good. Do not let pathfinding eat the milestone.
- Round lifecycle: start (seed both snakes) → play → death(s) → declare winner → reset
  (clear grid, re-seed) → replay.
- Confirm comfort/safety: walls pass through the player's body; volume fits guardian.
- Cover Core rules (movement, trail, collision, win, serialization) with edit-mode tests.

**Exit criteria (= v1 Definition of Done):** all acceptance criteria in `SPEC.md` §9 pass
on-device. **The game is shipped at this point.**

## M4 — Juice and tuning (buffer)

**Goal:** the one thing that makes it feel like a game, not a tech demo — if time allows.

Tasks (pick **one** primary, then tune):
- **Primary (recommended): voxel-burst on crash** — the snake/walls shatter into voxels on
  collision. Highest tactile payoff in MR and photographs well for a portfolio reel.
- Tune tick rate and turn-queuing feel (small change, large effect on "responsive").
- Optional: a clear win/lose beat, or a simple score = volume claimed — **not both**;
  resist a second polish item.

**Exit criteria:** one juice item lands and turning feel is tuned. Cuttable without
un-shipping — M3 already shipped.

---

## Milestone summary

| Milestone | Outcome | Gate? |
|---|---|---|
| M0 | Anchored passthrough boot + enforced seam + tests | — |
| M1 | Steering validated (or switched to body-relative) | **Gate** |
| M2 | Readable permanent walls, performant, legible | — |
| M3 | Complete winnable replayable game | **v1 ship** |
| M4 | One juice item + tuning | Buffer (cuttable) |
