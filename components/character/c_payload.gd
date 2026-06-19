class_name C_Payload
extends Component

@export var damage: float = 10.0
@export var knockback_force: float = 150.0 # How hard it pushes entities
@export var area_of_effect: float = 0.0 # 0 = single target piercing, >0 = explosion radius

func _init(dmg: float = 10.0, kb: float = 150.0, aoe: float = 0.0):
	damage = dmg
	knockback_force = kb
	area_of_effect = aoe
