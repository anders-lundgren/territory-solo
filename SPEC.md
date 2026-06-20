# SPEC — Voxel Territory v1

The detailed specification for the first shippable build. Scope is **solo vs. AI**.
Multiplayer and the phone spectator are out of scope here (see `ROADMAP.md`) but the
architecture is required to leave clean seams for them.

---

## 1. Vision and creative framing

A mixed-reality territory game where you pilot a snake-like head through a 3D voxel grid
anchored to your real room. Every cell the head leaves becomes a **permanent wall**.
Collision with any wall (yours, the opponent's, the boundary) ends the round. You win by
claiming volume and trapping the opponent.

**Why this concept.** It is the light-cycle *lineage* — claiming space with a permanent
trail — abstracted to its mechanic, which is genre rather than any one game's trademark.
It avoids the "old game but in 3D" feel because the third dimension and a real body
change the game qualitatively: open space and self-entrapment become things you read
spatially, not at a glance. It also has a clean growth path — the same systems become the
multiplayer game the project is ultimately aiming at, so nothing built for v1 is throwaway.
(The emotional spark for the broader project was the voxel **Centipede** from the film
*Pixels* — a segmented creature as a physical presence in a real room. That idea is
preserved as a separate future showcase in `ROADMAP.md` Phase 6, not v1, because it is
spectacle-dependent and shares fewer systems with the multiplayer line.)

## 2. Definition of "shippable" (v1)

A complete, winnable game loop, on-device, in passthrough, anchored to a real room:

> Anchored play volume → human snake and one AI snake both move volumetrically and lay
> permanent walls → collision with any wall or the boundary ends the round → a winner is
> declared → the game resets and can be replayed.

That is the whole bar. Everything past it is polish that can stop at any point.

## 3. Decided parameters (see `DECISIONS.md` for rationale)

| Dimension | v1 choice | Source |
|---|---|---|
| Game | Territory / space-claiming (snake-as-territory) | Dev-confirmed (D1) |
| Player count | Solo vs. one AI | Dev-confirmed (D2) |
| Movement | Fully volumetric, grid-locked, fixed tick | Dev-confirmed (D3, D10) |
| Steering | World-axis-locked first; body-relative fallback if M1 fails | Dev-confirmed, gated (D4) |
| Play volume | Room-scale, player stands inside | Dev-confirmed (D5) |
| Wall rendering | Chunked greedy meshing | Recommended (D7) |
| Wall legibility | See-through/wireframe walls + visible world-frame | Recommended, required (D5) |
| AI | Deliberately simple (1–2 cell lookahead) | Recommended (D8) |
| Juice | One effect only (voxel burst on crash), as buffer | Recommended (D9) |
| Architecture | Logic/render decoupled, deterministic, serializable | Recommended, required (D6) |

## 4. Architecture

Three layers, three assemblies (see `AGENTS.md` directive 1 for the enforcement detail).

### `Game.Core` — the simulation (pure C#, no rendering/XR)
- **Grid / occupied-cell store.** Source of truth for which cells are filled. Backed by a
  set keyed on integer cell coordinates (e.g. `HashSet<Vector3Int>` or a custom packed
  key). No floats in the authoritative state.
- **Tick simulation.** Fixed-step. Each tick: read pending input(s), advance each snake's
  head one cell along its current heading, mark the vacated cell as a permanent wall,
  evaluate collisions, update game state.
- **Collision.** For each snake, the cell it is about to enter is checked against the
  occupied set and the boundary. A hit flags that snake as dead. O(1) per snake.
- **Win/loss + round lifecycle.** When one snake remains (or both die on the same tick →
  define a tiebreak rule, e.g. draw), the round ends and a winner is recorded. Reset
  clears the grid and re-seeds start positions.
- **State snapshot.** A serializable representation of the full round state (occupied
  cells, snake heads/headings, status). Required for tests now and for the phone/remote
  seam later. Round-trip serialize→deserialize must reproduce identical state.

### `Game.Presentation` — the view (MonoBehaviours, XR, meshing)
- Subscribes to Core state/events; renders a voxel view of it. Owns nothing authoritative.
- **Wall rendering:** chunked greedy meshing; only dirty chunks regenerate on trail growth.
- **Legibility:** see-through wall material and the visible world-frame (see §6).
- **XR/MR:** passthrough scene, spatial anchor for the play volume, the player rig.
- **Input:** reads controller input, translates to Core's discrete heading-change intents.
- **Effects:** the M4 voxel-burst on crash.

### `Game.App` — composition root
- Wires Core ↔ Presentation, owns bootstrapping and the anchored scene.

### The seam (why it matters)
Presentation talks to Core only through state snapshots and events. That same interface is
what a phone spectator subscribes to (rendering its own view of the same state) and what a
remote peer synchronizes against. Building it cleanly now is the entire reason Phases 3–5
are cheap. Do not let Presentation reach into Core internals or let Core know rendering exists.

## 5. Systems and responsibilities (v1)

1. **Play-volume anchoring** *(Presentation/App)* — define a fixed-size volume, anchor it
   to the real space, keep it stable across the session. Reuse the lead's existing anchor
   harness.
2. **Logical grid** *(Core)* — the occupied-cell store and coordinate system.
3. **Snake movement** *(Core)* — fixed-tick, grid-locked, volumetric advance along a
   heading; heading changes come from input intents.
4. **Trail / walls** *(Core truth + Presentation mesh)* — vacated cells become permanent
   walls; Presentation greedy-meshes them by chunk.
5. **Collision** *(Core)* — set-membership + boundary check per tick.
6. **AI snake** *(Core)* — see §8.
7. **Round lifecycle** *(Core)* — start → play → death(s) → winner → reset.
8. **Input** *(Presentation → Core)* — controller input mapped to discrete heading intents.
9. **Legibility** *(Presentation)* — see-through walls + visible world-frame (§6).
10. **Comfort/safety** *(Presentation/App)* — walls non-colliding to the body; volume fits
    guardian.
11. **Juice** *(Presentation, M4)* — voxel burst on crash.

## 6. Controls and legibility (the project's main risk)

### Volumetric steering
The snake can travel along six directions (±X, ±Y, ±Z). v1 maps controller input to
**world-axis-locked** heading changes. Movement is discrete and tick-aligned; decide and
tune whether turns *queue* (a turn pressed mid-tick applies on the next tick) — this is
the difference between "responsive" and "fighting it."

### The world-locked + embedded tension
Standing inside the volume means the player's body faces arbitrary directions, so the
snake's world-"forward" stops matching their gaze. This is the single most likely thing
to make the game feel wrong. It is addressed two ways:

- **Mitigation (required): a visible world-frame.** Tint one boundary face as "north,"
  or color the volume's axis edges, so world-+X is always *findable* even when the player
  is turned around. Cheap geometry; build it in M2. Not optional.
- **Fallback (gated at M1): body-relative steering.** If the turn-around test shows
  world-locked is unsalvageable, switch so the snake's forward follows the player's
  facing. Costs the simpler control code; buys orientation that survives turning.

### Legibility from inside
A filled volume surrounds the embedded player with occluding wall, which makes the core
skill — reading open space and self-entrapment — hard. **See-through or wireframe-ish wall
rendering** is therefore a playability feature, not cosmetics. Build it in M2 while in the
rendering code, not as a later bolt-on.

## 7. Comfort and safety (hard requirement)

The player physically stands and moves inside a volume that fills with wall. Therefore:
- Walls are obstacles to the **snake** only; to the **player's body** they are pure
  visuals and fully pass-through. No body collision, ever.
- The play volume must sit comfortably within a guardian boundary.
- Keep the embedded experience comfortable (scale, height of accumulating geometry).

## 8. AI opponent (v1: deliberately simple)

A 3D collision-avoiding AI has more directions to check and more ways to trap itself than
a 2D one, so v1 keeps it intentionally shallow to protect the schedule:
- Advance; look ahead 1–2 cells; turn toward open space; add a little randomness.
- It may sometimes box itself in or die stupidly — acceptable, even charming, at v1.
- The opponent must be **present and functional**, not good. 3D pathfinding must not eat
  the milestone. AI depth is a Phase-2 concern (`ROADMAP.md`).

## 9. Acceptance criteria (testable)

Mirrors the v1 Definition of Done in `AGENTS.md`. The build passes when, on-device:
- [ ] Play volume anchors to the real room and is stable across the session.
- [ ] Human snake moves volumetrically on a fixed tick; heading changes respond correctly.
- [ ] Vacated cells become permanent walls; walls render via chunked greedy meshing.
- [ ] Walls are see-through enough to read the structure from inside the volume.
- [ ] A visible world-frame is present and makes world-locked steering legible when turned.
- [ ] One AI snake plays a full round.
- [ ] Collision with any wall or the boundary ends the round; a winner is declared.
- [ ] The game resets to a fresh round and can be replayed.
- [ ] The player can walk through walls bodily; the volume fits inside guardian.
- [ ] `Game.Core` has no rendering/XR dependency; movement, trail, collision, win, and
      state-serialization round-trip are covered by passing edit-mode tests.

## 10. Out of scope for v1

Multiplayer (same-room and remote), the smartphone portal/spectator, the Centipede
showcase, advanced AI, scoring meta, and any networking code. See `ROADMAP.md`. The only
forward investment v1 makes is keeping the simulation deterministic and serializable and
the logic/render seam clean.

---

## Glossary

- **Voxel** — a cubic cell; the visual atom of the game.
- **Logical grid / occupied-cell store** — the authoritative set of filled cells in
  `Game.Core`; the source of truth for collision and rendering.
- **Tick** — one fixed-step simulation update; movement is discrete and tick-aligned.
- **Trail / wall** — the permanent voxels left behind a moving snake head.
- **Chunk** — a sub-region of the volume meshed as a unit; only dirty chunks regenerate.
- **Greedy meshing** — merging coplanar voxel faces into larger quads to cut draw calls.
- **World-frame** — visible cues (tinted face / colored axis edges) that keep world-locked
  directions findable when the embedded player is turned around.
- **Turn-around test** — the M1 acceptance check: does world-locked steering still feel
  right when the player physically rotates inside the volume?
- **The seam** — the state-snapshot/event interface between `Game.Core` and
  `Game.Presentation`; the same attachment point used later by the phone and remote peers.
- **Embedded play** — the player stands *inside* the volume (vs. orbiting a tabletop box).
- **Colocation** — two co-present headsets agreeing on a shared coordinate origin (Phase 3).
