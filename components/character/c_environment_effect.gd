class_name C_EnvironmentEffect
extends Component

const EFFECT_TECH_HAZARD: String = "tech_hazard"
const EFFECT_CORRUPTION: String = "corruption"

@export var effect_type: String = EFFECT_TECH_HAZARD
@export var duration: float = 3.0
@export var remaining_time: float = 3.0
@export var radius: float = 20.0
@export var intensity: float = 1.0
@export var damage_per_tick: float = 5.0
@export var tick_interval: float = 0.5
@export var time_since_last_tick: float = 0.0

func _init(etype: String = EFFECT_TECH_HAZARD, dur: float = 3.0, rad: float = 20.0, dmg: float = 5.0) -> void:
	effect_type = etype
	duration = dur
	remaining_time = dur
	radius = rad
	damage_per_tick = dmg
	if etype == EFFECT_CORRUPTION:
		radius = 30.0
		damage_per_tick = 3.0
		tick_interval = 0.2
