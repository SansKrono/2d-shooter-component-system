class_name C_InteractableDebug
extends Component

@export var color: Color = Color(0, 1, 0, 0.3)
@export var line_width: float = 2.0

func _init(col: Color = Color(0, 1, 0, 0.3), width: float = 2.0):
	color = col
	line_width = width
