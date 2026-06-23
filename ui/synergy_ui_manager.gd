extends CanvasLayer

@onready var synergy_panel = synergy_panel_node if has_node("SynergyPanel") else null
@onready var popup_container = PopupContainer.new()

var synergy_popup_scene = preload("res://ui/synergy_popup.gd")
var first_synergy_per_type: Dictionary = {}

func _ready() -> void:
	add_child(popup_container)
	popup_container.name = "PopupContainer"

	var synergy_mgr = get_tree().root.get_node_or_null("SynergyManager")
	if synergy_mgr:
		synergy_mgr.synergy_activated.connect(_on_synergy_activated)

func _on_synergy_activated(synergy: ItemSynergy) -> void:
	var key = synergy.name
	if key not in first_synergy_per_type:
		first_synergy_per_type[key] = true
		_show_popup(synergy)

func _show_popup(synergy: ItemSynergy) -> void:
	var popup = synergy_popup_scene.new() as Control
	popup_container.add_child(popup)
	popup.show_synergy(synergy)

	print("Synergy activated: ", synergy.name, " — ", synergy.description)
