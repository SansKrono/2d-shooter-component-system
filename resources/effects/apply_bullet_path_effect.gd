class_name ApplyBulletPathEffect
extends "res://resources/effects/relic_effect.gd"

const C_BulletPath = preload("res://components/projectile/c_bullet_path.gd")
const BulletPathModifier = preload("res://resources/effects/bullet_path_modifier.gd")

@export var path_modifier: BulletPathModifier = null

func apply(entity: Entity) -> void:
	var c_path = entity.get_component(C_BulletPath) as C_BulletPath
	if not c_path:
		c_path = C_BulletPath.new()
		entity.add_component(c_path)
	
	var already_has = false
	for m in c_path.path_modifiers:
		if m.get_script() == path_modifier.get_script():
			already_has = true
			break
	if not already_has:
		c_path.path_modifiers.append(path_modifier)
