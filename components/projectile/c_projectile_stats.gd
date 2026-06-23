class_name C_ProjectileStats
extends Component

@export var tech_delay: float = 0.15
@export var magic_delay: float = 0.20

func _init(t_delay: float = 0.15, m_delay: float = 0.20) -> void:
	tech_delay = t_delay
	magic_delay = m_delay
