---
name: project-territory-stack
description: "Voxel Territory game — confirmed tech stack, XR API rules, and Kiro spec location"
metadata: 
  node_type: memory
  type: project
  originSessionId: 81ad35f2-7221-409f-b146-94ade92ddb90
---

Unity 6 (6000.x) + URP 17.5.0, Quest 3/3S target. OpenXR stack confirmed (no legacy Oculus XR Plugin).

**Key packages (manifest.json):**
- `com.unity.xr.openxr` 1.17.1
- `com.unity.xr.meta-openxr` 2.5.0 (pulls in AR Foundation 6.5.0)
- `com.meta.xr.mrutilitykit` 203.0.0
- `com.meta.xr.sdk.core` 203.0.0

**Why:** User explicitly wants Unity 6.5 + latest MRUK + OpenXR; avoid all legacy OVR** constructs in game code.

**Approved replacements:**
| Avoid | Use instead |
|---|---|
| OVRCameraRig | XROrigin (Unity.XR.CoreUtils) |
| OVRPassthroughLayer | ARCameraManager + ARCameraBackground (AR Foundation) |
| OVRSpatialAnchor | MRUK room anchors (MRUKRoom.FloorAnchor) |
| OVRInput | Unity Input System (UnityEngine.InputSystem) |
| OVRScene | MRUK.Instance + MRUKRoom |

**How to apply:** Any XR setup code must use the approved APIs. MRUK internally uses OVR** — that's fine, it's not game code. Always check current docs before assuming a Meta API exists; SDK versions are ahead of training data.

**Spec structure:** `.kiro/specs/m0–m4/` with requirements.md, design.md, tasks.md per milestone. Steering docs in `.kiro/steering/` (always-loaded). See `xr-stack.md` for the full XR reference.
