# Voxel Territory *(working title — rename freely)*

A mixed-reality, voxel territory-control game for Meta Quest. You pilot a snake-like
head through a 3D grid anchored to your real room. Everywhere it has been becomes a
**permanent voxel wall**, partitioning the space. Crash into any wall — yours, your
opponent's, or the boundary — and the round ends. The goal is to claim volume and
trap your opponent before they trap you.

It is **not** Snake, Tron, or any specific arcade title. The mechanic is the
light-cycle *lineage* — claiming space with a permanent trail — which is genre, not
trademark. The creative bet is that this reads as a native MR game, not a "well-known
game but in 3D" port. See `docs/DECISIONS.md` (D1) for why this concept was chosen
over the alternatives we considered (Snake, Tetris, Pac-Man, Centipede, voxel-carving).

---

## Status

Pre-implementation. This repository currently contains the design and engineering
handoff only — no code yet. The first deliverable is a **fully working solo-vs-AI
game** (the "v1 ship"); multiplayer, remote play, and a phone spectator are deliberately
deferred (see `docs/ROADMAP.md`).

## Who this is for

The lead is a senior Unity developer with 5+ years of Quest development experience and
existing proof-of-concepts for spatial anchors and WebRTC-based multiplayer/voice. The
docs therefore assume Unity/Quest fluency and do **not** re-explain passthrough,
anchors, or XR basics. They focus on the decisions, the architecture seams, and the
specific risks that are easy to get wrong.

## Repository map

| File | What it is | Read it when |
|---|---|---|
| `README.md` | This file — orientation and quick start | First |
| `AGENTS.md` | Operating manual for a coding agent: prime directives, conventions, gates, definition of done | Before writing any code |
| `docs/SPEC.md` | The v1 specification: vision, scope, architecture, systems, acceptance criteria, glossary | Before designing systems |
| `docs/BUILD_PLAN.md` | Milestones M0–M4 with tasks and exit criteria. M1 is a **gate**. | To know what to build next |
| `docs/DECISIONS.md` | Decision log (ADR-lite) with rationale and alternatives, so settled choices are not re-litigated | When tempted to change a decided thing |
| `docs/ROADMAP.md` | Everything deferred past v1 and the v1 seams it depends on | When deciding what *not* to build now |

## Prime directives (the short version — full detail in `AGENTS.md`)

1. **Separate logic from rendering.** The game runs as pure, deterministic data. The
   headset renders a *view* of that data. This single seam is what makes the future
   phone spectator and remote multiplayer cheap. Enforce it with assembly definitions.
2. **Greedy-mesh the walls in chunks.** Never one GameObject per voxel. A 3D volume
   fills with a lot of wall; per-voxel objects will destroy the standalone draw-call
   budget on the first interesting round.
3. **De-risk controls first.** Build a steering gray-box (M1) and run the **turn-around
   test** before building anything on top of it. The chosen control/framing pairing
   (world-axis-locked steering + room-scale embedded play) is the riskiest combination
   in the design; M1 exists to validate or reject it early. See `DECISIONS.md` (D4, D5).
4. **Defer the future, preserve the seams.** Do not build networking, remote play, or
   phone code in v1 — but keep the simulation deterministic and its state serializable,
   because those two nearly-free properties are what make Phases 3–5 tractable.

## Target platform (confirm before M0)

Mixed reality with **color** passthrough implies a Quest 3-class device (Quest 3 / 3S).
Exact Unity version and XR stack (Meta XR SDK vs. OpenXR + Meta features) are the lead's
call — pin them in M0 and record the choice in `DECISIONS.md`.
