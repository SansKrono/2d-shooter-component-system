@tool
class_name TriggerArea
extends Entity

const C_TRIGGER_SCRIPT = preload("res://components/world/c_trigger.gd")

@export var channel: int = -1:
	set(val):
		channel = val
		_update_component()

@export var one_shot: bool = true:
	set(val):
		one_shot = val
		_update_component()

var _trigger: Resource

func define_components() -> Array:
	_trigger = C_TRIGGER_SCRIPT.new()
	_trigger.one_shot = one_shot
	_trigger.channel = channel
	return [_trigger]

func on_ready() -> void:
	_update_component()
	if Engine.is_editor_hint():
		return
	var area = get_node_or_null("Area2D") as Area2D
	if area:
		area.body_entered.connect(_on_body_entered)

func _update_component() -> void:
	var c_trig = get_component(C_TRIGGER_SCRIPT) as C_TRIGGER_SCRIPT
	if c_trig:
		c_trig.channel = channel
		c_trig.one_shot = one_shot
	elif _trigger:
		_trigger.channel = channel
		_trigger.one_shot = one_shot

func _on_body_entered(body: Node) -> void:
	if not (body is Player):
		return
	var c_trig = get_component(C_TRIGGER_SCRIPT) as C_TRIGGER_SCRIPT
	if not c_trig or c_trig.triggered:
		return
	c_trig.triggered = true
	if c_trig.trigger_action.is_valid():
		c_trig.trigger_action.call()
	if c_trig.one_shot:
		await get_tree().process_frame
		if ECS.world:
			ECS.world.remove_entity(self)
		queue_free()
