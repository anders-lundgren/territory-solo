# Testing Strategy Design

## Assembly structure

```
Assets/
  Tests/
    EditMode/
      Game.Core.Tests.asmdef       ← Layer 1 & 2 & 3 (Edit Mode)
        SnakeHeadTests.cs
        TickSimulationTests.cs
        AiControllerTests.cs
        RoundLifecycleTests.cs
        SerializationTests.cs
        SimulationScenarioTests.cs  ← Layer 2 (multi-tick via SimulationRunner)
        GreedyMesherTests.cs        ← Layer 3 (pure algorithm)
        CoordinateMathTests.cs      ← Layer 3 (LogicalToWorld, ChunkKeyFor)
        GreedyMesherBenchmarks.cs   ← REQ-TEST-8 (Performance Testing)
    PlayMode/
      Game.Presentation.Tests.asmdef  ← Layer 4 (Play Mode headless)
        PlayVolumeAnchorTests.cs       ← uses MRUKTestBase + JSON room
        ChunkManagerTests.cs           ← mesh generation in lightweight scene
        HeadRendererTests.cs           ← visual response to tick events
    Rooms/
      TestRoom.json                  ← compact test room fixture (checked in)
```

## Game.Core.Tests.asmdef

```json
{
  "name": "Game.Core.Tests",
  "references": [
    "Game.Core",
    "Unity.TestFramework.NUnit",
    "Unity.PerformanceTesting"
  ],
  "includePlatforms": ["Editor"],
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
```

## Game.Presentation.Tests.asmdef

```json
{
  "name": "Game.Presentation.Tests",
  "references": [
    "Game.Core",
    "Game.Presentation",
    "Game.App",
    "Unity.TestFramework.NUnit",
    "com.meta.xr.mrutilitykit.tests"
  ],
  "includePlatforms": [],
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
```

## SimulationRunner (in Game.Core)

`SimulationRunner` is a plain C# static class in `Game.Core`, not in a test assembly.
It is useful for Editor tooling and tests alike.

```csharp
namespace Game.Core {
    public static class SimulationRunner {

        public readonly struct TickInput {
            public readonly int AtTick;
            public readonly Axis6 PlayerIntent;
            public TickInput(int atTick, Axis6 intent) {
                AtTick = atTick;
                PlayerIntent = intent;
            }
        }

        /// Runs until round ends or maxTicks exceeded. Returns final state.
        public static GameState RunToCompletion(
            TickSimulation sim,
            IEnumerable<TickInput> inputs = null,
            int maxTicks = 10_000)
        {
            var queue = inputs != null
                ? new Queue<TickInput>(inputs)
                : new Queue<TickInput>();

            for (int t = 0; t < maxTicks; t++) {
                while (queue.Count > 0 && queue.Peek().AtTick == t) {
                    sim.SetPlayerIntent(queue.Dequeue().PlayerIntent);
                }
                sim.Tick();
                if (sim.State.roundStatus != RoundStatus.Playing)
                    return sim.State;
            }
            return sim.State; // maxTicks reached without a result
        }

        /// Runs N ticks capturing a snapshot after every tick. Use for per-tick assertions.
        public static List<GameState> RunCapturing(
            TickSimulation sim,
            int ticks,
            IEnumerable<TickInput> inputs = null)
        {
            var queue = inputs != null
                ? new Queue<TickInput>(inputs)
                : new Queue<TickInput>();
            var snapshots = new List<GameState>(ticks);

            for (int t = 0; t < ticks; t++) {
                while (queue.Count > 0 && queue.Peek().AtTick == t) {
                    sim.SetPlayerIntent(queue.Dequeue().PlayerIntent);
                }
                sim.Tick();
                snapshots.Add(sim.State);
                if (sim.State.roundStatus != RoundStatus.Playing) break;
            }
            return snapshots;
        }
    }
}
```

## SimulationScenarioTests — example tests

```csharp
[TestFixture]
public class SimulationScenarioTests {

    // Player drives straight into the boundary — AI should win
    [Test]
    public void PlayerHitsBoundary_AIWins() {
        var gridMax = new Vector3Int(12, 12, 12);
        var sim = new TickSimulation(
            playerStart: new Vector3Int(1, 1, 1),
            playerHeading: Axis6.PosX,
            aiStart: new Vector3Int(11, 1, 11),
            aiHeading: Axis6.NegX,
            gridMax: gridMax);

        // No player inputs — player drives straight into +X boundary
        var result = SimulationRunner.RunToCompletion(sim, maxTicks: 20);

        Assert.AreEqual(RoundStatus.AIWins, result.roundStatus);
    }

    // AI cannot escape a completely sealed room — game ends
    [Test]
    public void FullyFilledGrid_GameEnds() {
        // Build a 3x3x3 grid (27 cells), pre-fill 25, one snake starts at (0,0,0)
        var sim = TestFixtures.TinyGridSimulation();
        var result = SimulationRunner.RunToCompletion(sim, maxTicks: 500);
        Assert.AreNotEqual(RoundStatus.Playing, result.roundStatus);
    }

    // Player and AI collide on the same tick → Draw
    [Test]
    public void SameTickCollision_Draw() {
        // Set up two snakes converging on the same cell from opposite sides
        // (Requires careful start position selection for the grid size)
        var sim = TestFixtures.HeadOnCollisionSimulation();
        var result = SimulationRunner.RunToCompletion(sim, maxTicks: 100);
        Assert.AreEqual(RoundStatus.Draw, result.roundStatus);
    }

    // Per-tick snapshot: trail grows exactly one cell per tick
    [Test]
    public void TrailGrowsOneCellPerTick() {
        var sim = TestFixtures.DefaultSimulation();
        var snapshots = SimulationRunner.RunCapturing(sim, ticks: 10);
        for (int i = 0; i < snapshots.Count; i++) {
            Assert.AreEqual(i + 1, snapshots[i].occupiedCells.Count,
                $"Expected {i+1} trail cells at tick {i+1}");
        }
    }
}
```

## TestFixtures static class

```csharp
// In Game.Core.Tests assembly (EditMode)
public static class TestFixtures {
    public static readonly Vector3Int DefaultGridMax = new Vector3Int(12, 12, 12);

    public static TickSimulation DefaultSimulation() =>
        new TickSimulation(
            playerStart: new Vector3Int(1, 1, 1),
            playerHeading: Axis6.PosX,
            aiStart: new Vector3Int(10, 1, 10),
            aiHeading: Axis6.NegX,
            gridMax: DefaultGridMax);

    public static TickSimulation TinyGridSimulation() =>
        new TickSimulation(
            playerStart: Vector3Int.zero,
            playerHeading: Axis6.PosX,
            aiStart: new Vector3Int(2, 2, 2),
            aiHeading: Axis6.NegX,
            gridMax: new Vector3Int(2, 2, 2));

    public static TickSimulation HeadOnCollisionSimulation() {
        // Player at (1,1,1) heading PosX; AI at (3,1,1) heading NegX; they meet at (2,1,1)
        return new TickSimulation(
            playerStart: new Vector3Int(1, 1, 1),
            playerHeading: Axis6.PosX,
            aiStart: new Vector3Int(3, 1, 1),
            aiHeading: Axis6.NegX,
            gridMax: new Vector3Int(6, 6, 6));
    }
}
```

## Humble Object pattern for Presentation

MonoBehaviours are thin. Logic lives in plain C# classes:

```
Game.Presentation/
  Meshing/
    GreedyMesher.cs           (pure static, no MB) ← Edit Mode testable
    ChunkMeshBuilder.cs       (plain C#, no MB)    ← Edit Mode testable
    ChunkManager.cs           (MonoBehaviour)       ← thin; delegates to ChunkMeshBuilder
  Visual/
    CoordinateHelper.cs       (pure static)         ← Edit Mode testable
    HeadPositioner.cs         (plain C#)            ← Edit Mode testable
    HeadRenderer.cs           (MonoBehaviour)        ← thin
    WorldFrameBuilder.cs      (pure static)         ← Edit Mode testable
    WorldFrameRenderer.cs     (MonoBehaviour)        ← thin
  XR/
    IPlayVolumeSource.cs      (interface)           ← seam for testing
    MRUKPlayVolumeSource.cs   (MonoBehaviour)        ← real impl, uses MRUK
    PlayVolumeAnchor.cs       (MonoBehaviour)        ← wires IPlayVolumeSource → volume root
```

`IPlayVolumeSource` decouples `PlayVolumeAnchor` from MRUK in tests:

```csharp
// Game.Presentation
public interface IPlayVolumeSource {
    bool IsReady { get; }
    Vector3 FloorCenter { get; }          // world-space floor center
    event Action<Vector3> OnReady;        // fires when room data is available
}

// Real implementation
public sealed class MRUKPlayVolumeSource : MonoBehaviour, IPlayVolumeSource {
    // Wraps MRUK.Instance.SceneLoadedEvent, exposes IPlayVolumeSource API
}
```

For `PlayVolumeAnchorTests`, the Play Mode test creates a `FakePlayVolumeSource` in the
test scene to position the volume without MRUK — OR it uses `MRUKTestBase` + `MRUKPlayVolumeSource`
with a JSON room. Both approaches are valid; use the JSON room approach for closer-to-real coverage.

## Play Mode: PlayVolumeAnchorTests

```csharp
[TestFixture]
public class PlayVolumeAnchorTests : MRUKTestBase {

    [UnityTest]
    public IEnumerator PlayVolumeIsPositionedAtFloorCenter() {
        // Load a known JSON room
        yield return LoadSceneFromJsonStringAndWait(
            System.IO.File.ReadAllText("Assets/Tests/Rooms/TestRoom.json"));

        var room = MRUK.Instance.GetCurrentRoom();
        Assert.IsNotNull(room, "Room should load from JSON");

        // Play volume root should be at floor center + half-height
        var anchor = Object.FindObjectOfType<PlayVolumeAnchor>();
        var expected = room.FloorAnchor.transform.position + Vector3.up * 1f;
        Assert.That(anchor.transform.position.y,
            Is.EqualTo(expected.y).Within(0.01f));
        Assert.That(anchor.transform.position.x,
            Is.EqualTo(expected.x).Within(0.01f));
    }
}
```

## GreedyMesher tests

```csharp
[TestFixture]
public class GreedyMesherTests {

    [Test]
    public void SingleCell_ProducesSixQuads() {
        var cells = new HashSet<Vector3Int> { Vector3Int.zero };
        var mesh = GreedyMesher.Build(cells, Vector3Int.zero, 8, 0.15f);
        // 6 faces × 2 triangles × 3 verts = 36 indices
        Assert.AreEqual(36, mesh.triangles.Length);
    }

    [Test]
    public void TwoAdjacentCells_SharedFaceMerged() {
        var cells = new HashSet<Vector3Int> { Vector3Int.zero, Vector3Int.right };
        var mesh = GreedyMesher.Build(cells, Vector3Int.zero, 8, 0.15f);
        // 10 faces (12 - 2 shared interior faces)
        Assert.AreEqual(10 * 6, mesh.triangles.Length);
    }

    [Test]
    public void FullChunk_NoBoundsOverflow() {
        var cells = new HashSet<Vector3Int>();
        for (int x = 0; x < 8; x++)
        for (int y = 0; y < 8; y++)
        for (int z = 0; z < 8; z++)
            cells.Add(new Vector3Int(x, y, z));

        Assert.DoesNotThrow(() =>
            GreedyMesher.Build(cells, Vector3Int.zero, 8, 0.15f));
    }
}
```

## Performance benchmark

```csharp
[TestFixture]
public class GreedyMesherBenchmarks {

    [Test, Performance]
    public void FullChunk_BuildTime_Under2ms() {
        var cells = new HashSet<Vector3Int>();
        for (int x = 0; x < 8; x++)
        for (int y = 0; y < 8; y++)
        for (int z = 0; z < 8; z++)
            cells.Add(new Vector3Int(x, y, z));

        Measure.Method(() =>
            GreedyMesher.Build(cells, Vector3Int.zero, 8, 0.15f))
            .WarmupCount(5)
            .MeasurementCount(20)
            .Run();

        // The [Performance] attribute captures the data; assert separately if needed:
        // PerformanceTest.Active.SampleGroups[0].Median < 2.0 (ms)
    }
}
```

## CLI runner (runtests.ps1)

```powershell
# runtests.ps1 — place at project root

param(
    [ValidateSet("editmode", "playmode", "all")]
    [string]$mode = "all"
)

# Auto-detect Unity from ProjectVersion.txt
$versionFile = ".\ProjectSettings\ProjectVersion.txt"
$unityVersion = (Get-Content $versionFile | Select-String "m_EditorVersion:").ToString().Split(" ")[1]
$unityExe = "C:\Program Files\Unity\Hub\Editor\$unityVersion\Editor\Unity.exe"

if (-not (Test-Path $unityExe)) {
    Write-Error "Unity $unityVersion not found at $unityExe. Adjust path or install via Hub."
    exit 1
}

$projectPath = $PSScriptRoot
$resultsDir = "$projectPath\TestResults"
New-Item -ItemType Directory -Force $resultsDir | Out-Null

function RunTests([string]$platform) {
    $resultFile = "$resultsDir\TestResults-$platform.xml"
    $logFile = "$resultsDir\TestLog-$platform.txt"
    Write-Host "Running $platform tests..."
    & $unityExe `
        -batchmode `
        -projectPath $projectPath `
        -runTests `
        -testPlatform $platform `
        -testResults $resultFile `
        -logFile $logFile
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
        Write-Error "$platform tests FAILED (exit $exit). See $logFile"
    } else {
        Write-Host "$platform tests passed."
    }
    return $exit
}

$exitCode = 0
if ($mode -eq "editmode" -or $mode -eq "all") {
    $exitCode = RunTests "editmode"
}
if (($mode -eq "playmode" -or $mode -eq "all") -and $exitCode -eq 0) {
    $exitCode = RunTests "playmode"
}
exit $exitCode
```

## TestRoom.json

A hand-crafted minimal room fixture (a simple rectangular room, 4m × 3m × 3m) stored at
`Assets/Tests/Rooms/TestRoom.json`. It does not need to be derived from a real scan — use
MRUK's JSON format but keep it minimal. Refer to MRUK's existing JSON files
(`Library/PackageCache/com.meta.xr.mrutilitykit.../Core/Rooms/Json/MeshBedroom1.json`)
for the exact format.

This fixture gives tests a stable room that won't change between MRUK updates.

## What is NOT unit tested

- Passthrough rendering (on-device only)
- Real MRUK room loading from the device (on-device only)
- Controller input with real hardware (on-device only — use Input System test doubles in editor)
- 72fps frame rate (on-device profiling only)
- M1 turn-around test (subjective human judgement)
