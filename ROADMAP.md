# ROADMAP — beyond v1

Everything here is **out of scope for the v1 ship** (`SPEC.md`). It is recorded so the
agent understands the destination and respects the v1 seams these phases depend on —
**not** as license to build ahead. The only forward investment v1 makes is keeping the
simulation deterministic and serializable and the logic/render seam clean (D6).

The lead already has proof-of-concepts for spatial anchors and WebRTC-based
multiplayer/voice, and reports Quest spatial anchors work well enough for the intended
use. The networking carrier of record is **WebRTC** (data packets; voice where relevant).

---

## Phase 2 — AI depth, tuning, more juice
The cheapest next step; no new platform risk. Deepen the deliberately-simple v1 AI
(better lookahead, space-filling / territory-aware strategy, difficulty levels), tune
feel further, and add polish beyond the single v1 juice item.
**Depends on v1 seam:** none new — AI lives entirely in `Game.Core`, so smarter AI is a
drop-in replacement, exactly as intended by D2/D8.

## Phase 3 — Same-room colocated multiplayer
Two co-present players in one physical room, each headset rendering the shared game in the
same real place. Swap the AI snake for a second human.
**The hard part is colocation, not networking:** both headsets must agree on a shared
coordinate origin so a wall placed by one lands in the same physical spot for the other.
Watch for re-localization after a player walks away and drift over a long session.
WebRTC carries the gameplay state/inputs and voice.
**Depends on v1 seams:** the deterministic, serializable simulation (D6) — both peers run
the same Core; the state-snapshot/event interface is the sync point.
**Failure mode to expect:** spatial drift between two headsets (a *spatial* problem layered
on simple networking).

## Phase 4 — Remote multiplayer (separate rooms)
Players in different physical rooms competing for space. The conceptually most novel mode.
**Key design resolution:** the contested arena is **virtual and shared**, anchored
*independently* to each player's own real surface — each player sees the same abstract
play volume on their own room. The "invading your opponent's room" feeling is **thematic**,
not literal. Do **not** attempt to literally claim territory inside the opponent's actual
physical room — the room-shape mismatch is intractable (a wall sensible in one room floats
over the other's couch). The most that's advisable is a stylized ghost-layer of the
opponent's space, and even that is a stretch goal.
**Depends on v1 seams:** determinism (D6) is now load-bearing — this is where lockstep (or
rollback) and state authority over "who claimed which cell" become real. Integer grid math
and identical simulation across peers are what make this feasible without a rewrite.
**Failure mode to expect:** latency / state-authority (a *networking* problem layered on
simpler anchoring) — a different muscle than Phase 3. Supporting both same-room and remote
at once doubles the hardest work; sequence them.

## Phase 5 — Smartphone portal / spectator
Let a phone watch (and later participate as a portal into) a live game. **Spectator first,
portal second.**
**This is the direct payoff of D6.** The phone subscribes to the authoritative game-state
seam and renders its own view of the same simulation — which is precisely why the
logic/render decoupling is mandatory from v1 even though no phone code is written then.
**Depends on v1 seams:** the serializable state snapshot and the Core→view interface.
Building the phone view means pointing a new renderer at the existing seam.

## Phase 6 — Centipede creature-in-your-room (separate showcase)
A distinct project, not an evolution of Territory: the spectacle that sparked the whole
effort — the voxel **Centipede** from the film *Pixels*, reimagined as a segmented voxel
creature physically present in a real room (emerging from under a real table, pouring down
a wall via passthrough), with tower-defense-tinged defense of a structure on the player's
surface. The appeal is the *creature as physical presence*, not arcade Centipede's fixed-
shooter mechanics — and the original twist is inverting the camera relationship (look
*across* at a creature in the world, not *down* at a field). Reuses the voxel-actor and MR
foundations (a segmented body is the same identical-cube primitive as the snake) but
shares fewer systems with the multiplayer line, which is why it is sequenced as a second
showcase after the Territory foundation is solid.
**Depends on v1 seams:** reuses voxel rendering (greedy meshing) and MR anchoring; otherwise
largely new.

---

## Sequencing note
Phases 3 and 4 stress completely different problems (spatial drift vs. latency/authority)
and should not both be attempted at launch of multiplayer. Pick the one whose failure mode
is the better use of debugging time first. The lead's existing anchor + WebRTC PoCs
de-risk both relative to a cold start.
