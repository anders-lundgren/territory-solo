# AGENTS.md

Operating instructions for a coding agent picking up this project. Read this fully
before writing code, then read `docs/SPEC.md` and `docs/DECISIONS.md`.

## How to work

- **Read order:** `README.md` → this file → `docs/SPEC.md` → `docs/DECISIONS.md` →
  `docs/BUILD_PLAN.md`. Build strictly in milestone order (M0 → M4). M1 is a gate;
  do not start M2 until the M1 exit criteria are met.
- **Decisions are settled unless flagged.** The choices in `docs/DECISIONS.md` were
  made deliberately, with tradeoffs understood. Do not silently reverse them. If
  implementation reveals a decision is wrong, stop and surface it explicitly (what
  broke, which decision, what you propose instead) rather than quietly substituting
  your own.
- **Scope discipline.** Anything in `docs/ROADMAP.md` is out of scope for v1. Building
  ahead into multiplayer/phone/Centipede is a regression, not initiative. The only
  thing you owe the future is the two cheap properties in directive 4 below.

## Prime directives (non-negotiable)

### 1. Logic/render separation, enforced by assembly definitions
Three assemblies:
- **`Game.Core`** — plain C#, **no** dependency on UnityEngine rendering, physics, or
  XR. Owns the grid, the tick simulation, collision, win/loss, and serializable state.
  Must be unit-testable in edit-mode with no headset and no scene.
- **`Game.Presentation`** — MonoBehaviours, voxel meshing, passthrough, XR rig,
  effects. *Subscribes* to `Game.Core` state/events. Never owns game truth.
- **`Game.App`** — composition root: wires Core to Presentation, owns scene/bootstrapping.

The compiler should make it impossible for `Game.Core` to reference rendering. This is
not stylistic — it is the exact seam a phone spectator and a remote peer attach to later.

### 2. Deterministic, serializable simulation
- Simulate on a **fixed tick**, independent of frame rate. Grid math is integer
  (cell coordinates), not float — no positional drift.
- Given the same inputs, two machines must reach identical state. You are not building
  networking now, but determinism + a serializable state snapshot are what make lockstep
  remote multiplayer (ROADMAP Phase 4) feasible without a rewrite. Keep them; they are
  nearly free if designed in from M0 and expensive to retrofit.

### 3. Chunked greedy meshing for walls
Voxels are logical cells. Render walls by greedy-meshing coplanar faces within chunks,
regenerating only the dirty chunk(s) when the trail grows. Never instantiate a GameObject
per voxel. (Marching-cubes/density-field was considered and rejected — it smooths away
the voxel aesthetic; see `DECISIONS.md` D7.)

### 4. Collision is O(1) set membership
The occupied-cell store is the source of truth for collision. "Did the head hit a wall?"
is a hashset lookup on the next cell, not a physics query. This is a direct payoff of
directive 1 and keeps the tick cheap even when the room is full of wall.

## The M1 gate (read this before touching controls)

The design pairs **world-axis-locked steering** with **room-scale embedded play**
(player stands *inside* the volume). These are individually reasonable but rub against
each other: world-locked controls assume a stable shared frame, and standing inside the
volume is exactly what destabilizes the player's frame (their body faces any direction,
so the snake's world-"forward" no longer matches their gaze).

M1 is built to test this in isolation, **before** any walls, AI, or scoring exist:

- Build a gray-box: a head advancing on a fixed tick through the logical 3D grid,
  steered with world-axis-locked controls. No trail, no opponent, no juice.
- **The turn-around test:** physically walk around and rotate your body inside the
  volume while steering. The question is not "does steering feel good" but "does it
  still feel good when I'm facing a different way than I started."
- **Decision point at M1 exit:**
  - If world-locked survives the turn-around test → proceed as planned.
  - If steering feels persistently "wrong-handed" no matter the tuning → switch the
    control model to **body-relative** (snake forward = player gaze/facing). This trades
    the simpler control code for orientation that survives turning. Record the switch in
    `DECISIONS.md` (update D4).
- Regardless of outcome, build the **visible world-frame** (a tinted boundary face or
  colored axis edges) as part of legibility — it is what makes world-locked controls
  readable when embedded, and it is not optional. See `SPEC.md` "Legibility."

Do not skip or reorder this. Getting it wrong is cheap to discover in M1 and ruinous to
discover after M2–M3 are built on top.

## Conventions

- **Language/engine:** C# / Unity. Pin Unity + XR stack versions in M0; record in
  `DECISIONS.md`.
- **Namespaces** mirror assemblies: `Game.Core.*`, `Game.Presentation.*`, `Game.App.*`.
- **Tests:** every `Game.Core` rule (movement, trail-laying, collision, win condition,
  state serialization round-trip) gets an edit-mode test. The core is designed to be
  tested without a headset — use that.
- **Comfort/safety is a hard requirement, not polish:** walls are obstacles to the
  *snake* and pure visuals to the *player* — the player walks through them freely (no
  body collision). The play volume must fit comfortably inside a guardian boundary.
- **Commits/PRs** reference the milestone and exit criterion they advance (e.g.
  "M2: walls regenerate dirty chunk only").

## Definition of done for v1

The v1 ship is reached at the end of **M3** (M4 is buffer/juice). It is done when all of
these are true, on-device, in passthrough, anchored to a real room:

1. The play volume is anchored to the real space and stays put across a session.
2. A human-controlled snake moves volumetrically on a fixed tick and leaves a permanent
   wall trail; walls render via chunked greedy meshing and are see-through enough to read
   the structure from inside.
3. A visible world-frame is present so world-locked steering is legible when embedded.
4. One AI snake plays — present and functional, not necessarily good.
5. Collision (vs. any wall or the boundary) ends the round; a winner is declared; the
   game resets to a fresh round.
6. The player can walk through walls bodily; the volume fits inside guardian.
7. `Game.Core` carries no rendering/XR dependency and its rules are covered by edit-mode
   tests; state is serializable.

Anything beyond this — voxel-burst juice, tick tuning, scoring polish — is M4 and may be
cut without un-shipping.
