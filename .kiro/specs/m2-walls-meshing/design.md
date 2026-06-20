# M2 Design: Trail, Walls, Meshing, Legibility

## Core: occupied-cell store

Expand `GameState`:

```csharp
[Serializable]
public sealed class GameState {
    public int tick;
    public SnakeHeadState playerHead;
    // HashSet is not directly JSON-serializable; store as list and reconstruct
    public List<Vector3Int> occupiedCellsList = new();
    [NonSerialized] public HashSet<Vector3Int> occupiedCells = new();

    public void AfterDeserialize() {
        occupiedCells = new HashSet<Vector3Int>(occupiedCellsList);
    }

    public void BeforeSerialize() {
        occupiedCellsList = new List<Vector3Int>(occupiedCells);
    }
}
```

In `TickSimulation.Tick()`, after advancing the head:

```csharp
var vacated = previousPosition;
_state.occupiedCells.Add(vacated);
OnCellAdded?.Invoke(vacated);   // event consumed by ChunkManager
```

`OnCellAdded` is a `Action<Vector3Int>` event on `TickSimulation` (Presentation subscribes; Core does not know about meshing).

## Presentation: chunk manager

### Constants
```csharp
public const int CHUNK_SIZE = 8;
public static Vector3Int ChunkKeyFor(Vector3Int cell) =>
    new Vector3Int(
        Mathf.FloorToInt((float)cell.x / CHUNK_SIZE),
        Mathf.FloorToInt((float)cell.y / CHUNK_SIZE),
        Mathf.FloorToInt((float)cell.z / CHUNK_SIZE)
    );
```

### ChunkManager MonoBehaviour (Game.Presentation)

```csharp
public sealed class ChunkManager : MonoBehaviour {
    private readonly Dictionary<Vector3Int, ChunkRenderer> _chunks = new();
    private readonly HashSet<Vector3Int> _dirty = new();

    public void OnCellAdded(Vector3Int cell) {
        var key = ChunkKeyFor(cell);
        if (!_chunks.ContainsKey(key))
            _chunks[key] = CreateChunk(key);
        _dirty.Add(key);
    }

    void LateUpdate() {
        foreach (var key in _dirty)
            _chunks[key].Rebuild(_gameState.occupiedCells, key);
        _dirty.Clear();
    }
}
```

### ChunkRenderer

Each chunk owns a single `MeshFilter` + `MeshRenderer` on a child GameObject. `Rebuild()` calls `GreedyMesher.Build()` and assigns the result.

## Greedy meshing algorithm

Standard 3D greedy mesh (Mikola Lysenko approach):

For each of 6 face orientations (axis × direction):
1. Iterate slices perpendicular to the axis
2. In each slice, build a 2D boolean mask: face is exposed if the cell is filled and its neighbor in the face direction is empty
3. Greedy-extend rectangles in the mask (merge adjacent same-material faces)
4. Emit one quad per rectangle with correct normal, UV, and position
5. Combine all quads into a single `Mesh` per chunk

```csharp
public static class GreedyMesher {
    public static Mesh Build(HashSet<Vector3Int> cells, Vector3Int chunkMin, int chunkSize, float cellSize) {
        // ... standard greedy mesh implementation
        // Returns a Mesh with vertices, triangles, normals, UVs
    }
}
```

Input: the full `occupiedCells` set (read-only), a chunk origin, chunk size, and cell world size.
Output: a Unity `Mesh` ready to assign to a `MeshFilter`.

Cell size: 0.15m (13×13×13 cells ≈ 2m volume). Tunable in `GameConfig` (M4).

## See-through wall material

URP `Lit` or `Unlit` shader with:
- **Render queue**: Transparent
- **Surface type**: Transparent, alpha blend
- **Base color alpha**: ~0.3–0.4 (start here; tune in M4)
- **Depth write**: off
- Optionally: a `FresnelEffect` rim highlight on edges to make individual cells pop

Avoid `ZWrite On` with transparent materials — walls behind other walls must show through.

## World-frame overlay

`WorldFrameRenderer` MonoBehaviour in Game.Presentation:

- Renders the 12 edges of the play volume boundary as `LineRenderer` components (or a baked `Mesh`)
- Color scheme (one option): X-axis edges = red, Y-axis edges = green, Z-axis edges = blue
- OR: one face distinctly tinted (e.g. −Z face = "north" in orange) — simpler to read at a glance
- Rendered with a solid, non-transparent unlit material so it is always visible through walls
- Does not obstruct the playfield interior

Recommendation: colored edges (12 lines, 3 colors). One look tells the player which axis is which. Build as a static baked mesh in the Play Volume Root's local space.
