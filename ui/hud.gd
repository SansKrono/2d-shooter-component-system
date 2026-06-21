extends Control

# Member variables
var coins_label: Label
var hearts_container: HFlowContainer
var _red_heart_tex: Texture2D
var _blue_heart_tex: Texture2D
var _black_heart_tex: Texture2D

# Onready variables
@onready var hp_label: Label = $ResourceBox/VBox/HPLabel
@onready var hp_bar: ProgressBar = $ResourceBox/VBox/HPBar
@onready var mp_label: Label = $ResourceBox/VBox/MPLabel
@onready var mp_bar: ProgressBar = $ResourceBox/VBox/MPBar
@onready var timer_label: Label = $StatBox/TimerLabel
@onready var kills_label: Label = $StatBox/KillsLabel
@onready var relics_label: Label = $StatBox/RelicsLabel

func _ready() -> void:
	# Load textures dynamically
	_red_heart_tex = load("res://assets/red_heart.png")
	_blue_heart_tex = load("res://assets/blue_heart.png")
	_black_heart_tex = load("res://assets/black_heart.png")

	# Hide default health label and progress bar
	hp_label.visible = false
	hp_bar.visible = false

	# Create hearts container programmatically
	hearts_container = HFlowContainer.new()
	hearts_container.name = "HeartsContainer"
	hearts_container.custom_minimum_size = Vector2(200, 0)
	hearts_container.add_theme_constant_override("h_separation", 2)
	hearts_container.add_theme_constant_override("v_separation", 2)

	var resource_vbox = get_node_or_null("ResourceBox/VBox")
	if resource_vbox:
		resource_vbox.add_child(hearts_container)
		resource_vbox.move_child(hearts_container, 0)

	coins_label = Label.new()
	coins_label.name = "CoinsLabel"
	coins_label.text = "Coins: 0"

	if has_node("StatBox/KillsLabel"):
		var kills = get_node("StatBox/KillsLabel") as Label
		coins_label.add_theme_font_size_override("font_size", kills.get_theme_font_size("font_size"))
		coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		coins_label.add_theme_font_size_override("font_size", 19)
		coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	var stat_box = get_node_or_null("StatBox")
	if stat_box:
		stat_box.add_child(coins_label)
		stat_box.move_child(coins_label, 2)

func update_coins(amount: int) -> void:
	if coins_label:
		coins_label.text = "Coins: %d" % amount

func update_health(current: float, maximum: float) -> void:
	hp_label.text = "HP: %.1f / %.1f" % [current, maximum]
	hp_bar.max_value = maximum
	hp_bar.value = current

func update_health_hearts(current_red: int, max_red: int, soul: int, black: int) -> void:
	if not hearts_container or not _red_heart_tex:
		return

	for child in hearts_container.get_children():
		child.queue_free()

	var w = _red_heart_tex.get_width()
	var h = _red_heart_tex.get_height()

	# 1. Red hearts capacity
	var red_containers = int(ceil(max_red / 2.0))
	for i in range(red_containers):
		var container_health = clamp(current_red - i * 2, 0, 2)
		var container = Control.new()
		container.custom_minimum_size = Vector2(w, h)
		container.size = container.custom_minimum_size

		if container_health == 0:
			var rect = TextureRect.new()
			rect.texture = _red_heart_tex
			rect.custom_minimum_size = Vector2(w, h)
			rect.size = rect.custom_minimum_size
			rect.modulate = Color(0.2, 0.2, 0.2, 0.4)
			rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			container.add_child(rect)
		elif container_health == 1:
			# Background empty
			var bg_rect = TextureRect.new()
			bg_rect.texture = _red_heart_tex
			bg_rect.custom_minimum_size = Vector2(w, h)
			bg_rect.size = bg_rect.custom_minimum_size
			bg_rect.modulate = Color(0.2, 0.2, 0.2, 0.4)
			bg_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			container.add_child(bg_rect)

			# Foreground half
			var clipper = Control.new()
			clipper.custom_minimum_size = Vector2(w / 2.0, h)
			clipper.size = clipper.custom_minimum_size
			clipper.clip_contents = true
			container.add_child(clipper)

			var fg_rect = TextureRect.new()
			fg_rect.texture = _red_heart_tex
			fg_rect.custom_minimum_size = Vector2(w, h)
			fg_rect.size = fg_rect.custom_minimum_size
			fg_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			clipper.add_child(fg_rect)
		else:
			var rect = TextureRect.new()
			rect.texture = _red_heart_tex
			rect.custom_minimum_size = Vector2(w, h)
			rect.size = rect.custom_minimum_size
			rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			container.add_child(rect)

		hearts_container.add_child(container)

	# 2. Soul hearts
	var soul_full = int(soul / 2.0)
	var soul_half = soul % 2
	for i in range(soul_full):
		var rect = _create_heart_rect(_blue_heart_tex, false)
		hearts_container.add_child(rect)
	if soul_half > 0:
		var rect = _create_heart_rect(_blue_heart_tex, true)
		hearts_container.add_child(rect)

	# 3. Black hearts
	var black_full = int(black / 2.0)
	var black_half = black % 2
	for i in range(black_full):
		var rect = _create_heart_rect(_black_heart_tex, false)
		hearts_container.add_child(rect)
	if black_half > 0:
		var rect = _create_heart_rect(_black_heart_tex, true)
		hearts_container.add_child(rect)

func _create_heart_rect(tex: Texture2D, is_half: bool) -> Control:
	var w = tex.get_width()
	var h = tex.get_height()
	var container = Control.new()
	var width_val = float(w) if not is_half else w / 2.0
	container.custom_minimum_size = Vector2(width_val, h)
	container.size = container.custom_minimum_size

	if is_half:
		var clipper = Control.new()
		clipper.custom_minimum_size = Vector2(w / 2.0, h)
		clipper.size = clipper.custom_minimum_size
		clipper.clip_contents = true
		container.add_child(clipper)

		var rect = TextureRect.new()
		rect.texture = tex
		rect.custom_minimum_size = Vector2(w, h)
		rect.size = rect.custom_minimum_size
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		clipper.add_child(rect)
	else:
		var rect = TextureRect.new()
		rect.texture = tex
		rect.custom_minimum_size = Vector2(w, h)
		rect.size = rect.custom_minimum_size
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		container.add_child(rect)

	return container

func set_health_na() -> void:
	hp_label.text = "HP: N/A"
	hp_bar.value = 0.0
	if hearts_container:
		for child in hearts_container.get_children():
			child.queue_free()

func update_mana(current: float, maximum: float) -> void:
	mp_label.text = "Mana: %.1f / %.1f" % [current, maximum]
	mp_bar.max_value = maximum
	mp_bar.value = current

func set_mana_na() -> void:
	mp_label.text = "Mana: N/A"
	mp_bar.value = 0.0

func update_run_time(time_secs: float) -> void:
	var mins = int(time_secs / 60.0)
	var secs = int(time_secs) % 60
	timer_label.text = "Time: %02d:%02d" % [mins, secs]

func update_kills(kills: int) -> void:
	kills_label.text = "Kills: %d" % kills

func update_relics(relics: Array[String]) -> void:
	var relics_str = ", ".join(relics) if not relics.is_empty() else "None"
	relics_label.text = "Relics: %s" % relics_str
