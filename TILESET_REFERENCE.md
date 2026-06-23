# dungeon_69b.png — Tile Reference
## 256×320px · 8 columns × 10 rows · 32×32px per tile · RGBA

---

## Atlas Map (col, row)

```
     Col 0       Col 1       Col 2       Col 3       Col 4       Col 5       Col 6       Col 7
Row 0  COR_TL    W_STONE     W_STONE     W_TOP       W_STONE     [EMPTY]     [EMPTY]     COR_TR
Row 1  W_STONE   W_STONE     W_STONE     [VOID]      W_STONE     W_STONE     W_STONE     W_STONE
Row 2  W_STONE   W_TOP       W_STONE     FLOOR       SOLID       W_TOP       W_TOP       W_STONE
Row 3  W_WEST    [VOID]      W_STONE     FLOOR       W_STONE     W_TOP       [VOID]      W_EAST
Row 4  W_STONE   W_SOUTH     FLOOR       FLOOR       FLOOR       FLOOR       W_SOUTH     W_STONE
Row 5  [EMPTY]   W_STONE     W_TOP       FLOOR       SOLID       SOLID       W_STONE     [EMPTY]
Row 6  [EMPTY]   W_STONE     W_WEST      [VOID]      W_EAST      W_STONE     W_STONE     [EMPTY]
Row 7  COR_BL    W_SOUTH     W_SOUTH     W_SOUTH     W_SOUTH     [EMPTY]     [EMPTY]     COR_BR
Row 8  W_NORTH   W_WEST      W_SOUTH     W_EAST      W_WEST_B    W_EAST_B    W_WEST_C    W_STONE
Row 9  [VOID]    [EMPTY]     [EMPTY]     [EMPTY]     W_NORTH_B   W_NORTH_B   W_NORTH_C   W_NORTH_C
```

---

## Tile Type Definitions

### Do Not Use

| Tile | Reason |
|---|---|
| `[EMPTY]` — (5,0)(6,0)(0,5)(7,5)(0,6)(7,6)(5,7)(6,7)(1,9)(2,9)(3,9) | Alpha = 0. Do not set_cell() here. |
| `[VOID]` — (3,1)(1,3)(6,3)(3,6)(0,9) | Alpha ≈ 68. Semi-transparent edge artefact between cross arms. Do not use. |

---

### FLOOR tile

**Function:** Walkable ground. No collision. Rendered on the floor layer.

| Coord | Measured values | Notes |
|---|---|---|
| **(2,4)** | brightness=56, variance=654, all edges ~48–63 | Primary floor — use this everywhere |
| (3,4) | brightness=56, slight darker bot (30) | Floor with mild top-wall shadow — good variation |
| (4,4) | brightness=56, variance=590 | Cleanest/flattest floor tile |
| (3,2)(3,3)(5,4)(3,5) | brightness=56 | Additional floor variants — same type |

**Use:** Any of the floor coords above. Prefer `(2,4)` as your single canonical floor tile.

**Godot settings:**
```
Collision polygon:   NONE
y_sort_origin:       0
z_index override:    (none — handled by FloorTech/FloorHybrid/FloorCorruption layer)
```

---

### WALL_STONE tile

**Function:** Solid stone fill. Used for all thick wall mass — not the thin directional wall edges.
These tiles have rough stone texture (variance 1500–3000+, medium brightness 90–130).

Recommended stock tiles:
| Coord | Notes |
|---|---|
| **(1,1)** | Clean stone fill, good for interior wall mass |
| **(2,2)** | Good fill tile |
| **(7,8)** | Highest variance (3009) — most textured stone |

**Use:** Fill any tile position that is solidly in the wall and does not need a directional gradient.

**Godot settings:**
```
Collision polygon:   Full 32×32 rectangle
y_sort_origin:       32
Render layer:        Walls TileMapLayer
```

---

### Directional Wall Tiles — PRIMARY SET (Row 8)

This is the canonical set to use in TileMapCarver. Row 8 cols 0–3 form a clean 4-tile rotation:
each tile has exactly one bright edge (lit face) and one dark edge (shadow), with a smooth gradient.

#### W_NORTH — `(0,8)`  ← USE THIS for all north-side (top) walls

```
top = 147  (bright — lit stone top surface facing up)
bot =  51  (dark  — shadow dropping toward floor)
lft = 107, rgt = 107 (neutral sides)
variance = 1448
```
Placed: on the tile ABOVE a floor tile, when there is no floor to the north of that tile.
Represents the player looking down at the top of a wall, with shadow cast southward.

#### W_WEST — `(3,8)`  ← USE THIS for all west-side (left) walls

```
lft = 143  (bright — lit face of the west wall)
rgt =  53  (dark  — shadow toward room interior... wait, reversed)
```
Wait — actually `lft=143, rgt=53` means bright on the LEFT. In a dungeon room, the west wall's outer face is on the LEFT. The room interior is to the RIGHT. The wall face lit from above would cast shadow toward the interior.

Interpretation: This tile is placed where a wall exists to the LEFT and floor exists to the RIGHT. The bright left = outer wall face, dark right = interior shadow.
→ **West wall** (left side of room): `(3,8)` ✓

#### W_EAST — `(1,8)`  ← USE THIS for all east-side (right) walls

```
lft =  53  (dark  — interior shadow)
rgt = 143  (bright — lit face of east wall)
```
Placed where a wall exists to the RIGHT and floor exists to the LEFT.
→ **East wall** (right side of room): `(1,8)` ✓

#### W_SOUTH — `(2,8)`  ← USE THIS for all south-side (bottom) walls

```
top =  54  (dark  — shadowed top)
bot = 138  (bright — lit bottom face)
```
Placed: on the tile BELOW a floor tile, when there is no floor to the south.
Represents the outer wall at the south side of a room, lit at its base.

---

### Secondary/Variant Wall Tiles (Row 8–9, cols 4–7)

These appear to be softer-gradient variants of the main directional set. Use as alternatives or for inner corners:

| Coord | Type | Measured | Notes |
|---|---|---|---|
| (4,8) | W_WEST_B | l=89,r=149 | Softer right-bright, inner corner candidate |
| (5,8) | W_EAST_B | l=148,r=90 | Softer left-bright, inner corner candidate |
| (6,8) | W_WEST_C | l=93,r=141 | Even softer, another wall variant |
| (4,9) | W_NORTH_B | t=129,b=74 | Softer north wall |
| (5,9) | W_NORTH_B | t=129,b=74 | Same as (4,9) — use interchangeably |
| (6,9) | W_NORTH_C | t=112,b=68 | Softer still |
| (7,9) | W_NORTH_C | t=109,b=69 | Same as (6,9) |

**For inner (concave) corners:** Use `(4,8)` for inner NE/SW corners and `(5,8)` for inner NW/SE corners as a starting point. Verify visually in editor.

---

### Outer Corner Tiles

| Coord | Position | Notes |
|---|---|---|
| **(0,0)** | Top-left (NW) outer corner | Stone texture, lft=138 bright (west face lit) |
| **(7,0)** | Top-right (NE) corner | top=86, bot=129 — has bottom gradient |
| **(0,7)** | Bottom-left (SW) corner | Stone texture, similar to (0,0) |
| **(7,7)** | Bottom-right (SE) corner | Stone texture |

**Note on (7,0):** Classified as WALL_BOT due to bot=129 > top=86. This is likely a combined NE corner tile that bridges the top and right wall styles. Use it at NE (top-right) outer corners.

**Godot settings for all corners:**
```
Collision polygon:   Full 32×32 rectangle
y_sort_origin:       32
Render layer:        Walls TileMapLayer
```

---

### SOLID tiles (decorative / pillar / obstacle)

These are nearly uniform in brightness — no texture gradient, low variance (<200):

| Coord | Brightness | Variance | Likely Use |
|---|---|---|---|
| **(4,2)** | 144 (light gray) | 63 | Bright stone block or energy barrier |
| **(4,5)** | 118 (mid gray) | 25 | Neutral stone pillar/obstacle |
| **(5,5)** | 146 (light gray) | 4 | Brightest solid — possibly highlight/glow |

**Use:** Decorative pillars inside rooms, impassable obstacles, or environmental props. Give them full collision if used as physics obstacles.

**Godot settings:**
```
Collision polygon:   Full 32×32 rectangle (if used as obstacles)
y_sort_origin:       32
Render layer:        Walls TileMapLayer (or a separate Props layer)
```

---

### South-side Wall Tiles (Row 7)

Row 7 tiles all have bot ≈ 143–161 (very bright base) and darker tops. These are the outer south wall row — the heavy wall at the very bottom of the demonstration room.

| Coord | top | bot | Notes |
|---|---|---|---|
| (1,7) | 103 | 143 | South outer wall segment |
| (2,7) | 96 | 143 | South outer wall segment |
| (3,7) | 74 | 143 | South outer wall — slightly darker top (more shadow) |
| (4,7) | 95 | 143 | South outer wall segment |

**Use:** These are the "heavy" south wall tiles for the outer boundary of the dungeon. Use `W_SOUTH (2,8)` for thin south walls adjacent to floor; use these row 7 tiles for the outer south boundary.

---

## TileMapCarver.gd — Constant Block

Paste this at the top of `TileMapCarver.gd`. These are the verified atlas coordinates:

```gdscript
# ─────────────────────────────────────────────
# dungeon_69b.png  256×320  8×10 tiles at 32×32
# ─────────────────────────────────────────────
const TILESET_SOURCE := 0

# Floor — walkable, no collision
const FLOOR            := Vector2i(2, 4)   # dark gray, uniform (brightness=56)

# Directional wall tiles — row 8 primary set
# These are the tiles to use in the neighbor-check wall algorithm
const WALL_NORTH       := Vector2i(0, 8)   # bright top (147), dark bottom (51)
const WALL_SOUTH       := Vector2i(2, 8)   # dark top (54), bright bottom (138)
const WALL_WEST        := Vector2i(3, 8)   # bright left (143), dark right (53)
const WALL_EAST        := Vector2i(1, 8)   # dark left (53), bright right (143)

# Outer corner tiles
const CORNER_NW        := Vector2i(0, 0)   # top-left stone corner
const CORNER_NE        := Vector2i(7, 0)   # top-right corner (has bot gradient)
const CORNER_SW        := Vector2i(0, 7)   # bottom-left stone corner
const CORNER_SE        := Vector2i(7, 7)   # bottom-right stone corner

# Inner/concave corner fallbacks — verify in editor, may need adjustment
const INNER_CORNER_NE  := Vector2i(4, 8)   # softer right-bright gradient
const INNER_CORNER_NW  := Vector2i(5, 8)   # softer left-bright gradient
const INNER_CORNER_SE  := Vector2i(4, 9)   # softer top-bright gradient
const INNER_CORNER_SW  := Vector2i(5, 9)   # softer top-bright gradient

# Stone fill — solid wall mass, no gradient
const WALL_STONE       := Vector2i(1, 1)   # standard stone fill

# Alternative wall variants (softer gradient, use for variety or transitions)
const WALL_NORTH_B     := Vector2i(4, 9)   # t=129, b=74
const WALL_NORTH_C     := Vector2i(6, 9)   # t=112, b=68
const WALL_WEST_B      := Vector2i(4, 8)   # softer
const WALL_EAST_B      := Vector2i(5, 8)   # softer

# Decorative solids (pillars, obstacles)
const SOLID_LIGHT      := Vector2i(4, 2)   # uniform bright gray (144)
const SOLID_MID        := Vector2i(4, 5)   # uniform mid gray (118)

# DO NOT USE — transparent/void cells
# (5,0)(6,0)(3,1)(1,3)(6,3)(3,6)(0,5)(7,5)(0,6)(7,6)(5,7)(6,7)(0,9)(1,9)(2,9)(3,9)
```

---

## Collision Settings (Godot TileSet Editor)

Configure one Physics Layer in the TileSet. Set these collision polygons per tile type:

| Tile type | Collision shape | Notes |
|---|---|---|
| `FLOOR` and all floor variants | **None** | No polygon. Fully walkable. |
| `WALL_NORTH` (0,8) | Full 32×32 rect | Player cannot cross this tile |
| `WALL_SOUTH` (2,8) | Full 32×32 rect | |
| `WALL_WEST` (3,8) | Full 32×32 rect | |
| `WALL_EAST` (1,8) | Full 32×32 rect | |
| `WALL_STONE` (1,1) and all stone variants | Full 32×32 rect | |
| `CORNER_NW/NE/SW/SE` | Full 32×32 rect | |
| `INNER_CORNER_*` | Full 32×32 rect | |
| `SOLID_LIGHT`, `SOLID_MID` | Full 32×32 rect | If used as obstacles |
| `VOID` / `EMPTY` tiles | Never placed | No polygon needed |

**Note on WALL_NORTH specifically:** Some top-down engines use a partial collision rectangle (only the top 16px) for north walls so the player can visually "stand at the wall base." For this game, start with full 32×32 and adjust if it feels wrong during playtesting.

---

## Y-Sort Origin Settings (Godot TileSet Editor)

In Godot 4, `y_sort_origin` controls where a tile's y-position is measured FROM when sorting with y_sort_enabled on the TileMapLayer.

**Rule:** Higher y-sort value renders ON TOP (in front) of lower values.

For a 32×32 tile at tile coordinates (col, row):
- World y position = row × 32
- Effective sort value = world_y + y_sort_origin

We want wall tiles to "sort from their base" so:
- Player standing SOUTH of wall (player.y > wall_base) → player renders in front ✓
- Player standing NORTH of wall (player.y < wall_base) → wall renders in front ✓

| Tile type | y_sort_origin | Reasoning |
|---|---|---|
| `FLOOR` (all floor tiles) | **0** | Floor always under everything — use a separate non-y-sorted layer |
| `WALL_NORTH` | **32** | Base of this tile is at its bottom edge (y+32) |
| `WALL_SOUTH` | **0** | Player walks NORTH of south walls — sorts from top |
| `WALL_WEST` | **16** | Side wall — sort from middle to avoid edge cases |
| `WALL_EAST` | **16** | Same |
| `WALL_STONE` | **32** | Solid fill — sorts from bottom |
| All `CORNER_*` | **32** | Sorts from bottom |
| `INNER_CORNER_*` | **32** | Sorts from bottom |
| `SOLID_*` | **32** | Obstacle — sorts from bottom |

---

## Z-Index / Layer Architecture

```
DungeonTileMap
├── FloorTech       z_index=0  y_sort_enabled=false  (tech floor, blue tint)
├── FloorHybrid     z_index=0  y_sort_enabled=false  (neutral floor)
├── FloorCorruption z_index=0  y_sort_enabled=false  (corruption floor, purple tint)
└── Walls           z_index=1  y_sort_enabled=true   (all wall tiles — y-sorts against player)

Player (CharacterBody2D / Entity)
  y_sort_enabled=true
  z_index=1   ← same as Walls, so y-sort comparison works
```

**FloorTileMapLayers:** y-sort disabled. These always render below everything. No z-sorting needed.

**Walls TileMapLayer:** y-sort enabled. Tiles here sort against the player using y_sort_origin. Set per-tile y_sort_origin values as above.

**Player:** Must be on the same z_index (1) as the Walls layer for y-sorting to compare them correctly.

---

## Quick Reference: Carver Algorithm Tile Selection

In `_pick_wall_tile(pos, floor_set)`:

```gdscript
# Cardinal walls (one adjacent floor side)
if only below:          return WALL_NORTH    # (0,8)
if only above:          return WALL_SOUTH    # (2,8)
if only right:          return WALL_WEST     # (3,8)
if only left:           return WALL_EAST     # (1,8)

# Outer corners (two adjacent floor sides, perpendicular)
if below and right:     return CORNER_NW     # (0,0)  or WALL_STONE fallback
if below and left:      return CORNER_NE     # (7,0)  or WALL_STONE fallback
if above and right:     return CORNER_SW     # (0,7)  or WALL_STONE fallback
if above and left:      return CORNER_SE     # (7,7)  or WALL_STONE fallback

# Inner corners (diagonal floor only — floor at one diagonal, no cardinal floors)
if above_left only:     return INNER_CORNER_SE   # (5,9)
if above_right only:    return INNER_CORNER_SW   # (4,9)
if below_left only:     return INNER_CORNER_NE   # (4,8)
if below_right only:    return INNER_CORNER_NW   # (5,8)

# No clear direction (isolated adjacency)
default:                return WALL_STONE    # (1,1)
```

---

## Tiles Not Used in Generation

These appear in the atlas but have no role in the procedural generator:

| Coord | Type | Reason not used |
|---|---|---|
| (3,0) | W_TOP (in-context) | Contextual tile in demo layout, superseded by (0,8) |
| (1,2)(5,2)(6,2)(5,3)(2,5) | W_TOP variants | Same — row 8 cleaner |
| (1,4)(6,4) | W_BOT (in-context) | Superseded by (2,8) |
| (0,3)(7,3)(2,6)(4,6) | W_WEST/EAST (in-context) | Superseded by (1,8)(3,8) |
| (1,7)-(4,7) | W_SOUTH (outer) | Heavy outer south wall — use only for dungeon outer border, not room walls |

---

## Notes

- **Grayscale only:** dungeon_69b is monochrome. Zone colour tinting (TECH=blue, CORRUPTION=purple) is applied via TileMapLayer `modulate` colour — the tiles themselves have no colour.
- **No separate shadow tile needed:** `WALL_NORTH (0,8)` includes the shadow gradient baked in (bright top → dark bottom). There is no separate shadow tile.
- **Inner corners are uncertain:** The `INNER_CORNER_*` assignments at (4,8)(5,8)(4,9)(5,9) are best-available estimates. Verify them visually in the Godot TileSet editor and adjust atlas coords if they look wrong.
- **Tile size is definitively 32×32.** The image is exactly 256×320 = 8×10 tiles.