# DECISIONS — Voxel Territory

Decision log (ADR-lite). These were made deliberately during design discussion. **Do not
silently reverse them** (see `AGENTS.md`). If implementation shows one is wrong, surface
it explicitly and update the relevant entry.

"Source" distinguishes choices the lead made directly (**Confirmed**) from advisor
recommendations adopted as the working plan (**Recommended**). Both are plan-of-record;
the distinction tells you which are firm and which carry more latitude if reality pushes back.

---

### D1 — Game concept: territory / space-claiming (snake-as-territory)
**Status:** Confirmed · **Source:** lead.
**Decision.** Build the light-cycle *lineage* — a snake-like head leaving a permanent wall
trail to partition and claim space — not Snake, Tron, Tetris, Pac-Man, or Centipede.
**Rationale.** (a) Every v1 system (grid, trail-as-walls, collision, win/loss) carries
forward into the multiplayer game the project is ultimately aiming at — nothing is
throwaway. (b) The mechanic is genre, not trademark, so it avoids IP entanglement and
knock-off feel. (c) The third dimension plus a real body changes the game qualitatively
(reading open space / self-entrapment spatially), so it transcends "old game but in 3D."
**Alternatives considered.** Snake (great starter but thinner growth path); Tetris (more
IP baggage, less MR-transformed); Pac-Man / dot-maze (strong MR transform but heavily
defended IP); Centipede (spectacle-dependent, fewer shared systems — preserved as a
future showcase, see ROADMAP Phase 6); voxel-carving/erosion (most original but hardest
rendering problem, no clear growth path to multiplayer).
**Consequences.** Sets up the multiplayer line; demands the clean state/render seam (D6).

### D2 — v1 player model: solo vs. one AI
**Status:** Confirmed · **Source:** lead.
**Decision.** First shippable build is single-player against one AI snake.
**Rationale.** Multiplayer is the destination, but solo-vs-AI exercises and ships every
core system first; the AI is the only part later replaced, and a simple one is small.
**Consequences.** AI is required for v1 but only minimally (D8).

### D3 — Movement: fully volumetric (not planar)
**Status:** Confirmed · **Source:** lead.
**Decision.** The snake moves in true 3D (±X, ±Y, ±Z), not on a single table plane.
**Rationale.** Lead chose to solve the hard control problem once, up front, rather than
ship planar and redo controls later.
**Cost accepted.** Volumetric makes two things materially harder: the control scheme
(six directions, the "up relative to what?" problem) and spatial legibility (occluding
walls surround the player). Both are addressed by D4/D5 and the M1 gate.
**Alternative considered.** Planar (snake on the table, walls rise up) — far simpler
controls and legibility, but rejected because volumetric is the true destination.

### D4 — Steering: world-axis-locked first; body-relative fallback (GATED)
**Status:** Confirmed, gated at M1 · **Source:** lead.
**Decision.** Try world-axis-locked steering first (easier to build and reason about).
M1's turn-around test decides whether it survives; if not, switch to body-relative
(snake forward follows player facing).
**Rationale.** World-locked is the simpler control code. But paired with embedded
room-scale play (D5) it risks feeling "wrong-handed" because the player's body faces
arbitrary directions. Rather than guess, M1 validates it in isolation before anything is
built on top.
**Consequences.** M1 is a hard gate (`BUILD_PLAN.md`). The visible world-frame (in D5) is
the required mitigation either way. **Update this entry with the M1 outcome.**

### D5 — Play volume: room-scale, player embedded (not tabletop-orbit)
**Status:** Confirmed · **Source:** lead.
**Decision.** The player stands *inside* the play volume, not orbiting a tabletop box.
**Rationale.** The in-the-thick-of-it feeling is a genuinely different, more immersive
game than looking into a box.
**Risk accepted.** This is the *harder* framing on legibility — and it is paired with
world-locked controls (D4), making this the riskiest combination in the design.
**Required mitigations (not optional):**
- A **visible world-frame** (tinted boundary face / colored axis edges) so world
  directions are findable when the player is turned around.
- **See-through / wireframe-ish walls** so the structure is readable from inside.
- **Comfort/safety:** walls pass through the player's body (no body collision); the volume
  fits inside guardian.
**Alternative considered.** Contained tabletop volume the player orbits and looks into —
more legible and comfortable, rejected in favor of immersion. (Remains a viable
simplification if embedded proves untenable.)

### D6 — Architecture: logic/render decoupled, deterministic, serializable
**Status:** Recommended, required · **Source:** advisor, adopted.
**Decision.** `Game.Core` (pure C#, no rendering/XR) owns deterministic, fixed-tick,
integer-grid simulation and serializable state; `Game.Presentation` renders a view by
subscribing to Core. Enforced by assembly definitions.
**Rationale.** This single seam is what makes the phone spectator (ROADMAP Phase 5) and
remote lockstep multiplayer (Phase 4) cheap rather than a rewrite. Determinism +
serializable snapshots are nearly free if designed in from M0 and expensive to retrofit.
**Consequences.** Collision becomes O(1) set membership; Core is unit-testable
headset-free; the same interface serves future phone/remote consumers.

### D7 — Wall rendering: chunked greedy meshing
**Status:** Recommended · **Source:** advisor, adopted.
**Decision.** Greedy-mesh coplanar voxel faces within chunks; regenerate only dirty
chunks on trail growth. Never one GameObject per voxel.
**Rationale.** A 3D volume fills with far more wall than a plane; per-voxel objects blow
the standalone draw-call budget immediately. Retrofitting meshing after building around
per-voxel objects is painful.
**Alternative considered.** Marching-cubes over a density field — smoother carving but
reads less "voxel," fighting the aesthetic; rejected.

### D8 — AI: deliberately simple for v1
**Status:** Recommended · **Source:** advisor, adopted.
**Decision.** v1 AI advances, looks ahead 1–2 cells, turns toward open space, with a
little randomness. It may die stupidly.
**Rationale.** 3D collision-avoidance is harder than 2D; dialing AI ambition *down*
compensates for movement ambition going *up* (D3) and protects the schedule. The opponent
must be present, not good.
**Consequences.** AI depth deferred to ROADMAP Phase 2.

### D9 — Juice: exactly one effect, as buffer
**Status:** Recommended · **Source:** advisor, adopted.
**Decision.** v1 ships with at most one juice item — recommended: voxel-burst on crash —
plus tick/turn tuning. Not two.
**Rationale.** The discipline of a single polish item is what gets the build actually
finished; juice is the schedule buffer that gives if controls (the M1 risk) eat time.
A burst effect has the highest tactile payoff in MR and reels well for portfolio.
**Consequences.** M4 is cuttable without un-shipping (M3 is the ship).

### D10 — Movement is grid-locked and tick-based (not free movement)
**Status:** Confirmed (movement model) · **Source:** lead/advisor.
**Decision.** The snake advances in discrete cells on a fixed tick; turns are discrete
heading changes, possibly queued.
**Rationale.** Far easier to reason about and to test than free movement, and a
prerequisite for the deterministic simulation (D6) that future multiplayer needs.
**Open tuning.** Tick rate and whether turns queue — tuned in M4; large effect on feel.

---

## Open / to-confirm

- **Unity version + XR stack** — pin in M0 (Meta XR SDK vs. OpenXR + Meta features).
- **Target device** — Quest 3-class assumed for color passthrough; confirm in M0.
- **M1 outcome** — world-locked vs. body-relative; record back into D4.
- **Double-death tiebreak** — define in M3 (e.g. draw on same-tick mutual collision).
- **Project name** — "Voxel Territory" is a placeholder.
