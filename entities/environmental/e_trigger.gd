@tool
class_name TriggerArea
extends Entity

const C_TRIGGER_SCRIPT = preload("res://components/world/c_trigger.gd")

@export var channel: int = -1:
	set(val):
		channel = val
		_update_component()

@export var trigger_range: float = 60.0:
	set(val):
		trigger_range = val
		_update_component()

var _trigger: Resource

func define_components() -> Array:
	_trigger = C_TRIGGER_SCRIPT.new()
	_trigger.trigger_range = trigger_range
	_trigger.one_shot = true
	_trigger.channel = channel
	return [
		_trigger,
		C_InteractableDebug.new(Color(0.0, 0.5, 1.0, 0.3), 2.0)
	]

func on_ready() -> void:
	_update_component()

func _update_component() -> void:
	var c_trig = get_component(C_TRIGGER_SCRIPT) as C_TRIGGER_SCRIPT
	if c_trig:
		c_trig.channel = channel
		c_trig.trigger_range = trigger_range
	elif _trigger:
		_trigger.channel = channel
		_trigger.trigger_range = trigger_range
