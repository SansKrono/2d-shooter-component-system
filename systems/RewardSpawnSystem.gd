class_name RewardSpawnSystem
extends System

const C_SPAWN_REWARD = preload("res://components/world/c_spawn_reward.gd")
const C_TRANSFORM = preload("res://components/movement/c_transform.gd")

const COIN_SCENE = preload("res://entities/collectibles/e_coin.tscn")
const SEEKING_RELIC_PICKUP_SCENE = preload("res://entities/collectibles/e_seeking_relic_pickup.tscn")

func query() -> QueryBuilder:
	return q.with_all([C_SPAWN_REWARD])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var reward = entity.get_component(C_SPAWN_REWARD)
		if not reward:
			continue
			
		var reward_type = reward.reward_type.to_lower()
		var spawn_pos = reward.spawn_position
		
		# Resolve spawn position if it defaults to Vector2.ZERO
		if spawn_pos == Vector2.ZERO:
			var trans = entity.get_component(C_TRANSFORM)
			if trans:
				spawn_pos = trans.position
				
		var scene: PackedScene = null
		match reward_type:
			"coin":
				scene = COIN_SCENE
			"relic", "seeking_relic":
				scene = SEEKING_RELIC_PICKUP_SCENE
			_:
				print("[RewardSpawnSystem] Warning: Unknown reward type: ", reward_type)
				
		if scene:
			var reward_entity = scene.instantiate() as Node2D
			reward_entity.position = spawn_pos
			# Add the entity to GECS via CommandBuffer; GECS handles scene tree insertion
			cmd.add_entity(reward_entity)
			print("[RewardSpawnSystem] Spawned reward '%s' at %s" % [reward_type, str(spawn_pos)])
			
		# Remove component so we only process it once
		cmd.remove_component(entity, C_SPAWN_REWARD)
