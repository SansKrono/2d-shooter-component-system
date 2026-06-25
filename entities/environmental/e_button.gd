@tool
class_name SpawnerButton
extends Entity

const C_INTERACTABLE_SCRIPT = preload("res://components/world/c_interactable.gd")

@export var channel: int = -1:
	set(val):
		channel = val
		_update_component()

@export var interaction_text: String = "[F] Interact":
	set(val):
		interaction_text = val
		_update_component()

var _interactable: Resource
var _player_in_range := false
var _player_ref: Node = null
var _prompt: Label = null

func define_components() -> Array:
	_interactable = C_INTERACTABLE_SCRIPT.new()
	_interactable.interaction_text = interaction_text
	_interactable.channel = channel
	return [_interactable]

func on_ready() -> void:
	_update_component()
	if Engine.is_editor_hint():
		return
	_prompt = Label.new()
	_prompt.name = "InteractionPrompt"
	_prompt.position = Vector2(-100, -50)
	_prompt.size = Vector2(200, 30)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var label_settings = LabelSettings.new()
	label_settings.font_size = 14
	label_settings.font_color = Color.GOLD
	label_settings.outline_color = Color.BLACK
	label_settings.outline_size = 4
	_prompt.label_settings = label_settings
	_prompt.visible = false
	add_child(_prompt)
	var area = get_node_or_null("Area2D") as Area2D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _update_component() -> void:
	var c_inter = get_component(C_INTERACTABLE_SCRIPT) as C_INTERACTABLE_SCRIPT
	if c_inter:
		c_inter.channel = channel
		c_inter.interaction_text = interaction_text
	elif _interactable:
		_interactable.channel = channel
		_interactable.interaction_text = interaction_text

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _player_in_range or not is_instance_valid(_player_ref):
		return
	var c_input = _player_ref.get_component(C_Input) as C_Input
	if c_input and c_input.interact_just_pressed:
		c_input.interact_just_pressed = false
		var c_inter = get_component(C_INTERACTABLE_SCRIPT) as C_INTERACTABLE_SCRIPT
		if c_inter:
			c_inter.triggered = true
			if c_inter.interaction_action.is_valid():
				c_inter.interaction_action.call()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player_in_range = true
		_player_ref = body
		if _prompt:
			var c_inter = get_component(C_INTERACTABLE_SCRIPT) as C_INTERACTABLE_SCRIPT
			_prompt.text = c_inter.interaction_text if c_inter else interaction_text
			_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body is Player:
		_player_in_range = false
		_player_ref = null
		if _prompt:
			_prompt.visible = false
