# Remaining ECS Refactoring Phases

**Status**: In Progress (complexity-refactor branch)  
**Last Updated**: 2026-06-24  
**Target Architecture**: Hybrid Godot scene-tree model with event-driven autoloads

---

## Overview

This document details the remaining work to transition from the over-engineered "ECS-everything" model to an idiomatic hybrid Godot architecture. The refactoring is organized into 6 sequential phases, each addressing a major architectural pain point identified in `ECS_COMPLEXITY_ANALYSIS.md`.

**Expected Impact**:
- ~60% code reduction
- Elimination of frame-rate stutter from GC pressure
- Full designer visibility in the Godot editor
- Easier debugging via signal-based event flows

---

## Phase 1: Transform & Physics Coordination ⏳ (In Progress)

**Scope**: Refactor player and enemy actors to inherit from `CharacterBody2D` directly, eliminating manual coordinate syncing.

**Current State**:
- Player/Enemy scenes use `Node2D` root with internal `CharacterBody2D` child
- `C_Physics` component wraps the physics body reference
- `MovementSystem` manually syncs positions every frame
- `C_Transform` tracks position redundantly

**Files to Modify**:
- `entities/player/e_player.gd` → Use `_physics_process(delta)` for movement
- `entities/player/e_player.tscn` → Root hierarchy refactor
- `entities/enemies/e_enemy.gd` → Use `_physics_process(delta)` for movement
- `entities/enemies/e_enemy.tscn` → Root hierarchy refactor
- `systems/MovementSystem.gd` → Delete (merge logic into actor scripts)
- `components/movement/C_Physics.gd` → Delete
- `components/movement/C_Transform.gd` → Delete
- `components/movement/C_Velocity.gd` → Migrate to actor instance variable
- `components/movement/C_Locomotion.gd` → Migrate to `@export` variables

**Acceptance Criteria**:
- [ ] Player scene root is `CharacterBody2D`
- [ ] Enemy scene root is `CharacterBody2D`
- [ ] Player moves smoothly via `_physics_process(delta)` with knockback support
- [ ] Enemy AI movement uses localized `_physics_process(delta)` or AI state script
- [ ] No manual position reset/syncing code
- [ ] All position changes visible in editor inspector during play
- [ ] `MovementSystem` removed from system registry
- [ ] No performance regression in movement responsiveness

---

## Phase 2: Proximity Queries → Area2D Signals ⏳ (In Progress)

**Scope**: Replace CPU-bound distance-check loops with native `Area2D` signal-based detection.

**Current State**:
- `TriggerSystem.gd` polls distance from player to triggers every frame
- `CollectibleSystem.gd` polls distance for pickup magnetization
- `InteractionSystem.gd` polls distance to determine prompt visibility
- `EnvironmentEffectSystem.gd` queries all entities and checks distance to hazards
- Designers cannot visualize collision zones in editor

**Files to Modify**:
- `systems/TriggerSystem.gd` → Delete (replace with Area2D signals)
- `systems/CollectibleSystem.gd` → Partially delete (keep pickup logic only)
- `systems/InteractionSystem.gd` → Delete (move prompt to entity scene)
- `systems/EnvironmentEffectSystem.gd` → Refactor to Area2D tick damage
- `entities/environmental/e_button.gd` → Add Area2D with signal handlers
- `entities/environmental/e_trigger.gd` → Convert to pure Area2D script
- `entities/collectibles/e_coin.gd` → Use Area2D for pickup zone + magnet script
- `components/world/C_Trigger.gd` → Delete
- `components/world/C_Interactable.gd` → Delete
- `components/economy/C_Collectible.gd` → Delete (convert to scene properties)

**Acceptance Criteria**:
- [ ] All interaction zones use `Area2D` + `CollisionShape2D`
- [ ] Button detection via `body_entered` / `body_exited` signals
- [ ] Collectible magnetization uses direct `Tween` interpolation
- [ ] Hazard damage uses `Area2D` + `Timer` for tick application
- [ ] Interaction prompts visible in editor as Control nodes in scenes
- [ ] Designers can see and edit collision boundaries in 2D viewport
- [ ] No `get_nodes_in_group()` queries in per-frame loops
- [ ] `TriggerSystem`, `InteractionSystem` removed from registry
- [ ] Distance-based detection gone entirely

---

## Phase 3: Programmatic UI → Scene-Based HUD ⏳ (Blocked)

**Scope**: Consolidate all UI into a designer-friendly `HUD` scene with proper Control hierarchy.

**Current State**:
- `MinimapSystem.gd` adds `CanvasLayer` and draws via raw canvas calls
- `InteractionSystem.gd` (lines 78-102) creates `Label` + `LabelSettings` on-the-fly
- UI styling and positioning hardcoded in GDScript
- No visual designer workflow

**Files to Create**:
- `scenes/ui/HUD.tscn` → Root CanvasLayer with Control containers
- `scenes/ui/Minimap.tscn` → Control node with minimap drawing logic
- `scenes/ui/InteractionPrompt.tscn` → Reusable prompt Control node
- `scenes/ui/HealthBar.tscn` → Health UI for player + enemies

**Files to Modify**:
- `systems/MinimapSystem.gd` → Delete (replace with HUD autoload signal listeners)
- `systems/InteractionSystem.gd` → Delete (prompts now in entity scenes)
- Create `autoloads/HUD.gd` → Manages global HUD state and connections
- `scenes/dungeon_game_scene.tscn` → Add HUD scene as child

**Acceptance Criteria**:
- [ ] HUD scene exists in `scenes/ui/HUD.tscn` with all UI elements visible in editor
- [ ] Minimap renders via `queue_redraw()` instead of raw canvas calls
- [ ] Interaction prompts are Control nodes placed in interactable entity scenes
- [ ] All UI colors, fonts, and positioning configurable in `.tres` theme resource
- [ ] No `add_child()` UI instantiation in systems
- [ ] MinimapSystem, related UI creation code removed
- [ ] UI updates via signal connections (e.g., player `health_changed` → HUD update)
- [ ] Designers can style and position UI in the Godot editor

**Blocker**: Phase 2 (Area2D signals) must be complete to know what interaction prompts need to display.

---

## Phase 4: Damage & Death Resolution Pipeline 🔴 (Not Started)

**Scope**: Consolidate fragmented damage/death logic into single, event-driven methods on actors.

**Current State**:
- `CombatSystem.gd` → Attaches `C_PendingDamage`
- `DamageResolutionSystem.gd` → Applies damage, marks `C_Dead`
- `DeathResolutionSystem.gd` → Runs death animation, spawns reward
- `RewardSpawnSystem.gd` → Instantiates drop items
- Damage flow spans **4 systems**, **3 components**, **4 frames**

**Files to Modify**:
- `entities/player/e_player.gd` → Add `take_damage(amount, knockback)` method
- `entities/enemies/e_enemy.gd` → Add `take_damage(amount, knockback)` method
- `systems/CombatSystem.gd` → Call `take_damage()` directly instead of component attachment
- `systems/DamageResolutionSystem.gd` → Delete
- `systems/DeathResolutionSystem.gd` → Delete (merge into `die()` method)
- `systems/RewardSpawnSystem.gd` → Delete (reward spawning in `die()`)
- `systems/KnockbackSystem.gd` → Delete (merge knockback into velocity handling)
- `components/combat/C_PendingDamage.gd` → Delete
- `components/combat/C_Dead.gd` → Delete
- `components/world/C_SpawnReward.gd` → Delete

**Acceptance Criteria**:
- [ ] `take_damage(amount: float, knockback: Vector2)` method on Player/Enemy
- [ ] Damage resolved instantly, not deferred to next frame
- [ ] Death animation + reward spawn triggered immediately in `die()` method
- [ ] No `C_PendingDamage`, `C_Dead`, or `C_SpawnReward` components
- [ ] `DamageResolutionSystem`, `DeathResolutionSystem`, `RewardSpawnSystem` removed
- [ ] Knockback applied directly to velocity in `take_damage()` or movement script
- [ ] Death logic single-frame: call `die()` → animate → spawn reward → `queue_free()`
- [ ] Combat events emitted via signals for UI/audio feedback (e.g., `damage_taken`, `died`)

**Dependency**: Phase 1 (CharacterBody2D actors) must be complete.

---

## Phase 5: Synergy & Stats Event-Driven Updates 🔴 (Not Started)

**Scope**: Replace every-frame synergy polling with event-driven stat recalculation on item pickup/drop.

**Current State**:
- `SynergyDetectionSystem.gd` polls every frame
- `StatRecalculationSystem.gd` recalculates stats + allocates dummy components every frame
- `SynergyAuraSystem.gd` modulates aura color every frame
- Stats only change on relic inventory change, not every frame

**Files to Modify**:
- `systems/SynergyDetectionSystem.gd` → Delete
- `systems/StatRecalculationSystem.gd` → Delete
- `systems/SynergyAuraSystem.gd` → Delete (replace with signal-connected script)
- `entities/player/e_player.gd` → Add `StatsManager` inner class or node
- Create `components/economy/C_RelicInventory.gd` → Keep (now just a simple data holder)
- Modify `entities/player/e_player.gd` → Emit `stats_changed` signal on synergy/relic changes
- `autoloads/SynergyManager.gd` → Modify to provide `evaluate_synergies()` method
- `entities/player/e_player.tscn` → Add `SynergyAura` Node2D child for visual feedback

**Acceptance Criteria**:
- [ ] `Stats` manager holds current stats (health, damage, speed, etc.)
- [ ] `recalculate_stats()` called only when inventory changes
- [ ] `stats_changed(new_stats)` signal emitted once per inventory change
- [ ] Synergy aura updates via signal listener, not every-frame system
- [ ] No per-frame synergy polling or stat recalculation
- [ ] `SynergyDetectionSystem`, `StatRecalculationSystem`, `SynergyAuraSystem` removed
- [ ] No heap allocations in per-frame loops
- [ ] Stats visible in editor via `@export` or debug inspector

**Dependency**: Phase 2 (Area2D signals) recommended for collectible pickup events.

---

## Phase 6: Projectile Scene Simplification 🔴 (Not Started)

**Scope**: Eliminate multi-component bullet architecture; use self-contained `Area2D` script.

**Current State**:
- Each bullet allocated with `C_Velocity`, `C_Locomotion`, `C_Payload`, `C_Trajectory`, `C_Volatility`
- `ShootingSystem.gd` + `TrajectorySystem.gd` manage movement
- Homing bullets query all enemies every frame via `get_nodes_in_group("enemies")`
- Complex path modifiers fight the velocity/trajectory system

**Files to Modify**:
- `entities/projectiles/e_bullet.gd` → Self-contained movement + collision logic
- `systems/ShootingSystem.gd` → Delete `C_*` attachment; call `instantiate()` + set params
- `systems/TrajectorySystem.gd` → Delete
- `components/projectile/C_Velocity.gd` → Delete (instance var on bullet)
- `components/projectile/C_Trajectory.gd` → Delete
- `components/projectile/C_Volatility.gd` → Delete
- `components/projectile/C_Payload.gd` → Delete
- `resources/effects/spiral_path_modifier.gd` → Simplify (calculate position directly)
- `entities/projectiles/e_bullet.tscn` → Ensure Area2D + Sprite + CollisionShape hierarchy

**Acceptance Criteria**:
- [ ] Bullet scene: `Area2D` root with `Sprite2D` + `CollisionShape2D` children
- [ ] Bullet script has `@export` variables: `speed`, `damage`, `max_range`, `homing_enabled`
- [ ] Movement calculated in `_physics_process(delta)` directly on bullet
- [ ] Homing target cached on spawn, not queried every frame
- [ ] No multi-component allocation per bullet spawn
- [ ] Complex paths (spirals, waves) calculated via closed-form equations in movement code
- [ ] `ShootingSystem`, `TrajectorySystem` removed
- [ ] No more fighting built-in velocity/trajectory components
- [ ] No GC stutter during high bullet counts

**Dependency**: Phase 1 (CharacterBody2D / Area2D refactor) provides architectural foundation.

---

## Summary Table: Component Removal Roadmap

| Component | Phase | Status | Replacement |
| :--- | :--- | :--- | :--- |
| `C_Transform` | 1 | 🔴 | Node2D native `global_position` |
| `C_Physics` | 1 | 🔴 | CharacterBody2D root node |
| `C_Velocity` | 1 | 🔴 | Instance variable on actor |
| `C_Locomotion` | 1 | 🔴 | `@export` on actor script |
| `C_Trigger` | 2 | 🔴 | Area2D + signals |
| `C_Interactable` | 2 | 🔴 | Area2D in scene + Control prompt |
| `C_Collectible` | 2 | 🔴 | Area2D + magnet Tween |
| `C_EnvironmentEffect` | 2 | 🔴 | Area2D + Timer |
| `C_PendingDamage` | 4 | 🔴 | Direct `take_damage()` call |
| `C_Dead` | 4 | 🔴 | Direct `die()` call |
| `C_SpawnReward` | 4 | 🔴 | Reward spawning in `die()` |
| `C_Offscreen` | — | ⏳ | `VisibleOnScreenNotifier2D` |
| `C_AIStateMachine` | — | ⏳ | Enemy script state machine |
| `C_RelicInventory` | 5 | ⏳ | Player inventory array |
| `C_Health` | 4 | ⏳ | Player/Enemy health variable |
| `C_Resilience` | 4 | ⏳ | Invulnerability manager script |
| `C_Velocity` (projectile) | 6 | 🔴 | Bullet script property |
| `C_Trajectory` | 6 | 🔴 | Bullet movement equation |
| `C_Volatility` | 6 | 🔴 | Bullet script behavior |
| `C_Payload` | 6 | 🔴 | Bullet script damage/effect |

**Legend**: 🔴 = Not Started | ⏳ = In Progress | ✅ = Complete

---

## System Removal Roadmap

| System | Phase | Status | Replacement |
| :--- | :--- | :--- | :--- |
| `MovementSystem` | 1 | 🔴 | Actor `_physics_process(delta)` |
| `TriggerSystem` | 2 | 🔴 | Area2D signals |
| `CollectibleSystem` | 2 | ⏳ | Area2D + Tween |
| `InteractionSystem` | 2 | 🔴 | Area2D + entity scene prompts |
| `EnvironmentEffectSystem` | 2 | 🔴 | Area2D + Timer |
| `DamageResolutionSystem` | 4 | 🔴 | Actor `take_damage()` method |
| `DeathResolutionSystem` | 4 | 🔴 | Actor `die()` method |
| `RewardSpawnSystem` | 4 | 🔴 | Spawned in `die()` |
| `KnockbackSystem` | 4 | 🔴 | Movement script + `take_damage()` |
| `SynergyDetectionSystem` | 5 | 🔴 | Signal-driven recalc |
| `StatRecalculationSystem` | 5 | 🔴 | Player `recalculate_stats()` method |
| `SynergyAuraSystem` | 5 | 🔴 | Aura node + signal listener |
| `ShootingSystem` | 6 | 🔴 | Direct instantiation + param set |
| `TrajectorySystem` | 6 | 🔴 | Bullet `_physics_process()` |
| `ScreenShakeSystem` | — | ⏳ | Keep (minimal impact) |
| `InvulnerabilitySystem` | — | ⏳ | Keep or merge into actor |
| `HealthSystem` | — | ⏳ | Merge into actor or autoload |
| `VisibilitySystem` | — | ⏳ | Keep (optimization) |

---

## Testing & Verification Checklist

After each phase, validate:

- [ ] No GDScript reload errors on scene open
- [ ] Game runs at 60 FPS without stutter
- [ ] Player movement responsive (8-directional input)
- [ ] Enemy AI pathfinding and movement smooth
- [ ] Projectile spawning and collision functional
- [ ] Damage/death flow instant and reliable
- [ ] UI updates reflect game state correctly
- [ ] All interactive elements respond to player input
- [ ] Designers can edit and preview in editor
- [ ] Git diff shows ~10-15% code reduction per phase
- [ ] No regression in existing features

---

## Git Workflow

Each phase should be:
1. **Branched** from `complexity-refactor`
2. **Tested** thoroughly before merge
3. **Committed** with clear messages referencing phase number
4. **Reviewed** for architectural consistency

Example commit pattern:
```
refactor(phase-1): make player/enemy inherit from CharacterBody2D

- Root nodes now CharacterBody2D, not Node2D
- Movement via _physics_process(delta) instead of MovementSystem
- Removed C_Physics, C_Transform, C_Velocity components
- Position syncing eliminated; native physics integration
```

---

## Estimated Timeline

- **Phase 1**: 3-4 days (foundational, affects all actors)
- **Phase 2**: 3-4 days (wide scope, many files)
- **Phase 3**: 2-3 days (UI-specific, can be parallel with others)
- **Phase 4**: 2-3 days (combat pipeline consolidation)
- **Phase 5**: 1-2 days (stats event-driven refactor)
- **Phase 6**: 1-2 days (projectile simplification)

**Total**: ~2-3 weeks for full refactor at 4-6 hours/day

---

## Notes for AI Agents

- Each phase is **independent enough to be tackled in isolation**, but **sequential ordering is strongly recommended** to avoid circular dependencies.
- **Phase 1 is critical**: CharacterBody2D hierarchy is the foundation for Phases 2, 4, and 6.
- **Phase 3 can run in parallel** with Phases 1–2, as UI has minimal dependencies on combat/physics logic.
- If a phase is blocked, **document the blocker clearly** and escalate to the user.
- Use **`@export` variables extensively** to allow designers to configure behavior without touching code.
- All signal-based communication should use clear, consistent naming: `{noun}_{verb}` (e.g., `player_died`, `health_changed`, `synergy_updated`).
