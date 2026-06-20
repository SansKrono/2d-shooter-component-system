@tool
class_name RelicPickup
extends Entity

@export var relic_resource: Relic:
	set(val):
		relic_resource = val
		_update_interaction_text()

var _interactable: C_Interactable

func define_components() -> Array:
	_interactable = C_Interactable.new(80.0, Callable(), "")
	_update_interaction_text()
	return [
		_interactable,
		C_InteractableDebug.new(Color(1.0, 0.84, 0.0, 0.3), 2.0)
	]

func on_ready() -> void:
	var c_inter = get_component(C_Interactable) as C_Interactable
	if c_inter:
		c_inter.interaction_action = Callable(self, "_on_interacted")
	NodeFX.hover(self)
	_update_interaction_text()

func _update_interaction_text() -> void:
	var c_inter = get_component(C_Interactable) as C_Interactable
	if c_inter:
		var r_name = relic_resource.name if relic_resource else "Relic"
		c_inter.interaction_text = "[E] Pick up " + r_name
	elif _interactable:
		var r_name = relic_resource.name if relic_resource else "Relic"
		_interactable.interaction_text = "[E] Pick up " + r_name

func _on_interacted() -> void:
	if not relic_resource:
		return
	
	if ECS.world:
		var query = QueryBuilder.new(ECS.world)
		var players = query.with_all([C_RelicInventory]).execute()
		if not players.is_empty():
			var player = players[0]
			var c_inv = player.get_component(C_RelicInventory) as C_RelicInventory
			if c_inv:
				c_inv.add_relic(player, relic_resource)
				NodeFX.fade(self, 1.0, false, true)
				print("[Pickup] Picked up relic: %s" % relic_resource.name)
				await get_tree().create_timer(1.0).timeout
				ECS.world.remove_entity(self)
