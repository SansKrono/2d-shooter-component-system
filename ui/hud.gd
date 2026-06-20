extends Control

@onready var hp_label: Label = $StatsPanel/VBox/HPLabel
@onready var hp_bar: ProgressBar = $StatsPanel/VBox/HPBar
@onready var mp_label: Label = $StatsPanel/VBox/MPLabel
@onready var mp_bar: ProgressBar = $StatsPanel/VBox/MPBar
@onready var timer_label: Label = $StatsPanel/VBox/TimerLabel
@onready var kills_label: Label = $StatsPanel/VBox/KillsLabel
@onready var relics_label: Label = $StatsPanel/VBox/RelicsLabel

func update_health(current: float, maximum: float) -> void:
	hp_label.text = "HP: %.1f / %.1f" % [current, maximum]
	hp_bar.max_value = maximum
	hp_bar.value = current

func set_health_na() -> void:
	hp_label.text = "HP: N/A"
	hp_bar.value = 0.0

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
