class_name C_Interactable
extends Component

@export var interaction_range: float = 80.0
@export var interaction_text: String = "[E] Interact"
@export var channel: int = -1

var interaction_action: Callable
var triggered: bool = false

func _init(rng: float = 80.0, action: Callable = Callable(), text: String = "[E] Interact", chan: int = -1):
	interaction_range = rng
	interaction_action = action
	interaction_text = text
	channel = chan
	triggered = false
	
