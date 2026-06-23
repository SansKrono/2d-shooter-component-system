@tool
class_name Coin
extends Entity

const C_COLLECTIBLE_SCRIPT = preload("res://components/economy/c_collectible.gd")
const C_INTERACTABLE_DEBUG_SCRIPT = preload("res://components/debug/c_interactable_debug.gd")
const C_CURRENCY_SCRIPT = preload("res://components/economy/c_currency.gd")

@export var value: int = 5

var _collectible: Resource

func define_components() -> Array:
	_collectible = C_COLLECTIBLE_SCRIPT.new(30.0, 150.0, 400.0, Callable())
	return [
		_collectible,
		C_INTERACTABLE_DEBUG_SCRIPT.new(Color(1.0, 0.84, 0.0, 0.3), 2.0)
	]

func on_ready() -> void:
	if Engine.is_editor_hint():
		return
		
	var c_coll = get_component(C_COLLECTIBLE_SCRIPT) as C_COLLECTIBLE_SCRIPT
	if c_coll:
		c_coll.on_collected = Callable(self, "_on_collected")
	
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		NodeFX.hover(sprite)

func _on_collected(player: Entity) -> void:
	var c_curr = player.get_component(C_CURRENCY_SCRIPT) as C_CURRENCY_SCRIPT
	if c_curr:
		c_curr.amount += value
		print("[Coin] Added %d coins to player. Total: %d" % [value, c_curr.amount])
	
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		NodeFX.kill_hover(sprite)
	
	var node2d := (self as Node) as Node2D
	if node2d:
		var tween := node2d.create_tween()
		tween.set_parallel(true)
		
		var target_y := node2d.position.y - 60.0
		tween.tween_property(node2d, "position:y", target_y, 0.6)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		
		tween.tween_property(node2d, "scale", Vector2.ZERO, 0.6)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
		
		tween.tween_property(node2d, "modulate:a", 0.0, 0.6)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(0.6).timeout
	if ECS.world:
		ECS.world.remove_entity(self)
