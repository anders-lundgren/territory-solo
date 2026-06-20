---
inclusion: always
---
# XR Stack Reference

> **This page describes the actual packages installed and the approved API surface for game code.**
> Meta's XR tooling evolves rapidly. Before using any class not listed here, check the current
> docs at https://developers.meta.com/horizon/documentation/unity/ — do not rely on training-data
> assumptions about Meta APIs.

## Confirmed package versions (manifest.json)

| Package | Version | Purpose |
|---|---|---|
| `com.unity.xr.openxr` | 1.17.1 | XR backend |
| `com.unity.xr.meta-openxr` | 2.5.0 | Meta OpenXR extensions (pulls in AR Foundation 6.5.0) |
| `com.meta.xr.mrutilitykit` | 203.0.0 | Room/scene understanding |
| `com.meta.xr.sdk.core` | 203.0.0 | Meta XR core (OVR** classes still present but off-limits for game code) |
| `com.unity.xr.arfoundation` | 6.5.0 | AR Foundation (dependency of meta-openxr) |
| `com.unity.render-pipelines.universal` | 17.5.0 | URP (Unity 6) |

**There is no `com.unity.xr.oculus` (legacy Oculus XR Plugin) — it was deprecated in Meta XR SDK v74 / Unity 6 and is absent from this project.**

## Approved API surface for game code (Game.Presentation, Game.App)

### XR Rig
Use **`XROrigin`** from `Unity.XR.CoreUtils`. Not `OVRCameraRig`.

```csharp
using Unity.XR.CoreUtils;  // XROrigin
```

### Passthrough
Use **`ARCameraManager`** + **`ARCameraBackground`** from AR Foundation, backed by `ARCameraFeature` (Meta OpenXR extension). Not `OVRPassthroughLayer`.

```csharp
using UnityEngine.XR.ARFoundation;  // ARCameraManager, ARCameraBackground
```

The feature must be enabled in:
`Project Settings → XR Plug-in Management → OpenXR → Meta Quest features → Camera (Passthrough)`

### Scene understanding / room anchors
Use **`MRUK`** singleton and **`MRUKRoom`** / **`MRUKAnchor`** from `Meta.XR.MRUtilityKit`.
Do NOT use `OVRScene`, `OVRSpatialAnchor`, or `OVRSceneRoom`.

```csharp
using Meta.XR.MRUtilityKit;  // MRUK, MRUKRoom, MRUKAnchor
```

Load room on startup:
```csharp
MRUK.Instance.SceneLoadedEvent.AddListener(OnSceneLoaded);
MRUK.Instance.LoadSceneFromDevice();
```

### Input
Use the **Unity Input System** (`com.unity.inputsystem`). Not `OVRInput`.

```csharp
using UnityEngine.InputSystem;  // InputAction, InputActionAsset
```

### Spatial anchors (if needed beyond MRUK room anchors)
Use **`ARAnchorManager`** from AR Foundation (`UnityEngine.XR.ARFoundation`).
Not `OVRSpatialAnchor`.

## Forbidden in game code (Game.Core, Game.Presentation, Game.App)

| Avoid | Reason | Use instead |
|---|---|---|
| `OVRCameraRig` | Legacy; requires Oculus XR Plugin | `XROrigin` |
| `OVRManager` | Legacy runtime manager | OpenXR handles this |
| `OVRPassthroughLayer` | Legacy passthrough | `ARCameraBackground` + `ARCameraManager` |
| `OVRSpatialAnchor` | Legacy anchor | `ARAnchorManager` or MRUK room anchors |
| `OVRInput` | Legacy input | Unity Input System |
| `OVRScene` / `OVRSceneRoom` | Legacy scene understanding | `MRUK` + `MRUKRoom` |

Note: MRUK's own internal source code uses OVR** classes. That is an internal implementation detail — its public API (`Meta.XR.MRUtilityKit.*`) is clean and is what game code consumes.

## Scene hierarchy template (M0)

```
[Scene: Main]
  XR Origin                         ← XROrigin component, Unity.XR.CoreUtils
    Camera Offset
      Main Camera                   ← ARCameraManager + ARCameraBackground (passthrough)
      Left Controller               ← XRController + InputActionProperty
      Right Controller              ← XRController + InputActionProperty
  MRUK                              ← MRUK prefab from com.meta.xr.mrutilitykit
  Play Volume Root                  ← positioned in OnSceneLoaded via MRUKRoom
    Boundary Geometry               ← placeholder / world-frame
```

## Passthrough setup (M0 task detail)

1. `Project Settings → XR Plug-in Management → OpenXR → Android tab`
   - Enable **Meta Quest feature set** (or individual features)
   - Enable **Camera (Passthrough)** feature (`ARCameraFeature`)
2. Add `ARCameraManager` component to Main Camera
3. Add `ARCameraBackground` component to Main Camera
   - Assign the Meta OpenXR background material (provided by `com.unity.xr.meta-openxr`)
4. Set camera background to **Solid Color, alpha = 0** so the real world shows through

## Play-volume anchoring with MRUK (M0 task detail)

The "lead's anchor harness" referred to in legacy docs used `OVRSpatialAnchor`. With MRUK, the
room itself is the anchor — position the play volume relative to the loaded room:

```csharp
void OnSceneLoaded(MRUKRoom room) {
    var floor = room.FloorAnchor;
    var center = floor.GetAnchorCenter();     // world-space floor center
    _playVolumeRoot.position = center + Vector3.up * (playVolumeHeight / 2f);
    _playVolumeRoot.rotation = Quaternion.identity;
}
```

MRUK handles re-localization and stability automatically via the OpenXR scene understanding subsystem.

## Checking docs

Because Meta XR SDK versions update frequently and are often ahead of training-data knowledge,
**always fetch current docs before assuming a class or method exists**:
- https://developers.meta.com/horizon/documentation/unity/
- https://docs.unity3d.com/Packages/com.unity.xr.meta-openxr@2.5/manual/index.html
