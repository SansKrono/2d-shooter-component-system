extends PanelContainer

@onready var synergy_list = VBoxContainer.new()

var tracked_entity: Entity = null

func _ready() -> void:
	add_child(synergy_list)
	synergy_list.custom_minimum_size = Vector2(300, 200)

	visible = false

	var synergy_mgr = get_tree().root.get_node_or_null("SynergyManager")
	if synergy_mgr:
		synergy_mgr.synergy_activated.connect(_on_synergy_activated)
		synergy_mgr.synergy_deactivated.connect(_on_synergy_deactivated)

func set_tracked_entity(entity: Entity) -> void:
	tracked_entity = entity

func _on_synergy_activated(synergy: ItemSynergy) -> void:
	_add_synergy_label(synergy)
	visible = true

func _on_synergy_deactivated(synergy: ItemSynergy) -> void:
	_remove_synergy_label(synergy)
	if synergy_list.get_child_count() == 0:
		visible = false

func _add_synergy_label(synergy: ItemSynergy) -> void:
	var label = Label.new()
	label.text = "► %s" % synergy.name
	label.add_theme_color_override("font_color", Color(0.7, 0.4, 1, 1))
	label.add_theme_font_size_override("font_size", 14)
	synergy_list.add_child(label)

func _remove_synergy_label(synergy: ItemSynergy) -> void:
	for child in synergy_list.get_children():
		if child.text.contains(synergy.name):
			child.queue_free()
