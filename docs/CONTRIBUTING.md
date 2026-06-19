# Contributing to GECS 2D Shooter & Relic System

Thank you for your interest in contributing! This project is built using a clean Entity Component System (ECS) architecture powered by the GECS addon. Following these guidelines ensures that codebase modularity, performance, and readability remain high.

---

## 🛠 Coding Standards & Style

We adhere to the official [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- **Strong Typing**: Always define static types for parameters, return values, and variables.
  ```gdscript
  var velocity: Vector2 = Vector2.ZERO
  func get_speed() -> float:
      return 100.0
  ```
- **File Naming Conventions**:
  - Components: Prefix files with `c_` (e.g., `components/character/c_my_component.gd`).
  - Systems: CamelCase files ending in `System` (e.g., `systems/MySystem.gd`).
  - Entities: Prefix files with `e_` (e.g., `entities/enemies/e_my_enemy.tscn`).

---

## 🧩 Architectural Design Patterns

This codebase relies on strict separation of concerns:
- **Components** hold **data only**. No processing logic is allowed in components beyond simple instantiation initialization.
- **Systems** process **logic only**. They query entities that possess specific components and operate on their data.
- **Entities** are scene representations that hold and compose components.

### 1. Adding a Component
To add a new component:
1. Create a script in `components/character/` or `components/behaviour/`.
2. Inherit from `Component`.
3. Export variables for data fields.

Example (`c_shield.gd`):
```gdscript
class_name C_Shield
extends Component

@export var max_shield: float = 50.0
@export var current_shield: float = 50.0

func _init(shield: float = 50.0) -> void:
	max_shield = shield
	current_shield = shield
```

### 2. Adding a System
To add a new system:
1. Create a script in the `systems/` directory.
2. Inherit from `System`.
3. Implement `query() -> QueryBuilder` to target relevant components.
4. Implement `process(entities: Array[Entity], components: Array, delta: float)` to execute logic.

Example (`ShieldSystem.gd`):
```gdscript
class_name ShieldSystem
extends System

func query() -> QueryBuilder:
	# Matches entities with a Shield component, but no PlayerInput (meaning AI/enemy only)
	return q.with_all([C_Shield]).with_none([C_Input])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var shield = entity.get_component(C_Shield) as C_Shield
		if shield and shield.current_shield < shield.max_shield:
			shield.current_shield = min(shield.max_shield, shield.current_shield + 2.0 * delta)
```

### 3. Registering the System
Register your system in the main entry point, usually in [main.gd](file:///Users/aaronlozenkovski/Desktop/2d-roguelike-component-system/scripts/main.gd#L33-L48):
```gdscript
world.add_system(ShieldSystem.new())
```

---

## 💎 Creating Relics & Relic Effects

Relics are data-driven `Resource` definitions that modify gameplay.

1. **Relic Effects**: Inherit from `res://resources/effects/relic_effect.gd` and implement `apply(entity: Entity) -> void`.
2. **Relic Resource**: Create a `.tres` file under `resources/relics/` that uses the `Relic` class, filling in the metadata and adding your custom relic effects to its `effects` array.

---

## 🧪 Testing Your Changes

Before submitting your contributions, verify that:
1. **No Editor Errors**: Load the project in the Godot Editor and verify the Output log is clear of syntax/preload warnings.
2. **Headless Execution**: Execute the simulation headlessly to verify the automated timeline completes without runtime exceptions:
   ```bash
   godot --headless --path .
   ```
