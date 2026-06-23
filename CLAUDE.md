# 2D Roguelike Component System

## Hard Rules

- **ECS architecture**: Game logic via Entity, Component, System pattern (addon: `addons/gecs`)
- **Components**: Immutable data containers in `components/{category}/`; no logic. Categories: `combat`, `movement`, `projectile`, `player`, `economy`, `world`, `synergy`, `status`, `behaviour`, `debug`
- **Systems**: Pure functional transforms in `systems/`; read components, write state
- **Projectiles**: Use C_Velocity (direction) + C_Locomotion (speed) for movement
- **Naming**: `C_*` for components, `*System` for systems, `e_*` for entity scenes
- **No physics inheritance**: Projectiles & players use C_Physics + MovementSystem, not CharacterBody2D

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

- **Refuse**: Non-ECS architectural changes (e.g., inherit from CharacterBody2D for player)
- **Ask first**: Changes to core system loop, adding new resource types, cross-cutting concerns
- **Clarify**: If component shape or system responsibility is ambiguous