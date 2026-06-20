# M1 Requirements: Volumetric Steering Gray-box (Gate)

## Overview
Validate — or reject — the world-axis-locked + room-scale-embedded control pairing in complete isolation, before anything is built on top of it. This is a hard gate. M2 does not begin until the exit criteria are met and a control model is decided and recorded.

See AGENTS.md "The M1 gate" for full rationale.

---

## REQ-M1-1: Snake head modelled in Game.Core
Game.Core models a single snake head: an integer cell position, a world-axis heading, and the ability to advance one cell per tick and accept a discrete heading-change intent.

**Acceptance criteria:**
- `Axis6` enum covers ±X, ±Y, ±Z (six directions)
- `SnakeHead` has position (`Vector3Int`), heading (`Axis6`), and pending intent fields
- `SnakeHead.Advance()` moves position one cell along current heading; applies pending intent first if set
- 180° reversals are blocked (can't turn directly back)
- `TickSimulation.Tick()` drives the head
- Edit-mode tests cover: straight advance N ticks, turn applied at tick boundary, 180° intent ignored

---

## REQ-M1-2: World-axis-locked controller input
Game.Presentation maps controller input to world-axis heading intents and forwards them to the tick simulation.

**Acceptance criteria:**
- Six gestures (or fewer combined-axis inputs) map to the six world-axis directions
- Pressing "right" always means world +X regardless of where the player is physically facing
- At most one intent is forwarded per tick (rapid inputs do not stack multiple turns in one tick)

---

## REQ-M1-3: Minimal head rendering — nothing else
Game.Presentation renders exactly the snake head's current position. No trail, no walls, no AI, no effects.

**Acceptance criteria:**
- A single distinct object (cube or distinct marker) tracks the head's logical cell in world space
- The head updates position each tick, not each frame
- Nothing else is rendered beyond the play volume boundary from M0

---

## REQ-M1-4: Turn-around test (the gate)
On-device, the player steers the head while physically rotating inside the volume. The control model is evaluated for usability under orientation changes.

**Gate criteria (both must be satisfied before M2 begins):**
- Either: steering feels correct when the player faces a direction different from their starting orientation, or
- The world-locked model is declared unsalvageable and the body-relative fallback is adopted instead

---

## REQ-M1-5: Control model decision recorded in DECISIONS.md
The M1 outcome is recorded in DECISIONS.md, updating entry D4.

**Acceptance criteria:**
- D4 is updated with the actual M1 outcome (world-locked survives / body-relative adopted)
- If body-relative was adopted, the input mapping in Presentation is updated accordingly before M2 begins
