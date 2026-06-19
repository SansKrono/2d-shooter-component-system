@tool
class_name Enemy
extends Entity

func define_components() -> Array:
	return [
		C_Health.new(50.0),
		C_Resilience.new(3.0, 1.5, 0.4), # 3 armor mitigation, 1.5 weight (harder to push)
		C_Velocity.new(Vector2.ZERO, 50.0),
		C_Input.new(),
		C_Shooter.new(1.0, 300.0),
		C_Payload.new(10.0, 150.0),
		C_AIStateMachine.new(C_AIStateMachine.State.IDLE, 300.0, 150.0, 10.0)
	]

func on_ready():
	add_to_group("enemies")
	if not Engine.is_editor_hint():
		var area_2d = get_node_or_null("Area2D") as Area2D
		if area_2d:
			area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	var target = area.owner as Entity
	if target and target is Player:
		CombatSystem.apply_contact_damage(self, target)
