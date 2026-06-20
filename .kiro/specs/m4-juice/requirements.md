# M4 Requirements: Juice and Tuning (Buffer)

## Overview
One juice item — voxel burst on crash — plus tick/turn feel tuning. M4 is buffer: it may be cut without un-shipping (M3 is the v1 ship). Pick exactly one primary juice item; do not add a second.

---

## REQ-M4-1: Voxel burst on crash
When a snake collides with a wall, a burst of voxel fragments flies outward from the collision point. This is implemented entirely in Game.Presentation — no Core state is modified.

**Acceptance criteria:**
- Collision triggers a visually distinct burst of voxel-sized particles or physics fragments
- Fragments are short-lived (~0.8–1.5s) and do not persist as permanent game objects
- Effect triggers for both player and AI deaths
- Frame rate does not drop below 72 fps during the effect (particle budget appropriate for standalone)
- The burst does not obscure the round-result UI or extend the perceived death beat by more than ~1s

---

## REQ-M4-2: Tick rate and turn-feel tuning
Tick interval and turn-queuing behavior are dialed in so the game feels responsive and deliberate.

**Acceptance criteria:**
- Tick interval is configurable (e.g. via a `GameConfig` ScriptableObject) without recompiling
- Turn queuing mode (queue-one vs. last-wins) is decided and implemented
- After tuning, steering a deliberate path feels "responsive" — neither laggy nor frantic
- Final values are set as defaults in the config

---

## REQ-M4-3: Exactly one juice item
No second polish item is added at this milestone.

**Acceptance criteria:**
- Only the voxel burst (REQ-M4-1) is added beyond M3
- Score display, win animation (beyond the M3 result text), additional effects, and difficulty levels are explicitly not added at this milestone
- M3 acceptance criteria continue to pass after M4 changes
