@tool
class_name Tear
extends Entity

const C_MASS = preload("res://components/character/c_mass.gd")
const C_FIRED_BY = preload("res://components/character/c_fired_by.gd")

@onready var area_2d: Area2D = $Area2D

func define_components() -> Array:
	return [
		C_MASS.new(8.0) # Mp = 8
	]

func on_ready():
	if not Engine.is_editor_hint():
		if area_2d:
			area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	var target = area.owner as Entity
	if target and target != self and not target.name.begins_with("EBullet") and not target is Bullet and not target is Tear:
		var dummy_fired = C_FIRED_BY.new()
		var fired_by = get_relationship(Relationship.new(dummy_fired, ECS.wildcard))
		if fired_by and fired_by.target == target:
			return # Avoid hitting shooter
		
		CombatSystem.apply_hit(self, target)
