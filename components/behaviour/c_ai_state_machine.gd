class_name C_AIStateMachine
extends Component

enum State {
	IDLE,
	CHASE,
	SHOOT
}

@export var current_state: State = State.IDLE
@export var chase_range: float = 300.0
@export var shoot_range: float = 150.0
@export var contact_damage: float = 10.0

func _init(initial_state: State = State.IDLE, chase_rng: float = 300.0, shoot_rng: float = 150.0, dmg: float = 10.0):
	current_state = initial_state
	chase_range = chase_rng
	shoot_range = shoot_rng
	contact_damage = dmg
