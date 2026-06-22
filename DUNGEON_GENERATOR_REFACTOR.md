# Organic Dungeon Generation Refactor

## Overview
Replace the grid-based room system (Isaac-like) with continuous, organic dungeon generation that fits a cyberpunk-magic setting. The new system generates connected chambers and corridors procedurally, allowing for exploration, dead ends, branching paths, and environmental storytelling through "corruption zones."

---

## Current State (Legacy)
- **Grid-based**: Rooms at discrete Vector2i coordinates
- **Discrete loading**: Rooms completely unload/reload on transitions
- **Cardinal doors only**: 4 directions, simple grid adjacency
- **Static spawning**: Fixed enemy/item positions per room type
- **No environmental narrative**: Layout is purely functional

---

## Target State (New)
- **Node-graph based**: Chambers and corridors connected via a spatial graph
- **Persistent world**: Large dungeon stays in memory, player navigates through continuous space
- **Organic corridors**: Procedurally generated paths between chambers with varying widths/shapes
- **Corruption zones**: Environmental hazard areas that "spread" from sources (bosses, corrupted servers)
- **Environmental exploration**: Secrets hidden in spatial relationships, optional branching paths
- **Thematic narrative**: Visual corruption patterns, tech-magic fusion environments reflected in generation

---

## Architecture Changes

### New Components
```
C_DungeonGraph.gd
  - Stores the dungeon as a node-graph (chambers and corridors)
  - Each node = chamber or corridor segment
  - Edges = connections between nodes
  - Metadata: corruption_level, room_type, difficulty_tier

C_CorruptionZone.gd
  - Represents areas of high magic corruption
  - Affects enemy spawning, movement behavior
  - Has a center point and radius
  - Spreads over time or on player actions

C_DungeonCell.gd
  - Individual tile/cell in the procedural TileMap
  - Tracks: walkable, corruption_amount, entity_spawned
```

### Modified Systems
```
DungeonGenerationSystem.gd (renamed from RoomGenerationSystem)
  - Generates chamber layout using BSP (Binary Space Partitioning) or cellular automata
  - Creates corridor connections between chambers
  - Distributes corruption zones thematically
  - Spawns enemies and items across the dungeon (not per-room)
  - Manages persistent dungeon TileMap

DungeonNavigationSystem.gd (new)
  - Tracks player position in continuous dungeon space
  - Manages visible/active region culling (only render/update nearby cells)
  - Handles region transitions and load/unload of TileMap chunks

CorruptionSystem.gd (new)
  - Updates corruption zones over time
  - Modulates visual effects based on corruption level
  - Affects enemy behavior (corruption makes them stronger/faster)
  - Spreads from sources (boss locations, corrupted servers)
```

---

## Generation Algorithm

### 1. Chamber Layout (BSP - Binary Space Partitioning)
```
Input: dungeon_bounds (e.g., 2000x2000 pixels), target_chamber_count
Process:
  1. Recursively subdivide space into rectangles
  2. Split along axis, creating left/right branches
  3. At leaf nodes, create chambers (not filling entire space)
  4. Connect sibling chambers with corridors
  5. Add some random loops (2-3 extra corridors for exploration)
Output: Array of chamber rects, corridor definitions
```

### 2. Corruption Zone Distribution
```
1. Place "source" corruption zones at boss/major enemy locations
2. Create "infection fronts" that radiates from sources
3. Spread algorithmically: nearby chambers get higher corruption
4. Corruption affects:
   - Enemy spawn density
   - Enemy types (more corrupted = dangerous enemies)
   - Visual tiles (tech walls become corrupted/glitchy)
   - Hazard spawning (corrupted servers explode)
```

### 3. Content Spawning
```
Instead of per-room spawning, spawn based on:
  - Chamber type (small = 1-2 enemies, large = 4-6)
  - Corruption level (high corruption = tougher enemies)
  - Distance from start (later chambers harder)
  - Difficulty tier (configurable per floor)

Treasure/shops distributed across dungeon rather than specific rooms
```

---

## Data Structures

### DungeonGraph (replaces grid Dictionary)
```gdscript
class_name DungeonGraph
extends Resource

class Chamber:
  var id: int
  var rect: Rect2i  # Spatial bounds in dungeon
  var chamber_type: String  # "normal", "boss", "treasure", "shop"
  var corruption_level: float  # 0.0 to 1.0
  var connected_corridors: Array[int]  # IDs of corridors

class Corridor:
  var id: int
  var from_chamber: int
  var to_chamber: int
  var path: PackedVector2Array  # Waypoints for corridor shape
  var width: float  # Variable width (organic feel)
  var corruption_level: float

var chambers: Array[Chamber] = []
var corridors: Array[Corridor] = []
var corruption_zones: Array[CorruptionZone] = []
var tilemap_layer: TileMap  # The actual walkable surface
```

---

## File Structure (New & Modified)

### New Files
```
res://systems/DungeonGenerationSystem.gd
res://systems/DungeonNavigationSystem.gd
res://systems/CorruptionSystem.gd
res://components/character/c_dungeon_graph.gd
res://components/character/c_corruption_zone.gd
res://components/procedural/DungeonBSPGenerator.gd
res://components/procedural/CorridorGenerator.gd
```

### Modified Files
```
res://systems/RoomGenerationSystem.gd  → DELETE or heavily refactor

# Update these to work with persistent dungeon instead of discrete rooms:
res://entities/doors/e_door.gd  → May become deprecated (no discrete rooms)
Any system that reads C_ROOM_DATA  → Migrate to query dungeon position instead
```

---

## Implementation Roadmap

### Phase 1: Dungeon Graph & Basic Generation
1. Create `C_DungeonGraph` component
2. Create `DungeonBSPGenerator.gd` (generates chamber layout)
3. Create `CorridorGenerator.gd` (connects chambers with organic paths)
4. Replace `generate_layout()` in RoomGenerationSystem with new algorithm
5. Output: Visual debug of chamber + corridor layout (no TileMap yet)

### Phase 2: TileMap & Persistence
1. Create procedural TileMap from dungeon graph
2. Paint tiles based on chamber type and corruption level
3. Load/keep entire dungeon in memory (or chunk it if too large)
4. Update player movement to work in continuous space
5. Remove discrete room loading/unloading

### Phase 3: Corruption & Content
1. Create `CorruptionSystem.gd`
2. Implement corruption zone spreading
3. Update enemy spawning to be corruption-aware
4. Visual effects: apply shader/color modulation based on corruption
5. Add environmental hazards (corrupted servers, glitching walls)

### Phase 4: Polish & Exploration
1. Add hidden passages and optional branches
2. Implement environmental storytelling (lore pickups, corrupted artifacts)
3. Add visual "infection" patterns (spreading tech corruption)
4. Create shortcuts and sequence-breaking opportunities

---

## Claude Code Prompt Template

When you're ready to execute this in Claude Code, use this prompt:

```
You are refactoring a roguelike dungeon system from grid-based discrete rooms 
to continuous organic dungeon generation. 

Current System:
- Grid of rooms at Vector2i coordinates
- Rooms load/unload on transition
- 4-directional cardinal doors
- File: res://systems/RoomGenerationSystem.gd

Target System:
- Continuous dungeon with procedurally generated chambers and corridors
- Persistent TileMap (entire dungeon in memory or chunked)
- Organic corridor generation with variable widths
- Corruption zones that affect enemy spawning and visuals
- Player navigates continuous space, no discrete room transitions

Cyberpunk-Magic Theme:
- Chambers look like corrupted server rooms, tech labs, magic nodes
- Corruption spreads visually (glitching tiles, magical auras)
- Environmental storytelling through layout and corruption patterns

PHASE 1 TASK:
1. Create C_DungeonGraph component (stores chamber and corridor data)
2. Create DungeonBSPGenerator.gd (Binary Space Partitioning algorithm)
3. Create CorridorGenerator.gd (connects chambers with organic paths)
4. Refactor DungeonGenerationSystem.gd:
   - Replace generate_layout() with BSP + corridor generation
   - Store result in C_DungeonGraph instead of grid Dictionary
   - Debug-visualize chambers and corridors (can be simple colored rectangles)

Deliverables:
- New component files
- New generator utility files
- Updated DungeonGenerationSystem with new generate_layout() implementation
- Debug visualization that shows chambers (colored rects) and corridors (lines)

Do not implement TileMap or player navigation yet — just the graph generation and visualization.
```

---

## Key Design Decisions for Your Theme

### 1. **Chamber Variety**
- `lab` - Clean tech environment (sparse corruption)
- `server_farm` - Dense equipment, high tech density
- `ritual_chamber` - Magical node, glowing runes
- `corrupted_junction` - Fusion of all three, dangerous
- `vault` - Treasure/boss location

### 2. **Corridor Types**
- `data_conduit` - Wide, clean tech corridor
- `access_tunnel` - Narrow, claustrophobic
- `infection_trail` - Heavily corrupted, visual effects

### 3. **Corruption Mechanics**
- Spreads outward from boss/major enemy locations
- High corruption = more dangerous enemies + environmental hazards
- Visual: tiles shift from clean tech → glitchy → magical → corrupted
- Shader effect: slight screen distortion, color desaturation, glow

### 4. **Environmental Storytelling**
- Lore pickups scattered in chambers
- Corrupted servers that explode (hazards)
- Optional side passages (dead ends or shortcuts)
- "Cleansed" areas (where player cleared corruption) stay cleared

---

## Testing Checklist

Once implemented, verify:
- [ ] Dungeons generate consistently with same seed
- [ ] Chambers are properly spaced (no overlaps)
- [ ] Corridors connect all chambers (graph is connected)
- [ ] Corruption zones visualize correctly
- [ ] Player can walk through entire dungeon without gaps
- [ ] Enemies spawn distributed (not clustered)
- [ ] Performance: TileMap renders smoothly at 60fps

---

## Notes

- **Canvas vs World**: Consider whether dungeon is infinite or bounded. For now, assume bounded (e.g., 2000x2000 pixels max).
- **Chunk Loading**: If dungeon gets large (>5000x5000), implement TileMap chunking to avoid memory issues.
- **Doors**: Discrete door entities become obsolete. Exit/boss gates can be special tiles or environmental triggers instead.
- **Save State**: Player position now saved as `Vector2` in dungeon space, not `Vector2i` room coordinates.