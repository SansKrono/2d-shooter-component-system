@tool
class_name Enemy
extends Entity

enum EnemyType { CHASER, SHOOTER }

const C_ENEMY = preload("res://components/character/c_enemy.gd")
const C_TRANSFORM = preload("res://components/character/c_transform.gd")
const C_MASS = preload("res://components/character/c_mass.gd")

@export var type: EnemyType = EnemyType.CHASER

func _init(t = null) -> void:
	if t != null:
		type = t
	elif not Engine.is_editor_hint():
		type = EnemyType.CHASER if randf() < 0.5 else EnemyType.SHOOTER

func define_components() -> Array:
	if type == EnemyType.CHASER:
		return [
			C_Health.new(50.0),
			C_Resilience.new(3.0, 1.5, 0.4),
			C_Velocity.new(Vector2.ZERO, 80.0),
			C_Input.new(),
			C_AIStateMachine.new(C_AIStateMachine.State.IDLE, 300.0, 0.0, 15.0),
			C_ENEMY.new(),
			C_TRANSFORM.new(Vector2.ZERO),
			C_MASS.new(15.0)
		]
	else:
		return [
			C_Health.new(40.0),
			C_Resilience.new(1.0, 1.0, 0.4),
			C_Velocity.new(Vector2.ZERO, 40.0),
			C_Input.new(),
			C_Shooter.new(1.5, 250.0),
			C_Payload.new(10.0, 150.0),
			C_AIStateMachine.new(C_AIStateMachine.State.IDLE, 300.0, 200.0, 5.0),
			C_ENEMY.new(),
			C_TRANSFORM.new(Vector2.ZERO),
			C_MASS.new(15.0)
		]

func on_ready():
	add_to_group("enemies")
	if not Engine.is_editor_hint():
		var trans = get_component(C_TRANSFORM)
		if trans and "global_position" in self:
			trans.position = self.get("global_position")
			
		var area_2d = get_node_or_null("Area2D") as Area2D
		if area_2d:
			area_2d.area_entered.connect(_on_area_entered)
			
		var sprite = get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			if name == "EBoss":
				sprite.modulate = Color(0.8, 0.3, 0.9)
			elif type == EnemyType.CHASER:
				sprite.modulate = Color(1.0, 0.4, 0.4)
			else:
				sprite.modulate = Color(0.4, 0.6, 1.0)

func _on_area_entered(area: Area2D):
	var target = area.owner as Entity
	if target and target is Player:
		CombatSystem.apply_contact_damage(self, target)

