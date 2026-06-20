# M0 Design: Scaffolding and the Seam

> Before implementing XR setup steps, verify class names against the installed package versions
> (see `xr-stack.md`). Meta's SDK updates frequently; the patterns below match the confirmed
> installed versions but the docs URL for each package should be checked before coding.

## Assembly layout

```
Assets/
  Scripts/
    Core/
      Game.Core.asmdef              # no engine rendering/XR refs
      Simulation/
        GameState.cs                # serializable state snapshot
        TickSimulation.cs           # fixed-step tick loop
    Presentation/
      Game.Presentation.asmdef      # references Game.Core
      XR/
        PlayVolumeAnchor.cs         # positions play volume via MRUK room
    App/
      Game.App.asmdef               # references Game.Core + Game.Presentation
  Tests/
    EditMode/
      Game.Core.Tests.asmdef        # references Game.Core + Unity.Test.Framework only
      CoreBootstrapTests.cs
```

## GameState (M0 skeleton)

```csharp
using System;

namespace Game.Core {
    [Serializable]
    public sealed class GameState {
        public int tick;
        // Expanded in M1 (snake head) and M2 (occupied cells)
    }
}
```

## TickSimulation (M0 skeleton)

```csharp
namespace Game.Core {
    public sealed class TickSimulation {
        public GameState State { get; private set; } = new GameState();

        public void Tick() {
            State.tick++;
        }
    }
}
```

## Serialization round-trip

Use `UnityEngine.JsonUtility` (available in edit-mode tests without a scene):

```csharp
var sim = new TickSimulation();
sim.Tick(); sim.Tick();
var json = JsonUtility.ToJson(sim.State);
var restored = JsonUtility.FromJson<GameState>(json);
Assert.AreEqual(sim.State.tick, restored.tick);
```

## Scene hierarchy

```
[Scene: Main]
  XR Origin                         ← XROrigin component (Unity.XR.CoreUtils)
    Camera Offset
      Main Camera                   ← ARCameraManager + ARCameraBackground (passthrough)
      Left Controller               ← InputActionReference bindings (Unity Input System)
      Right Controller              ← InputActionReference bindings (Unity Input System)
  MRUK                              ← MRUK prefab from com.meta.xr.mrutilitykit
  Play Volume Root                  ← anchored by PlayVolumeAnchor (positioned via MRUKRoom)
    Boundary Geometry               ← placeholder colored edges (M0) / WorldFrameRenderer (M2)
```

## Passthrough setup (OpenXR / AR Foundation — no OVRPassthroughLayer)

The project uses `com.unity.xr.meta-openxr` 2.5.0 which provides `ARCameraFeature` — an
AR Foundation-based passthrough path. `OVRPassthroughLayer` is **not used**.

Steps:
1. `Project Settings → XR Plug-in Management → Android → OpenXR`
   - Confirm **Meta Quest** feature set is enabled
   - Enable **Camera (Passthrough)** feature (this is `ARCameraFeature`)
2. On Main Camera GameObject:
   - Add `ARCameraManager` component (`UnityEngine.XR.ARFoundation`)
   - Add `ARCameraBackground` component; assign the Meta OpenXR camera background material
     (provided in `com.unity.xr.meta-openxr` package)
3. Camera `Clear Flags` → **Solid Color**, background alpha = 0 (the real world shows through)
4. In `AndroidManifest.xml` (or via Project Settings → Player → Android → Custom Manifest):
   - Add `com.oculus.permission.USE_SCENE` and passthrough-related permissions

> If the passthrough setup API has changed in `com.unity.xr.meta-openxr` 2.5.0, consult:
> https://docs.unity3d.com/Packages/com.unity.xr.meta-openxr@2.5/manual/index.html

## Play-volume anchoring with MRUK (no OVRSpatialAnchor)

MRUK 203.0.0 loads room data via OpenXR scene understanding. The room itself is the anchor —
no separate `OVRSpatialAnchor` is needed.

```csharp
// Game.Presentation — PlayVolumeAnchor.cs
using Meta.XR.MRUtilityKit;
using UnityEngine;

namespace Game.Presentation {
    public sealed class PlayVolumeAnchor : MonoBehaviour {
        [SerializeField] private Transform playVolumeRoot;
        [SerializeField] private float playVolumeHeight = 2f;

        void Start() {
            // MRUK prefab must be in scene; subscribe before loading
            MRUK.Instance.SceneLoadedEvent.AddListener(OnSceneLoaded);
            MRUK.Instance.LoadSceneFromDevice();
        }

        void OnDestroy() {
            if (MRUK.Instance)
                MRUK.Instance.SceneLoadedEvent.RemoveListener(OnSceneLoaded);
        }

        private void OnSceneLoaded(MRUKRoom room) {
            // Position play volume at the center of the floor
            if (room.FloorAnchor != null) {
                var floorCenter = room.FloorAnchor.transform.position;
                playVolumeRoot.position = floorCenter + Vector3.up * (playVolumeHeight / 2f);
            }
            playVolumeRoot.rotation = Quaternion.identity;
        }
    }
}
```

> `MRUKRoom.FloorAnchor` and the exact API shape should be verified against MRUK 203.0.0 docs
> before use — the package is recent and the API may differ from older examples online.
> Reference: https://developers.meta.com/horizon/documentation/unity/unity-mr-utility-kit-overview/

## XR stack decision — already settled

The stack is confirmed by the existing `manifest.json`. Record in DECISIONS.md:
- Unity 6 (Unity 6000.x)
- XR backend: OpenXR (`com.unity.xr.openxr` 1.17.1 + `com.unity.xr.meta-openxr` 2.5.0)
- Scene understanding: MRUK 203.0.0
- No legacy Oculus XR Plugin
