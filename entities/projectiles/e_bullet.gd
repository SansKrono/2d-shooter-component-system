@tool
class_name Bullet
extends Entity

var shooter: Entity = null

@onready var area_2d: Area2D = $Area2D

func define_components() -> Array:
	return [
		C_Velocity.new(Vector2.ZERO),
		C_Lifetime.new(2.0)
	]

func on_ready():
	# Only run logic in-game, not in editor
	if not Engine.is_editor_hint():
		area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	var target = area.owner as Entity
	if target and target != self and not target is Bullet and target != shooter:
		CombatSystem.apply_hit(self, target)
