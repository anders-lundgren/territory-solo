# M3 Design: Collision, AI, Game Loop

## Core: multi-snake tick with collision

Introduce a `Snake` wrapper that owns a `SnakeHead` and a `SnakeStatus`:

```csharp
public enum SnakeStatus { Alive, Dead }
public enum SnakeOwner { Player, AI }

public sealed class Snake {
    public SnakeHead Head { get; }
    public SnakeStatus Status { get; private set; } = SnakeStatus.Alive;
    public SnakeOwner Owner { get; }

    public Snake(SnakeOwner owner, Vector3Int startPos, Axis6 startHeading) {
        Owner = owner;
        Head = new SnakeHead(startPos, startHeading);
    }

    public void Kill() => Status = SnakeStatus.Dead;
}
```

Revised `TickSimulation.Tick()`:

```csharp
public void Tick() {
    // 1. Collision check (before moving)
    foreach (var snake in _snakes.Where(s => s.Status == SnakeStatus.Alive)) {
        var next = snake.Head.PeekNextPosition();  // does not advance
        if (_state.occupiedCells.Contains(next) || IsOutOfBounds(next))
            snake.Kill();
    }

    // 2. Advance and lay trail for survivors
    foreach (var snake in _snakes.Where(s => s.Status == SnakeStatus.Alive)) {
        var prev = snake.Head.Position;
        snake.Head.Advance();
        _state.occupiedCells.Add(prev);
        OnCellAdded?.Invoke(prev);
    }

    // 3. Evaluate round outcome
    _state.roundStatus = EvaluateOutcome();
    _state.tick++;
}

private RoundStatus EvaluateOutcome() {
    var alive = _snakes.Where(s => s.Status == SnakeStatus.Alive).ToList();
    return alive.Count switch {
        1 => alive[0].Owner == SnakeOwner.Player ? RoundStatus.PlayerWins : RoundStatus.AIWins,
        0 => RoundStatus.Draw,
        _ => RoundStatus.Playing
    };
}
```

`SnakeHead.PeekNextPosition()` returns the position the head would move to without modifying state:
```csharp
public Vector3Int PeekNextPosition() {
    var heading = _pendingIntent ?? Heading;
    return Position + Axis6Extensions.ToVector(heading);
}
```

## Core: round lifecycle

```csharp
public enum RoundStatus { Playing, PlayerWins, AIWins, Draw }

// In GameState:
public RoundStatus roundStatus = RoundStatus.Playing;

// In TickSimulation:
public event Action<RoundStatus> OnRoundEnd;

public void ResetRound() {
    _state.occupiedCells.Clear();
    _state.occupiedCellsList.Clear();
    _state.roundStatus = RoundStatus.Playing;
    _state.tick = 0;
    SeedSnakes();
    foreach (var snake in _snakes)
        snake.Revive();  // reset to Alive + re-position
}

private void SeedSnakes() {
    // Player: corner (1, 1, 1), heading PosX
    // AI:    opposite corner (gridMax.x - 1, 1, gridMax.z - 1), heading NegX
    // Ensure these do not overlap; adjust if grid is small
}
```

Raise `OnRoundEnd` immediately when `EvaluateOutcome()` returns non-Playing.

## Core: AI controller

```csharp
public sealed class AiController {
    private readonly System.Random _rng = new System.Random(42);  // fixed seed for determinism

    public Axis6 ChooseHeading(SnakeHead head, GameState state, Vector3Int gridMax) {
        // 20% random open direction
        if (_rng.NextDouble() < 0.2f) {
            var random = OpenDirections(head, state, gridMax);
            if (random.Count > 0)
                return random[_rng.Next(random.Count)];
        }

        // Prefer current heading if clear 2 cells ahead
        if (IsClear(head.PeekNextPosition(), head.Heading, state, gridMax) &&
            IsClear(Peek2(head), head.Heading, state, gridMax))
            return head.Heading;

        // Fall back to any open direction
        var open = OpenDirections(head, state, gridMax);
        return open.Count > 0 ? open[0] : head.Heading;  // heading → certain death, but graceful
    }

    private bool IsClear(Vector3Int cell, Axis6 heading, GameState state, Vector3Int gridMax) =>
        !state.occupiedCells.Contains(cell) && IsInBounds(cell, gridMax);

    private List<Axis6> OpenDirections(SnakeHead head, GameState state, Vector3Int gridMax) =>
        System.Enum.GetValues(typeof(Axis6))
            .Cast<Axis6>()
            .Where(d => !Axis6Extensions.IsOpposite(d, head.Heading))
            .Where(d => IsClear(head.Position + Axis6Extensions.ToVector(d), d, state, gridMax))
            .ToList();
}
```

`AiController.ChooseHeading()` is called once per tick in `TickSimulation.Tick()` before the AI snake advances, and the result is passed to `aiSnake.Head.SetIntent()`.

## Game.App: GameLoop expansion

```csharp
private void DoTick() {
    // Player input
    if (_pendingPlayerIntent.HasValue) {
        _sim.SetPlayerIntent(_pendingPlayerIntent.Value);
        _pendingPlayerIntent = null;
    }

    // AI intent
    var aiIntent = _aiController.ChooseHeading(_aiSnake.Head, _sim.State, _gridMax);
    _sim.SetAiIntent(aiIntent);

    _sim.Tick();
    OnTick?.Invoke(_sim.State);

    if (_sim.State.roundStatus != RoundStatus.Playing) {
        StopTicking();
        OnRoundEnd?.Invoke(_sim.State.roundStatus);
    }
}
```

## Presentation: round result UI

`RoundResultUI` MonoBehaviour in Game.Presentation (or Game.App):
- A `Canvas` in world space at the top of the play volume
- `TextMeshPro` text: "You Win!", "AI Wins", or "Draw"
- Shown on `OnRoundEnd`, hidden otherwise
- After 2.5 seconds (or on button press): calls `GameLoop.RequestReset()` which calls `sim.ResetRound()` and restarts ticking

## Seeding positions

With a grid of dimensions `gridMax = (W, H, D)`:
- Player: `(1, 1, 1)`, heading `PosX`
- AI: `(W-2, 1, D-2)`, heading `NegX`

For a 13×13×13 grid: player at (1,1,1), AI at (11,1,11). Diagonal separation gives each player clean run-up space at the start.

## Double-death tiebreak

Same-tick double death → **Draw** (recommended). Record in DECISIONS.md. Implementation: `EvaluateOutcome()` returns `RoundStatus.Draw` when `alive.Count == 0`.
