class_name C_DungeonGraph
extends Component

class Chamber:
	var id: int
	var rect: Rect2i
	var chamber_type: String  # "normal", "boss", "treasure", "shop"
	var corruption_level: float = 0.0
	var connected_corridors: Array[int] = []

	func _init(p_id: int, p_rect: Rect2i, p_type: String, p_corruption: float = 0.0) -> void:
		id = p_id
		rect = p_rect
		chamber_type = p_type
		corruption_level = p_corruption

class Corridor:
	var id: int
	var from_chamber: int
	var to_chamber: int
	var path: PackedVector2Array
	var width: float
	var corruption_level: float = 0.0

	func _init(p_id: int, p_from: int, p_to: int, p_path: PackedVector2Array, p_width: float, p_corruption: float = 0.0) -> void:
		id = p_id
		from_chamber = p_from
		to_chamber = p_to
		path = p_path
		width = p_width
		corruption_level = p_corruption

class CorruptionZone:
	var center: Vector2
	var radius: float
	var intensity: float = 1.0

	func _init(p_center: Vector2, p_radius: float, p_intensity: float = 1.0) -> void:
		center = p_center
		radius = p_radius
		intensity = p_intensity

var chambers: Array[Chamber] = []
var corridors: Array[Corridor] = []
var corruption_zones: Array[CorruptionZone] = []
var dungeon_bounds: Rect2i = Rect2i(0, 0, 2000, 2000)

func get_chamber(id: int) -> Chamber:
	for chamber in chambers:
		if chamber.id == id:
			return chamber
	return null

func get_corridor(id: int) -> Corridor:
	for corridor in corridors:
		if corridor.id == id:
			return corridor
	return null

func find_chamber_at_position(pos: Vector2) -> Chamber:
	for chamber in chambers:
		if chamber.rect.has_point(Vector2i(int(pos.x), int(pos.y))):
			return chamber
	return null
