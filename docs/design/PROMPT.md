## Task: Organic Dungeon Generation – Phase 1

You are refactoring a roguelike dungeon system from grid-based discrete rooms to continuous organic dungeon generation. The game is a cyberpunk-magic 2D roguelike shooter in Godot with an ECS (entity-component-system) architecture.

### Current System (Isaac-style)
- **File**: `res://systems/RoomGenerationSystem.gd`
- **Architecture**: Grid-based rooms at Vector2i coordinates
- **Rooms**: Discrete scenes loaded/unloaded on door transitions
- **Layout**: Simple pathfinding connecting room nodes
- **Theme**: Generic dungeon (can be cyberpunk-themed visually, but layout is generic)

### Target System (Organic Dungeon)
- **Continuous space**: One persistent TileMap dungeon instead of discrete rooms
- **Procedural generation**: Binary Space Partitioning (BSP) to generate chambers
- **Organic corridors**: Variable-width corridors connecting chambers with natural branching
- **Corruption zones**: Environmental hazard areas that affect enemy spawning
- **No discrete room transitions**: Player walks seamlessly through the dungeon
- **Thematic**: Chambers look like corrupted server rooms, tech labs, magic nodes

### Phase 1 Deliverables
Complete these three components and integrate them into the existing system:

1. **C_DungeonGraph.gd** (new component)
   - Stores the dungeon structure as chambers and corridors
   - Each chamber has: id, spatial rect, type (normal/boss/treasure/shop), corruption_level, connected_corridors
   - Each corridor has: id, from_chamber, to_chamber, path (waypoints), width, corruption_level
   - Includes an array of CorruptionZone objects

2. **DungeonBSPGenerator.gd** (new utility)
   - Implements Binary Space Partitioning algorithm
   - Input: dungeon bounds (e.g., 2000x2000), target_chamber_count (e.g., 8-12)
   - Output: Array of Chamber definitions with rects and types
   - Chambers should have random padding inside their subdivided areas (don't fill entire rect)
   - Assigns room types: one BOSS, one TREASURE, one SHOP, rest NORMAL
   - Distributes special rooms at distance from start

3. **CorridorGenerator.gd** (new utility)
   - Connects two chambers with an organic corridor
   - Input: from_chamber_rect, to_chamber_rect
   - Output: Corridor definition with waypoints (PackedVector2Array) and width (variable between 60-120px)
   - Should create L-bends or gently curved paths
   - Add 2-3 random loops connecting sibling chambers for exploration

4. **Integration into RoomGenerationSystem.gd**
   - Replace `generate_layout()` to use BSP + corridor generation
   - Store result in `C_DungeonGraph` component instead of grid Dictionary
   - Keep `_spawn_enemy()`, `_spawn_boss()`, etc. — they work with positions, not room coords
   - Remove door-based transitions (that's Phase 2)
   - Add debug visualization: render chambers as colored rectangles, corridors as lines

### Debug Visualization
Add a simple visual overlay to verify generation:
- Draw chambers as colored transparent rectangles (different colors for NORMAL/BOSS/TREASURE/SHOP)
- Draw corridors as white lines between chamber centers
- Label chambers with their type (optional: add a DebugDraw layer that renders to canvas)

### Key Design Constraints
- **Single floor for now**: Just generate one dungeon, don't worry about multiple floors yet
- **Bounds**: Dungeon should fit within ~2000x2000 pixels (tunable)
- **Target chamber count**: Aim for 8-12 chambers for a medium-sized floor
- **Corruption zones**: Don't implement spreading yet — just the data structure. Initialize a few corruption zones near the boss location.
- **No TileMap yet**: Phase 1 is graph + visualization. The actual walkable TileMap comes in Phase 2.

### Code Structure
Create these new files:
```
res://systems/DungeonGenerationSystem.gd  (heavily refactored from RoomGenerationSystem)
res://components/character/c_dungeon_graph.gd
res://components/procedural/DungeonBSPGenerator.gd
res://components/procedural/CorridorGenerator.gd
```

Modify:
```
res://systems/RoomGenerationSystem.gd → DELETE or keep as fallback (deprecated)
```

### BSP Algorithm Pseudocode
```
def bsp_partition(rect, depth=0, max_depth=4):
    if depth >= max_depth:
        create_chamber(rect)
        return [chamber]
    
    # Randomly choose horizontal or vertical split
    if random() > 0.5:
        # Split vertically
        split_x = rect.x + random(rect.width * 0.4, rect.width * 0.6)
        left = bsp_partition(Rect(rect.x, rect.y, split_x - rect.x, rect.height), depth+1)
        right = bsp_partition(Rect(split_x, rect.y, rect.right - split_x, rect.height), depth+1)
    else:
        # Split horizontally
        split_y = rect.y + random(rect.height * 0.4, rect.height * 0.6)
        top = bsp_partition(Rect(rect.x, rect.y, rect.width, split_y - rect.y), depth+1)
        bottom = bsp_partition(Rect(rect.x, split_y, rect.width, rect.bottom - split_y), depth+1)
    
    return left + right (or top + bottom)
```

### Corridor Algorithm Pseudocode
```
def connect_chambers(chamber_a, chamber_b):
    start = chamber_a.center
    end = chamber_b.center
    
    # Simple L-bend: horizontal then vertical
    mid_x = (start.x + end.x) / 2
    waypoints = [start, Vector2(mid_x, start.y), end]
    
    # Random width between 60-120
    width = random(60, 120)
    
    return Corridor(waypoints=waypoints, width=width)
```

### Testing Checklist
After implementation:
- [ ] `DungeonBSPGenerator.generate()` produces non-overlapping chambers
- [ ] Chambers are connected by corridors with no gaps
- [ ] Debug visualization shows all chambers and corridors clearly
- [ ] No chamber types overlap (only one BOSS, one TREASURE, one SHOP)
- [ ] Same seed produces identical dungeon (deterministic RNG)
- [ ] Dungeon fits within bounds (no chambers outside 2000x2000)

### Notes on the ECS Architecture
- Your system extends `System` and uses `_world` to add/remove entities
- The `C_DungeonGraph` component holds the static dungeon structure
- Keep the existing `C_ROOM_DATA`, `C_DOOR`, etc. for now — Phase 2 will refactor those
- You can ignore the player position and camera for Phase 1

### Asking for Help
If you need clarification on:
- The BSP algorithm: provide a simple example with a 400x400 rect and 3 chambers
- Corridor generation: provide a visual example of what waypoints and widths should look like
- Integration points: show where the old `grid` Dictionary is referenced and how to replace it

---

## Start with Phase 1 Only

Do not implement:
- TileMap painting or tile generation
- Player walking/continuous movement (keep discrete room transitions for now)
- Corruption zone spreading or effects
- Secrets or hidden passages
- Interior room generation beyond the graph

These are Phases 2–4. Phase 1 is purely: graph generation + debug visualization.

---

## Deliverables Summary

When complete, you should have:
1. Three new `.gd` files (components + generators)
2. Refactored `DungeonGenerationSystem.gd` with `generate_layout()` replaced
3. Debug visualization showing chambers and corridors
4. Console output confirming dungeon generation (similar to existing print statements)
5. No breaking changes to the rest of the codebase

---

## File Locations
Assume your project structure is standard Godot:
```
res://
├── systems/
├── components/
│   └── character/
│   └── procedural/ (create this folder)
├── entities/
└── resources/
```

Create `res://components/procedural/` folder for the new generator utility files.