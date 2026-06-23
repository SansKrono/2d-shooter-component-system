class_name C_Volatility
extends Component

@export var crit_chance: float = 0.05 # 5% base chance to crit
@export var crit_multiplier: float = 1.5 # Crit damage modifier
@export var mutation_chance: float = 0.0 # Chance for a bullet to trigger a wild status effect
@export var is_critical: bool = false # Runtime check per bullet

func _init(crit_c: float = 0.05, crit_m: float = 1.5, mut_c: float = 0.0):
	crit_chance = crit_c
	crit_multiplier = crit_m
	mutation_chance = mut_c
	is_critical = false
