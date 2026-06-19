class_name C_Interactable
extends Component

@export var interaction_range: float = 80.0
@export var interaction_text: String = "[E] Interact"
var interaction_action: Callable

func _init(rng: float = 80.0, action: Callable = Callable(), text: String = "[E] Interact"):
	interaction_range = rng
	interaction_action = action
	interaction_text = text
	
