extends Node2D

enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

const GAMEPLAY_SCENE = preload("res://gui_test_scene.tscn")
const C_TRIGGER_SCRIPT = preload("res://components/character/c_trigger.gd")
const C_SPAWNER_SCRIPT = preload("res://components/character/c_spawner.gd")

@export var initial_state: GameState = GameState.MAIN_MENU

var current_state: GameState = GameState.MAIN_MENU
var run_time: float = 0.0
var enemies_killed: int = 0
var relics_collected: Array[String] = []
var active_level: Node2D = null
var player: Player = null

@onready var world_container: Node2D = $WorldContainer
@onready var canvas_layer: CanvasLayer = $CanvasLayer

# UI Screen References
@onready var main_menu_ui: Control = $CanvasLayer/MainMenuUI
@onready var hud_ui: Control = $CanvasLayer/HUDUI
@onready var pause_menu_ui: Control = $CanvasLayer/PauseMenuUI
@onready var game_over_ui: Control = $CanvasLayer/GameOverUI
@onready var victory_ui: Control = $CanvasLayer/VictoryUI

# HUD Node References
@onready var hp_label: Label = $CanvasLayer/HUDUI/StatsPanel/VBox/HPLabel
@onready var mp_label: Label = $CanvasLayer/HUDUI/StatsPanel/VBox/MPLabel
@onready var timer_label: Label = $CanvasLayer/HUDUI/StatsPanel/VBox/TimerLabel
@onready var kills_label: Label = $CanvasLayer/HUDUI/StatsPanel/VBox/KillsLabel
@onready var relics_label: Label = $CanvasLayer/HUDUI/StatsPanel/VBox/RelicsLabel

# Game Over / Victory Display stats
@onready var go_stats_label: Label = $CanvasLayer/GameOverUI/Panel/VBoxContainer/StatsText
@onready var vic_stats_label: Label = $CanvasLayer/VictoryUI/Panel/VBoxContainer/StatsText

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS # Let Manager process inputs even during scene pause
	change_state(initial_state)

	# Auto-start run when running headlessly for verification
	if DisplayServer.get_name() == "headless":
		print("[GameManager] Headless mode detected. Auto-starting run for verification...")
		call_deferred("start_run")

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		run_time += delta
		_update_hud()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		if current_state == GameState.PLAYING:
			change_state(GameState.PAUSED)
		elif current_state == GameState.PAUSED:
			change_state(GameState.PLAYING)

func change_state(new_state: GameState) -> void:
	current_state = new_state

	# Toggle control visibilities
	main_menu_ui.visible = (new_state == GameState.MAIN_MENU)
	hud_ui.visible = (new_state == GameState.PLAYING or new_state == GameState.PAUSED)
	pause_menu_ui.visible = (new_state == GameState.PAUSED)
	game_over_ui.visible = (new_state == GameState.GAME_OVER)
	victory_ui.visible = (new_state == GameState.VICTORY)

	# Scene tree pause management
	get_tree().paused = (new_state == GameState.PAUSED)

	if new_state == GameState.GAME_OVER:
		_populate_end_stats(go_stats_label)
	elif new_state == GameState.VICTORY:
		_populate_end_stats(vic_stats_label)

func start_run() -> void:
	unload_level()

	run_time = 0.0
	enemies_killed = 0
	relics_collected.clear()

	# Instantiate gameplay level
	active_level = GAMEPLAY_SCENE.instantiate() as Node2D
	world_container.add_child(active_level)

	var world_node = active_level.get_node_or_null("World") as World
	if world_node:
		ECS.world = world_node
		if not world_node.entity_removed.is_connected(_on_entity_removed):
			world_node.entity_removed.connect(_on_entity_removed)

		# Defer player search until entity ready completes
		call_deferred("_setup_player_connections", world_node)

	change_state(GameState.PLAYING)
	print("[GameManager] Starting new run.")

func unload_level() -> void:
	if active_level:
		if ECS.world:
			# Purge the world
			ECS.world.purge(false)
			ECS.world = null
		active_level.queue_free()
		active_level = null
		player = null

func trigger_game_over() -> void:
	if current_state == GameState.PLAYING:
		print("[GameManager] Player has died. Game Over!")
		change_state(GameState.GAME_OVER)

func trigger_victory() -> void:
	if current_state == GameState.PLAYING:
		print("[GameManager] Victory achieved! Clear run completed.")
		change_state(GameState.VICTORY)

func _setup_player_connections(world_node: World) -> void:
	var players = world_node.query.with_all([C_Input]).execute()
	if not players.is_empty():
		player = players[0] as Player

		# Attach inventory signals
		var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
		if c_inv:
			if not c_inv.relic_added.is_connected(_on_player_relic_added):
				c_inv.relic_added.connect(_on_player_relic_added)

			# Cache existing relics
			for relic in c_inv.relics:
				if relic and not relics_collected.has(relic.name):
					relics_collected.append(relic.name)

func _on_player_relic_added(relic: Relic) -> void:
	if relic and not relics_collected.has(relic.name):
		relics_collected.append(relic.name)
		print("[GameManager] Stat modifier/relic collected: ", relic.name)

func _on_entity_removed(entity: Entity) -> void:
	if entity == player:
		# Defer death transition to avoid modification in process loop
		call_deferred("trigger_game_over")
	elif entity.is_in_group("enemies"):
		enemies_killed += 1
		print("[GameManager] Enemy defeated. Kills: ", enemies_killed)
		call_deferred("check_victory_condition")

func check_victory_condition() -> void:
	if current_state != GameState.PLAYING:
		return

	# Query living enemies
	var living_enemies = get_tree().get_nodes_in_group("enemies")
	var active_count = 0
	for enemy in living_enemies:
		if is_instance_valid(enemy):
			var health = enemy.get_component(C_Health) as C_Health
			if health and health.current > 0.0:
				active_count += 1

	if active_count > 0:
		return # Active threats still present

	# Query GECS spawners for pending enemy spawns
	if ECS.world:
		var spawners = ECS.world.query.with_all([C_SPAWNER_SCRIPT]).execute()
		var pending = false
		for spawner in spawners:
			var c_spawn = spawner.get_component(C_SPAWNER_SCRIPT) as C_SPAWNER_SCRIPT
			if c_spawn:
				if c_spawn.max_spawn_count < 0 or c_spawn.current_spawn_count < c_spawn.max_spawn_count:
					pending = true
					break

		# If no pending spawns and no living enemies, player achieves victory
		if not pending:
			trigger_victory()

func _update_hud() -> void:
	if not is_instance_valid(player):
		return

	var health = player.get_component(C_Health) as C_Health
	var mana = player.get_component(C_Mana) as C_Mana

	if health:
		hp_label.text = "HP: %.1f / %.1f" % [health.current, health.maximum]
	else:
		hp_label.text = "HP: N/A"

	if mana:
		mp_label.text = "Mana: %.1f" % mana.current
	else:
		mp_label.text = "Mana: N/A"

	# Timer format MM:SS
	var mins = int(run_time / 60.0)
	var secs = int(run_time) % 60
	timer_label.text = "Time: %02d:%02d" % [mins, secs]
	kills_label.text = "Kills: %d" % enemies_killed
	var r_list = relics_collected
	var r_str = ", ".join(r_list) if not r_list.is_empty() else "None"
	relics_label.text = "Relics: %s" % r_str

func _populate_end_stats(label: Label) -> void:
	if not label:
		return
	var mins = int(run_time / 60.0)
	var secs = int(run_time) % 60
	var time_str = "%02d:%02d" % [mins, secs]
	var r_list = relics_collected
	var relics_str = ", ".join(r_list) if not r_list.is_empty() else "None"

	label.text = "Time Survived: %s\nEnemies Defeated: %d\nRelics Collected: %s" % [
		time_str, enemies_killed, relics_str
	]

# UI Button Callbacks
func _on_start_pressed() -> void:
	start_run()

func _on_resume_pressed() -> void:
	change_state(GameState.PLAYING)

func _on_restart_pressed() -> void:
	start_run()

func _on_menu_pressed() -> void:
	unload_level()
	change_state(GameState.MAIN_MENU)

func _on_quit_pressed() -> void:
	get_tree().quit()
