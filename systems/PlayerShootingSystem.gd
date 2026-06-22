class_name PlayerShootingSystem
extends System

const PROJECTILE_PREFAB = preload("res://prefabs/entities/e_tear.tscn")
const C_TEAR_STATS = preload("res://components/character/c_tear_stats.gd")
const C_TRANSFORM = preload("res://components/character/c_transform.gd")
const C_INPUT = preload("res://components/character/c_input.gd")
const C_VELOCITY = preload("res://components/character/c_velocity.gd")
const C_LOCOMOTION = preload("res://components/character/c_locomotion.gd")
const C_DAMAGE = preload("res://components/character/c_damage.gd")
const C_LIFETIME = preload("res://components/character/c_lifetime.gd")
const C_FIRED_BY = preload("res://components/character/c_fired_by.gd")

func query() -> QueryBuilder:
	return q.with_all([C_TEAR_STATS, C_TRANSFORM, C_INPUT])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var stats = entity.get_component(C_TEAR_STATS)
		var trans = entity.get_component(C_TRANSFORM)
		var input = entity.get_component(C_INPUT) as C_Input
		
		if not stats or not trans or not input:
			continue
			
		# Calculate fire rate in seconds based on the target mechanical formula
		var fire_rate_sec: float = 1.0 / (30.0 / float(max(1, stats.tear_delay + 1)))
		
		if stats.current_cooldown_sec > 0.0:
			stats.current_cooldown_sec -= delta
			
		if input.is_shooting() and stats.current_cooldown_sec <= 0.0:
			stats.current_cooldown_sec = fire_rate_sec
			_spawn_tear(entity, trans.position, input.get_shoot_direction(), stats)

func _spawn_tear(shooter: Entity, spawn_pos: Vector2, direction: Vector2, stats) -> void:
	var tear_entity: Entity = PROJECTILE_PREFAB.instantiate()

	tear_entity.add_component(C_TRANSFORM.new(spawn_pos))
	tear_entity.add_component(C_VELOCITY.new(direction))
	# Projectile uses C_Locomotion with instant acceleration (99999.0) and no decay (99999.0)
	# to travel at constant speed in the given direction
	tear_entity.add_component(C_LOCOMOTION.new(stats.shot_speed * 300.0, 99999.0, 99999.0))
	tear_entity.add_component(C_DAMAGE.new(stats.damage))
	tear_entity.add_component(C_LIFETIME.new(stats.tear_range * 0.15))

	# Establish a relationship to bypass friendly fire and inherit modifiers
	tear_entity.add_relationship(Relationship.new(C_FIRED_BY.new(), shooter))

	# Safely queue the entity addition for the end of the system's execution
	cmd.add_entity(tear_entity)
