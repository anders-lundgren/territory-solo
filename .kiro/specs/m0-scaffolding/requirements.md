# M0 Requirements: Scaffolding and the Seam

## Overview
Stand up a correctly-structured Unity project that boots into anchored passthrough, with the logic/render separation enforced by assembly definitions and a test harness in place. No game logic yet.

---

## REQ-M0-1: Assembly structure
The project must have three C# assemblies — Game.Core, Game.Presentation, Game.App — with dependency direction enforced: Core has no reference to Unity rendering or XR; only Presentation and App may reference Core.

**Acceptance criteria:**
- `Game.Core.asmdef` has no UnityEngine.XR, UnityEngine.Rendering, or rendering-related references
- `Game.Presentation.asmdef` references Game.Core
- `Game.App.asmdef` references both Game.Core and Game.Presentation
- Adding a rendering-type reference to Game.Core causes a compile error (the asmdef enforces this structurally)

---

## REQ-M0-2: Passthrough boot
The app must launch on a Quest 3-class device and display stable color passthrough.

**Acceptance criteria:**
- App opens directly to passthrough with no opaque VR or black-screen startup
- Passthrough is color (not greyscale), confirming Quest 3-class capability

---

## REQ-M0-3: Anchored play volume
A fixed-size, empty play volume is anchored to the real room and remains stable within a session.

**Acceptance criteria:**
- A visible boundary (placeholder geometry acceptable at this milestone) marks the play volume
- The volume does not drift or re-snap during normal play
- Volume fits within the guardian boundary

---

## REQ-M0-4: Edit-mode test harness
An edit-mode test assembly referencing only Game.Core compiles and a sample test passes.

**Acceptance criteria:**
- A Unity Test Framework EditMode test assembly references Game.Core only (no Presentation or App)
- At least one passing smoke test confirms the assembly loads correctly

---

## REQ-M0-5: Deterministic tick loop and serializable state
Game.Core contains a fixed-step tick loop skeleton and a serializable (but empty) state snapshot that round-trips through serialize/deserialize.

**Acceptance criteria:**
- Tick loop advances a deterministic counter; after N calls to `Tick()`, `state.tick == N`
- State snapshot serializes and deserializes to an identical state (edit-mode test covers this)

---

## REQ-M0-6: Platform and XR stack decision recorded
Unity version, XR stack choice (Meta XR SDK vs. OpenXR + Meta features), and target device are pinned and recorded in DECISIONS.md.

**Acceptance criteria:**
- DECISIONS.md has a new entry for Unity version with the chosen LTS
- DECISIONS.md has a new entry for XR stack choice with rationale
- Target confirmed as Quest 3-class (color passthrough)
