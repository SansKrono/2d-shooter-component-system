@tool
class_name SpawnerButton
extends Entity

const C_INTERACTABLE_SCRIPT = preload("res://components/character/c_interactable.gd")

@export var channel: int = -1:
	set(val):
		channel = val
		_update_component()

@export var interaction_range: float = 80.0:
	set(val):
		interaction_range = val
		_update_component()

@export var interaction_text: String = "[E] Interact":
	set(val):
		interaction_text = val
		_update_component()

var _interactable: Resource

func define_components() -> Array:
	_interactable = C_INTERACTABLE_SCRIPT.new()
	_interactable.interaction_range = interaction_range
	_interactable.interaction_text = interaction_text
	_interactable.channel = channel
	return [
		_interactable,
		C_InteractableDebug.new(Color(0, 1, 0, 0.3), 2.0)
	]

func on_ready() -> void:
	_update_component()

func _update_component() -> void:
	var c_inter = get_component(C_INTERACTABLE_SCRIPT) as C_INTERACTABLE_SCRIPT
	if c_inter:
		c_inter.channel = channel
		c_inter.interaction_range = interaction_range
		c_inter.interaction_text = interaction_text
	elif _interactable:
		_interactable.channel = channel
		_interactable.interaction_range = interaction_range
		_interactable.interaction_text = interaction_text
