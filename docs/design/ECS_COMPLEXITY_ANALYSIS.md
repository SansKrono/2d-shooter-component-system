# GECS Architecture Complexity & Refactoring Analysis

## Executive Summary
This project implements a custom Entity Component System (GECS) framework to manage 2D roguelike mechanics. While the core motivation of ECS is performance and decoupling, its application in this codebase is **heavily over-engineered**, leading to several architectural critical failures:
1. **High Overhead & GC Pressure**: Spawning basic game elements (like bullets) programmatically allocates multiple custom GDScript Component instances on the heap per spawn, triggering garbage collection and destroying the performance benefits of a flat, memory-adjacent ECS.
2. **Bypassing Godot’s C++ Optimization**: Highly optimized C++ subsystems (such as collision detection, physics movement, and scene-tree lifecycle management) are replaced with CPU-bound, frame-by-frame loops in GDScript (e.g., searching lists, calculating Cartesian distances every frame).
3. **Editor Blindness**: Level designers and artists cannot configure, tweak, or style entity properties, UI elements, collision boundaries, or particle systems because they are generated programmatically by logic-only ECS Systems.
4. **Scattered Logic Pipelines**: Standard game events (like dealing damage and dying) are fragmented across multiple frames and systems (`CombatSystem` -> `C_PendingDamage` -> `DamageResolutionSystem` -> `C_Dead` -> `DeathResolutionSystem` -> `C_SpawnReward` -> `RewardSpawnSystem`), making debugging and tracking state changes incredibly difficult.

By transitioning from a pure "ECS-everything" model to an **idiomatic Godot hybrid model** (using scenes, nodes, signals, resources, and event-driven autoloads), we can reduce code volume by roughly **60%**, eliminate frame-rate stutter caused by GC spikes, and restore full designer-friendly visualization in the Godot IDE.

---

## Detailed Analysis of Over-Engineered Areas

### 1. Transform & Physics Coordination
* **Current Implementation**: [e_player.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/entities/player/e_player.gd), [MovementSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/MovementSystem.gd)
* **How It Works**: 
  - The entity node (`Player` / `Enemy`) is a base `Node2D` acting as a parent.
  - A `CharacterBody2D` named `PhysicsBody` is placed inside the entity.
  - A `C_Physics` component holds a reference to the `PhysicsBody` child.
  - Every single frame, `MovementSystem` queries entities, calculates final velocity, writes it to `c_phys.body.velocity`, calls `move_and_slide()` on the child body, copies `c_phys.body.global_position` back to the parent `Entity.global_position`, and then resets `c_phys.body.position` to `Vector2.ZERO` to keep it centered.
  - A redundant `C_Transform` component is kept in sync with the entity's position.
* **Why It Is Over-Engineered**: 
  - This completely fights Godot's node hierarchy. Godot's physics bodies are designed to be the root of their respective actor scenes.
  - Doing manual frame-by-frame coordinate syncing and coordinate resetting in GDScript adds CPU cost and breaks standard editor gizmos.
* **Refactor Directive**:
  - Make `Player` and `Enemy` scenes root nodes inherit from `CharacterBody2D` directly.
  - Eliminate `C_Physics` and `C_Transform`.
  - Let movement, knockback, and velocity calculations run inside the entity's native `_physics_process(delta)` or a localized controller script.

### 2. Proximity-based Query Loops vs. Physics Area2D
* **Current Implementation**: [TriggerSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/TriggerSystem.gd), [CollectibleSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/CollectibleSystem.gd), [InteractionSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/InteractionSystem.gd), [EnvironmentEffectSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/EnvironmentEffectSystem.gd)
* **How It Works**:
  - Environmental hazards, buttons, collectibles, and interactables are tracked by CPU-bound queries that calculate `distance_to` between the player and all world objects on every frame.
  - Hazards like `EnvironmentEffectSystem` execute a world-wide query for *all* entities with `C_Health` and check distance against the hazard's radius every frame.
* **Why It Is Over-Engineered**:
  - If there are 10 hazards and 100 entities, that’s 1,000 distance checks happening every frame inside GDScript.
  - It bypasses Godot's highly optimized, multi-threaded C++ physics engine broadphase/narrowphase collision systems.
  - Designers cannot see or edit interaction zones or hazard ranges visually in the editor.
* **Refactor Directive**:
  - Replace these systems and components with native `Area2D` nodes and `CollisionShape2D` configurations.
  - Use `body_entered` and `body_exited` signals to detect entities.
  - For hazard pools, keep an array of bodies currently inside the shape and apply tick damage using a local `Timer` node or physics tick.
  - Collectibles should have an inner collision circle (for pickups) and an outer collision circle (for magnetizing) to interpolate their position directly in a lightweight script.

### 3. Programmatic UI Instantiation
* **Current Implementation**: [MinimapSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/MinimapSystem.gd), [InteractionSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/InteractionSystem.gd) (lines 78-102)
* **How It Works**:
  - The `MinimapSystem` runs a process loop, programmatically instantiates a `CanvasLayer` and custom `Node2D` onto the root window (`get_tree().root.add_child`), and performs raw canvas drawing.
  - The `InteractionSystem` programmatically constructs a `Label` node and a `LabelSettings` resource, settings properties, and mounts them to interactable entities on the fly.
* **Why It Is Over-Engineered**:
  - Hardcoding UI positions, colors, styling, and layering in GDScript scripts makes UI design and iteration incredibly tedious.
  - Adding CanvasLayers directly to the viewport root bypasses Godot’s UI anchor, layout, and control container systems.
* **Refactor Directive**:
  - Create a visual `HUD` scene with control containers, labels, and anchors.
  - Design the minimap as a Control scene that can be placed and styled inside the HUD. It can read the dungeon layout from a resource or global manager and call `queue_redraw()`.
  - Place a pre-styled `InteractionPrompt` Control node directly in the interactable actor scenes (e.g. `SpawnerButton`), turning it on and off from the interactable's local script.

### 4. Fragmented Logic Chains & Component Pipelines
* **Current Implementation**: [DamageResolutionSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/DamageResolutionSystem.gd), [DeathResolutionSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/DeathResolutionSystem.gd), [RewardSpawnSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/RewardSpawnSystem.gd), [CombatSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/CombatSystem.gd)
* **How It Works**:
  - Damage calculation is done in `CombatSystem`, which attaches `C_PendingDamage` to the target.
  - Next frame, `DamageResolutionSystem` queries health, applies damage, removes `C_PendingDamage`, and if <= 0, attaches `C_Dead`.
  - Next frame, `DeathResolutionSystem` queries `C_Dead`, triggers `NodeFX` animations, adds a `C_SpawnReward` component to the entity, and marks a timer.
  - Next frame, `RewardSpawnSystem` queries `C_SpawnReward`, instantiates the coin or relic, adds it to GECS, and removes the component.
  - After 0.3 seconds, `DeathResolutionSystem` finally deletes the entity.
* **Why It Is Over-Engineered**:
  - What should be a single execution sequence takes 3-4 frames, requires allocating and deleting multiple components (which is highly CPU-inefficient in GDScript), and splits a simple event ("enemy takes damage and dies") across 4 files and 300+ lines of code.
* **Refactor Directive**:
  - Implement a direct, event-driven method on the target script: `take_damage(amount: float, knockback: Vector2)`.
  - When health reaches 0, call a local `die()` function on the enemy.
  - The `die()` function immediately runs the fade effects (`NodeFX`), instantiates and adds the reward item, and calls `queue_free()`.

### 5. Synergy Polling loops & Circular Dependencies
* **Current Implementation**: [SynergyDetectionSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/SynergyDetectionSystem.gd), [SynergyManager.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/autoloads/SynergyManager.gd), [StatRecalculationSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/StatRecalculationSystem.gd), [SynergyAuraSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/SynergyAuraSystem.gd)
* **How It Works**:
  - `SynergyDetectionSystem` polls every frame to bind relic inventory events and tells `SynergyManager` to evaluate synergies.
  - `SynergyManager` manages synergies, attaches `C_SYNERGY_STATE` to the entity.
  - `StatRecalculationSystem` queries `C_TEAR_STATS` and `C_RELIC_INVENTORY` every frame, allocating dummy component resources (`C_STAT_MODIFIER.new()`) and relationship queries to calculate final stats.
  - `SynergyAuraSystem` queries `C_SYNERGY_STATE`, adds a blank `Node2D` called `SynergyAura`, and modulates its color on every frame.
* **Why It Is Over-Engineered**:
  - Stats and synergies only change when items are collected or lost. Recalculating synergies and stats every single frame (with heap allocations in the query loop!) is a severe performance bottleneck.
  - Programmatically adding blank nodes and modulating them in a system is opaque and hard to debug.
* **Refactor Directive**:
  - Use an event-driven system. When a player collects a relic, trigger a `recalculate_stats()` method on their local `Stats` manager once.
  - The `Stats` manager can check active synergies via the `SynergyManager` autoload and fire a `stats_changed` signal.
  - Visual layers (like an aura node or particles on the player scene) can connect to the player's signals and update their colors and particle visibility once when they change.

### 6. Projectile Instantiation & Homing Queries
* **Current Implementation**: [ShootingSystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/ShootingSystem.gd), [TrajectorySystem.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/systems/TrajectorySystem.gd), [spiral_path_modifier.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/resources/effects/spiral_path_modifier.gd)
* **How It Works**:
  - Spawning a bullet programmatically adds `C_Velocity`, `C_Locomotion`, `C_Payload`, `C_Trajectory`, and `C_Volatility` to the instantiated scene.
  - Homing bullets query `get_nodes_in_group("enemies")` and loop through all of them to find the closest living enemy *every frame for every bullet in the air*.
  - Complex path modifiers like the spiral modifier have to manually zero out velocities and locomotion parameters in the ECS systems, then manually update positions and fake `distance_traveled` stats to bypass the systems' own rules.
* **Why It Is Over-Engineered**:
  - Allocating 5-6 Component objects per bullet is extremely slow and generates huge amounts of garbage, causing stutters in a twin-stick shooter.
  - Querying all nodes in a group repeatedly for every bullet is a classic performance hazard.
  - Writing code to fight your own physics system (`TrajectorySystem`) is a sure sign of architectural friction.
* **Refactor Directive**:
  - Maintain the bullet as an `Area2D` scene with a single script that has variables for speed, damage, range, and homing. Set these parameters on instantiation.
  - Run the bullet movement in `_physics_process(delta)`.
  - For homing, scan for a target on spawn, or let the bullet have a targeting area, and cache the target entity. Interpolate the bullet heading toward the cached target.
  - For complex paths (like spirals), calculate the position equation directly in the bullet script’s movement logic, avoiding the need to mock or fight velocity components.

---

## Component Refactoring & Swapping Guide

Here is a breakdown of GECS components and their direct, user-friendly Godot scene-tree replacements:

| ECS Component | File Category | Over-engineered Role | Godot Scene-Tree / Node Replacement |
| :--- | :--- | :--- | :--- |
| `C_Transform` | `movement` | Syncs positions with Godot nodes | None needed. Node2D already has `global_position` and `rotation`. |
| `C_Physics` | `movement` | Wraps a reference to a `CharacterBody2D` | Inherit from `CharacterBody2D` directly at the scene root. |
| `C_Velocity` | `movement` | Holds velocity direction and knockback | Expose a `velocity` Vector2 and `knockback` Vector2 directly in the actor script. |
| `C_Locomotion` | `movement` | Holds acceleration, speed, and friction | Expose `@export` speed, acceleration, and friction in the actor script. |
| `C_Health` | `combat` | Holds current/max HP | Expose `@export` health variables in the actor script. |
| `C_Resilience` | `combat` | Invulnerability frames and armor values | Expose `@export var armor` and `i_frames_timer` in the actor script. |
| `C_PendingDamage` | `combat` | Deferring damage resolution | Replace with direct call to `take_damage(amount, knockback)`. |
| `C_Dead` | `combat` | Marks entity as dead | Replace with direct `die()` call and `queue_free()`. |
| `C_Spawner` / `C_ChannelSpawner` | `world` | Configuration for spawners | Standard script on Node2D with exported `PackedScene` and a `Timer` child. |
| `C_Trigger` | `world` | Distance check configurations | `Area2D` with a `CollisionShape2D` and signals. |
| `C_Interactable` | `world` | Interaction parameters | `Area2D` detection zone with custom prompt visibility inside the scene. |
| `C_Collectible` | `economy` | Pickup and magnet range stats | `Area2D` pickup zone, with magnet interpolation script on the collectible. |
| `C_RelicInventory` | `economy` | Relics array | Expose `var relics: Array[Relic]` inside the player’s script. |
| `C_AIStateMachine` | `behaviour` | State enums and parameters | Custom `StateMachine` node structure or simple state machine script on the Enemy. |
| `C_Offscreen` | `status` | Marks nodes offscreen | `VisibleOnScreenNotifier2D` child connected to local functions via signals. |
| `C_EnvironmentEffect` | `status` | Damage ticks and active pool durations | `Area2D` hazard zone with collision check and a `Timer` child. |

---

## Suggested Hybrid Architecture (Target State)

By removing the over-engineered boilerplate, the game elements are structured in a standard, modular Godot tree, keeping the codebase simple and maintainable:

```mermaid
graph TD
	subgraph Dungeon Scene Tree
		Main[DungeonGameScene] --> Runner[DungeonGameRunner]
		Main --> HUD[HUD CanvasLayer]
		HUD --> Minimap[Minimap Control]
		HUD --> StatusBars[Health & Mana UI]
		
		Main --> EntitiesNode[Entities Node]
		EntitiesNode --> Player[Player: CharacterBody2D]
		Player --> SpriteP[Sprite2D]
		Player --> CameraP[Camera2D]
		Player --> InteractDetect[Interaction Area2D]
		
		EntitiesNode --> Enemy[Enemy: CharacterBody2D]
		Enemy --> SpriteE[Sprite2D]
		Enemy --> AI[AI StateMachine Node]
		Enemy --> Hurtbox[Hurtbox Area2D]
		
		EntitiesNode --> Bullet[Bullet: Area2D]
		Bullet --> SpriteB[Sprite2D]
		Bullet --> Targeter[Targeting Area2D]
		
		EntitiesNode --> Trigger[TriggerButton: Area2D]
		Trigger --> SpriteT[Sprite2D]
		Trigger --> Prompt[InteractionPrompt Control]
	end

	subgraph Global Systems (Event-Driven Autoloads)
		Autoloads[Autoloads] --> EventBus[EventBus Autoload]
		Autoloads --> SynergyMgr[SynergyManager Autoload]
	end
```

### Key Architectural Rules for the Refactor:
1. **Event-Driven Communications**: Replace frame-by-frame queries with signals. If an action occurs (e.g. player collects relic), emit a signal. Nodes that need to react (e.g. stats recalulation, UI updates) connect to this signal and execute their code *once*.
2. **Encapsulate Movement & Physics**: Let actors control themselves. Instead of a global `MovementSystem` querying and overriding variables, the player or enemy's own `_physics_process(delta)` updates its position natively.
3. **Use the Inspector**: Expose variables as `@export` in scripts, allowing designers to set stats, configure spawn lists, and build visual level components directly in the Godot Editor.
4. **Leverage Native Areas**: Let the physics engine do the heavy lifting for overlaps, triggers, interaction detectors, and hazards.
