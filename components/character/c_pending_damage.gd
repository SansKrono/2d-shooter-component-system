class_name C_PendingDamage
extends Component

@export var amount: float = 0.0
@export var knockback_vector: Vector2 = Vector2.ZERO

func _init(amt: float = 0.0, kb_vec: Vector2 = Vector2.ZERO) -> void:
	amount = amt
	knockback_vector = kb_vec
