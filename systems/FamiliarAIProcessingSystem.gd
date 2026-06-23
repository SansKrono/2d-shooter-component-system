class_name FamiliarAIProcessingSystem
extends System

const C_FAMILIAR_OF = preload("res://components/behaviour/c_familiar_of.gd")
const C_TRANSFORM = preload("res://components/movement/c_transform.gd")

func query() -> QueryBuilder:
	var dummy_familiar = C_FAMILIAR_OF.new()
	return q.with_relationship([Relationship.new(dummy_familiar, null)])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var dummy_familiar = C_FAMILIAR_OF.new()
		var relationship = entity.get_relationship(Relationship.new(dummy_familiar, ECS.wildcard))
		if relationship and relationship.target:
			var player = relationship.target as Entity
			var player_trans = player.get_component(C_TRANSFORM)
			var familiar_trans = entity.get_component(C_TRANSFORM)
			
			if player_trans and familiar_trans:
				var offset = Vector2(-30.0, 0.0)
				if relationship.relation:
					offset = relationship.relation.follow_offset
				var target_pos = player_trans.position + offset
				familiar_trans.position = familiar_trans.position.lerp(target_pos, 5.0 * delta)
				if "global_position" in entity:
					entity.global_position = familiar_trans.position
