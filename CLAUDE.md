# 2D Roguelike Component System

## Hard Rules

- **ECS architecture**: Game logic via Entity, Component, System pattern (addon: `addons/gecs`)
- **Components**: Immutable data containers in `components/{category}/`; no logic. Categories: `combat`, `movement`, `projectile`, `player`, `economy`, `world`, `synergy`, `status`, `behaviour`, `debug`
- **Systems**: Pure functional transforms in `systems/`; read components, write state
- **Projectiles**: Self-contained `Bullet` entities with `@export` vars (`speed`, `damage`, `direction`, etc.); movement via `_physics_process`, no ECS components for movement
- **Naming**: `C_*` for components, `*System` for systems, `e_*` for entity scenes
- **Actors**: Player and Enemy use `CharacterBody2D` root with Entity script; movement via `_physics_process`; game logic (stats, AI, inventory) via ECS components

## Authority & Links

- **Godot version**: 4.7-stable
- **ECS framework**: `addons/gecs/ecs/` (Entity, Component, System base classes)
- **Main scene**: `scenes/dungeon_game_scene.tscn`
- **Dungeon generation**: BSP-based via `DungeonBSPGenerator`, seeded RNG layouts
- **Room layouts**: DEPRECATED — `resources/rooms/_deprecated/layouts/` (legacy grid-room system)
- **Memory docs**: `.claude/projects/.../memory/MEMORY.md` (project context)

## Setup / Test

- Open `scenes/dungeon_game_scene.tscn` in Godot 4.7
- Run project (F5)
- Test player movement, shooting, enemy spawning in continuous dungeon

## Workflow

- **Add component**: Create `C_MyComponent` in the appropriate `components/{category}/`, extend `Component`, add `_init()`
- **Add system**: Create `MySystem` in `systems/`, extend `System`, implement `query()` and `process()`
- **Hook into world**: Register system in dungeon runner or world attach point
- **Test change**: Run scene, verify no GDScript reload errors, check console logs
- **Commit**: Reference issue/feature, describe ECS change (component shape or system logic)

## Stop Conditions

- **Refuse**: Breaking the ECS/Godot hybrid boundary (e.g., adding movement components back to actors, using per-frame system polling for spatial detection)
- **Ask first**: Changes to core system loop, adding new resource types, cross-cutting concerns
- **Clarify**: If component shape or system responsibility is ambiguous