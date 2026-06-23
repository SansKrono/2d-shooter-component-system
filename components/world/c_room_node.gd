class_name C_RoomNode
extends Component

var id: int = 0
var room_type: String = "normal"   # "start","normal","shop","treasure","boss"
var size: String = "medium"        # "small","medium","large"
var zone: String = "tech"          # "tech","hybrid","corruption"
var grid_pos: Vector2i = Vector2i.ZERO
var world_pos: Vector2 = Vector2.ZERO
var prefab_key: String = ""        # e.g. "normal_small_a"
var connections: Array[int] = []
var is_cleared: bool = false
var is_visited: bool = false
var is_on_main_path: bool = false
var corruption_level: float = 0.0

func _init(p_id: int = 0, p_type: String = "normal", p_size: String = "medium") -> void:
	id = p_id
	room_type = p_type
	size = p_size
