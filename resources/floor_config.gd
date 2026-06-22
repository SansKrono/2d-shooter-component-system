class_name FloorConfig
extends Resource

@export var floor_name: String = "Basement"
@export var min_room_count: int = 6
@export var treasure_room_count: int = 1
@export var shop_room_count: int = 1
@export var theme_color: Color = Color.WHITE
@export var normal_room_layouts: Array[Resource] = []
@export var boss_room_layouts: Array[Resource] = []
@export var treasure_room_layouts: Array[Resource] = []
@export var shop_room_layouts: Array[Resource] = []
@export var start_room_layouts: Array[Resource] = []
