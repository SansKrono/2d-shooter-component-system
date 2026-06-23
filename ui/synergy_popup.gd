extends Control

@onready var label = Label.new()
@onready var timer = Timer.new()

var duration: float = 3.0

func _ready() -> void:
	add_child(label)
	label.anchor_left = 0.5
	label.anchor_top = 0.2
	label.offset_left = -150
	label.offset_top = 0
	label.size = Vector2(300, 100)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(300, 100)

	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)

func show_synergy(synergy: ItemSynergy) -> void:
	label.text = "✨ %s ✨\n%s" % [synergy.name, synergy.description]
	label.add_theme_color_override("font_color", Color(0.7, 0.4, 1, 1))
	label.add_theme_font_size_override("font_size", 22)

	modulate.a = 1.0
	timer.start(duration)

func _on_timer_timeout() -> void:
	timer.stop()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()
