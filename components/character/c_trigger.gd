class_name C_Trigger
extends Component

@export var trigger_range: float = 60.0
@export var one_shot: bool = true

var trigger_action: Callable
var triggered: bool = false

func _init(range_val: float = 60.0, action: Callable = Callable(), single_trigger: bool = true) -> void:
	trigger_range = range_val
	trigger_action = action
	one_shot = single_trigger
	triggered = false
