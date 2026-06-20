# M1 Design: Volumetric Steering Gray-box

## Core additions

### Axis6 enum

```csharp
namespace Game.Core {
    public enum Axis6 { PosX, NegX, PosY, NegY, PosZ, NegZ }
}
```

### SnakeHead

```csharp
namespace Game.Core {
    public sealed class SnakeHead {
        public Vector3Int Position { get; private set; }
        public Axis6 Heading { get; private set; }
        private Axis6? _pendingIntent;

        public SnakeHead(Vector3Int startPosition, Axis6 startHeading) {
            Position = startPosition;
            Heading = startHeading;
        }

        public void SetIntent(Axis6 direction) {
            if (!IsOpposite(direction, Heading))
                _pendingIntent = direction;
        }

        public void Advance() {
            if (_pendingIntent.HasValue) {
                Heading = _pendingIntent.Value;
                _pendingIntent = null;
            }
            Position += ToVector(Heading);
        }

        private static bool IsOpposite(Axis6 a, Axis6 b) =>
            (int)a / 2 == (int)b / 2 && a != b;  // same axis, different sign

        public static Vector3Int ToVector(Axis6 axis) => axis switch {
            Axis6.PosX => Vector3Int.right,
            Axis6.NegX => Vector3Int.left,
            Axis6.PosY => Vector3Int.up,
            Axis6.NegY => Vector3Int.down,
            Axis6.PosZ => new Vector3Int(0, 0, 1),
            Axis6.NegZ => new Vector3Int(0, 0, -1),
            _ => throw new ArgumentOutOfRangeException()
        };
    }
}
```

### GameState (M1 expansion)

```csharp
[Serializable]
public sealed class GameState {
    public int tick;
    public SnakeHeadState playerHead;  // serializable value-type snapshot
}

[Serializable]
public struct SnakeHeadState {
    public Vector3Int position;
    public Axis6 heading;
}
```

### TickSimulation (M1 expansion)

```csharp
public sealed class TickSimulation {
    private readonly SnakeHead _playerHead;
    public GameState State { get; private set; }

    public TickSimulation(Vector3Int startPos, Axis6 startHeading) {
        _playerHead = new SnakeHead(startPos, startHeading);
        State = Snapshot();
    }

    public void SetPlayerIntent(Axis6 direction) => _playerHead.SetIntent(direction);

    public void Tick() {
        _playerHead.Advance();
        State = Snapshot();
    }

    private GameState Snapshot() => new GameState {
        tick = State?.tick + 1 ?? 0,
        playerHead = new SnakeHeadState {
            position = _playerHead.Position,
            heading = _playerHead.Heading
        }
    };
}
```

## Presentation: game loop

`GameLoop` MonoBehaviour in Game.App drives the tick on a fixed interval:

```csharp
// Game.App
public sealed class GameLoop : MonoBehaviour {
    [SerializeField] private float tickInterval = 0.3f;
    public event Action<GameState> OnTick;

    private TickSimulation _sim;
    private Axis6? _pendingIntent;

    void Start() {
        _sim = new TickSimulation(startCell, Axis6.PosX);
        InvokeRepeating(nameof(DoTick), tickInterval, tickInterval);
    }

    public void QueueIntent(Axis6 dir) => _pendingIntent = dir;

    private void DoTick() {
        if (_pendingIntent.HasValue) {
            _sim.SetPlayerIntent(_pendingIntent.Value);
            _pendingIntent = null;
        }
        _sim.Tick();
        OnTick?.Invoke(_sim.State);
    }
}
```

## Presentation: input handler

`WorldAxisInput` MonoBehaviour in Game.Presentation reads controller input each frame and calls `GameLoop.QueueIntent()`:

| Input | World axis |
|---|---|
| Right thumbstick right | Axis6.PosX |
| Right thumbstick left | Axis6.NegX |
| Right thumbstick up | Axis6.PosZ |
| Right thumbstick down | Axis6.NegZ |
| A button / right trigger | Axis6.PosY |
| B button / right grip | Axis6.NegY |

Use Unity's Input System with an `InputActionAsset`. Thumbstick binds to a `Vector2` action; map quadrant to axis. Face buttons bind to button actions.

If body-relative fallback is adopted post-M1, the mapping changes to: "up" = player's current forward (HMD yaw snapped to nearest 90° world axis), "right" = 90° CW from that, etc.

## Presentation: head renderer

`HeadRenderer` MonoBehaviour in Game.Presentation:

```csharp
public sealed class HeadRenderer : MonoBehaviour {
    [SerializeField] private Transform headVisual;
    [SerializeField] private Transform playVolumeRoot;
    [SerializeField] private float cellSize = 0.15f;

    public void OnTick(GameState state) {
        headVisual.position = LogicalToWorld(state.playerHead.position);
    }

    private Vector3 LogicalToWorld(Vector3Int cell) =>
        playVolumeRoot.TransformPoint(new Vector3(cell.x, cell.y, cell.z) * cellSize);
}
```

## Turn-around test protocol (on-device)

1. Launch build. Head starts advancing in world +X.
2. Drive the head a few seconds; note the feel.
3. Physically walk to the opposite side of the volume and rotate ~180°.
4. Drive the head in all six directions.
5. Question: does pressing "right" still feel intentionally world +X, or does it feel inverted/confusing?
6. Repeat at 90° offsets.
7. Record verdict in DECISIONS.md D4.

Tuning levers before declaring failure: try different button layouts, try a visual "compass" overlay, try slowing the tick. If none of these salvage the feel → switch to body-relative.
