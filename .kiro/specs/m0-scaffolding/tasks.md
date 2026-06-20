# M0 Tasks: Scaffolding and the Seam

- [ ] 1. Record confirmed stack in DECISIONS.md
  - Stack is already confirmed by manifest.json (Unity 6, OpenXR, meta-openxr 2.5.0, MRUK 203.0.0)
  - Add DECISIONS.md entry: Unity 6000.x, OpenXR backend, no legacy Oculus XR Plugin
  - Confirm target device: Quest 3-class (color passthrough)
  - _Requirements: REQ-M0-6_

- [ ] 2. Create three assembly definitions with enforced dependency direction
  - Create `Assets/Scripts/Core/Game.Core.asmdef` with no rendering/XR assembly references
  - Create `Assets/Scripts/Presentation/Game.Presentation.asmdef` referencing Game.Core
  - Create `Assets/Scripts/App/Game.App.asmdef` referencing Game.Core and Game.Presentation
  - Verify enforcement: temporarily add a UnityEngine.Rendering using statement to a Core file and confirm compile error
  - _Requirements: REQ-M0-1_

- [ ] 3. Set up test infrastructure (see testing-strategy spec tasks 1–7)
  - Create `Game.Core.Tests` EditMode assembly and `Game.Presentation.Tests` PlayMode assembly
  - Add `SimulationRunner` to Game.Core; create `TestFixtures` helper class
  - Add `IPlayVolumeSource` interface and `MRUKPlayVolumeSource` implementation
  - Create `Assets/Tests/Rooms/TestRoom.json` room fixture
  - Create `runtests.ps1` at project root
  - Write smoke test `CoreAssemblyLoads`: instantiate `TickSimulation`, assert non-null
  - Confirm: `.\runtests.ps1 -mode editmode` exits 0
  - _Requirements: REQ-M0-4_

- [ ] 4. Implement GameState and serialization round-trip
  - Create `GameState.cs` in Game.Core with `[Serializable]` and `tick` field
  - Write edit-mode test: serialize `GameState` to JSON → deserialize → assert `tick` matches
  - _Requirements: REQ-M0-5_

- [ ] 5. Implement fixed-step tick loop skeleton
  - Create `TickSimulation.cs` in Game.Core with `Tick()` incrementing `State.tick`
  - Write edit-mode test: call `Tick()` N times, assert `State.tick == N`
  - _Requirements: REQ-M0-5_

- [ ] 6. Set up passthrough scene (OpenXR / AR Foundation — no OVRPassthroughLayer)
  - Create main Unity scene with `XROrigin` (not OVRCameraRig)
  - In Project Settings → XR Plug-in Management → Android → OpenXR: enable Camera (Passthrough) feature
  - Add `ARCameraManager` + `ARCameraBackground` to Main Camera; assign Meta OpenXR background material
  - Set camera Clear Flags to Solid Color, alpha 0
  - Verify against `com.unity.xr.meta-openxr` 2.5.0 docs before coding: https://docs.unity3d.com/Packages/com.unity.xr.meta-openxr@2.5/manual/index.html
  - Build and deploy to Quest 3; verify stable color passthrough on launch
  - _Requirements: REQ-M0-2_

- [ ] 7. Anchor the play volume via MRUK (no OVRSpatialAnchor)
  - Drop the MRUK prefab (from `com.meta.xr.mrutilitykit`) into the scene
  - Implement `PlayVolumeAnchor` MonoBehaviour in Game.Presentation (see design.md)
  - Subscribe to `MRUK.Instance.SceneLoadedEvent`; position play volume from `MRUKRoom.FloorAnchor`
  - Verify MRUK 203.0.0 API against docs before coding: https://developers.meta.com/horizon/documentation/unity/unity-mr-utility-kit-overview/
  - Define fixed play volume dimensions (confirm with lead; 2m × 2m × 2m starting point)
  - Add placeholder boundary geometry (colored edge lines or wireframe cube) as child of Play Volume Root
  - Deploy and verify: volume is stable, does not drift, placeholder visible, fits guardian
  - _Requirements: REQ-M0-3_

- [ ] 8. Verify all M0 exit criteria
  - [ ] App launches on-device into stable anchored passthrough with an empty volume visible
  - [ ] Game.Core compiles with no rendering/XR dependency
  - [ ] `.\runtests.ps1 -mode editmode` exits 0 (smoke test + serialization test pass)
  - [ ] State snapshot round-trips in a passing edit-mode test
  - [ ] Platform, XR stack, and device decisions recorded in DECISIONS.md
