class_name C_Resilience
extends Component

@export var armor: float = 0.0 # Flat damage reduction before hitting C_Health
@export var weight: float = 1.0 # Multiplier against incoming C_Payload knockback (higher = harder to push)
@export var invulnerability_duration: float = 0.5 # i-frames granted after taking damage
@export var current_i_frames: float = 0.0 # Remaining duration of i-frames (runtime)

func _init(arm: float = 0.0, wgt: float = 1.0, i_frames: float = 0.5):
	armor = arm
	weight = wgt
	invulnerability_duration = i_frames
	current_i_frames = 0.0
