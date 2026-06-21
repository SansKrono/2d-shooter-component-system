class_name C_Health
extends Component

const HP_PER_HEART: float = 10.0

@export var is_player: bool = false

# Roguelike granular health pools for player
@export var max_red: int = 6 # e.g. 3 full red heart containers
@export var current_red: int = 6
@export var soul_hearts: int = 0
@export var black_hearts: int = 0

@export var current: float:
	get:
		if is_player:
			return (current_red + soul_hearts + black_hearts) * HP_PER_HEART
		return _current_enemy
	set(value):
		if is_player:
			if value <= 0.0:
				current_red = 0
				soul_hearts = 0
				black_hearts = 0
				return

			var prev_hp = (current_red + soul_hearts + black_hearts) * HP_PER_HEART
			var diff = value - prev_hp

			if diff < 0.0:
				var damage_to_take = -diff
				var hearts_to_take = int(round(damage_to_take / HP_PER_HEART))
				if hearts_to_take > 0:
					# Deplete black hearts first
					var black_dmg = min(black_hearts, hearts_to_take)
					black_hearts -= black_dmg
					hearts_to_take -= black_dmg

					# Deplete soul hearts next
					if hearts_to_take > 0:
						var soul_dmg = min(soul_hearts, hearts_to_take)
						soul_hearts -= soul_dmg
						hearts_to_take -= soul_dmg

					# Deplete red hearts last
					if hearts_to_take > 0:
						var red_dmg = min(current_red, hearts_to_take)
						current_red -= red_dmg
						hearts_to_take -= red_dmg
			elif diff > 0.0:
				var heal_amount = diff
				var hearts_to_heal = int(round(heal_amount / HP_PER_HEART))
				if hearts_to_heal > 0:
					current_red = min(max_red, current_red + hearts_to_heal)
		else:
			_current_enemy = value

@export var maximum: float:
	get:
		if is_player:
			return (max_red + soul_hearts + black_hearts) * HP_PER_HEART
		return _maximum_enemy
	set(value):
		if is_player:
			var desired_max_hearts = int(round(value / HP_PER_HEART))
			max_red = max(0, desired_max_hearts - soul_hearts - black_hearts)
		else:
			_maximum_enemy = value

# Backing fields for enemy health
var _current_enemy: float = 100.0
var _maximum_enemy: float = 100.0

func _init(
	max_health: float = 100.0,
	red_containers: int = 6,
	soul: int = 0,
	black: int = 0,
	player_flag: bool = false
) -> void:
	is_player = player_flag
	if is_player:
		max_red = red_containers
		current_red = red_containers
		soul_hearts = soul
		black_hearts = black
	else:
		_maximum_enemy = max_health
		_current_enemy = max_health
