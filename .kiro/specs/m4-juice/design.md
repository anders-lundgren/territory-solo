# M4 Design: Juice and Tuning

## Voxel burst effect

Implemented entirely in Game.Presentation. Core state is never modified.

### Approach A: Particle System (recommended)

`CrashBurstEffect` MonoBehaviour:
- Child `ParticleSystem` configured as a burst:
  - Shape module: Box, size = cell size (0.15m)
  - Emission: burst of 100–200 particles on `Play()`
  - Start speed: 1–4 m/s radial outward
  - Start lifetime: 0.6–1.2s (randomized)
  - Gravity modifier: 0.3 (slight fall for realism in MR)
  - Renderer: Mesh renderer with a tiny cube mesh, unlit material, wall color
  - `SimulationSpace: World`
- `PlayAt(Vector3 worldPosition)`: move to position, call `particleSystem.Play()`
- `Stop()` auto-fires after emission; no manual cleanup needed

Particle budget: 200 max at once. Well within Quest 3 standalone budget; confirm on-device.

### Approach B: Rigidbody fragments (higher visual impact, more overhead)

Pool of 30–50 small cube `Rigidbody` GameObjects (pre-warmed at scene start):
- On crash: activate N cubes at the death position, apply random impulse (1–3 m/s radial), add slight spin
- Deactivate after 1.5s via coroutine or timed callback
- Use a simple `ObjectPool<Transform>` for zero-GC recycling

Choose Approach A unless the particle version feels weak on-device. Swap to B only if needed.

### Integration

`TickSimulation.OnRoundEnd` should carry the death position(s). Options:

1. Add `Vector3Int playerDeathCell` and `Vector3Int aiDeathCell` to `GameState` (set when snake is killed)
2. Raise a separate `OnSnakeDied(SnakeOwner, Vector3Int cell)` event from `TickSimulation`

Option 2 is cleaner (no dead state lingers in GameState). Prefer it.

```csharp
// In TickSimulation, when snake is killed:
OnSnakeDied?.Invoke(snake.Owner, snake.Head.Position);
```

```csharp
// In Game.App (GameLoop wires this):
_sim.OnSnakeDied += (owner, cell) => {
    _burstEffect.PlayAt(LogicalToWorld(cell));
};
```

## Tick rate and turn-feel tuning

### GameConfig ScriptableObject

```csharp
// Game.App
[CreateAssetMenu(menuName = "VoxelTerritory/GameConfig")]
public sealed class GameConfig : ScriptableObject {
    [Range(0.05f, 1.0f)]
    public float tickInterval = 0.25f;  // seconds per tick; tune in M4

    public TurnQueueMode turnQueueMode = TurnQueueMode.QueueOne;
}

public enum TurnQueueMode {
    QueueOne,    // buffer one pending intent; later input before tick overwrites
    LastWins,    // only the most recent input before the tick fires is used (same behavior for 1 input, different for 2)
}
```

`GameLoop` reads `GameConfig` at start (or via `[SerializeField]`) and uses `tickInterval` for its repeat interval.

### Tuning guidance

Start with `tickInterval = 0.25s`, `TurnQueueMode.QueueOne`. Play several rounds:
- If it feels like the snake ignores inputs: reduce interval or switch to `QueueOne` if not already set
- If it feels frantic/uncontrollable: increase interval
- If turns feel "sticky" (queued turn applied one tick later than expected): `LastWins` may feel tighter

Recommended final range: 0.2s–0.35s. Record the chosen default.

## What not to add

M4 is deliberately small. These are explicitly out of scope:
- Score display or persistent scoring
- Win/lose animation beyond the M3 round-result text
- Difficulty selection for the AI
- Any networking, multiplayer, or phone code
- A second juice item
