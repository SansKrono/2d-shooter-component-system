class_name PlayerInputSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Input, C_Velocity])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return

	for entity in entities:
		if not entity is Player:
			continue
		var c_input = entity.get_component(C_Input) as C_Input
		var c_vel = entity.get_component(C_Velocity) as C_Velocity
		if not c_input or not c_vel:
			continue

		# 8-way movement input (WASD)
		var move_dir = Vector2.ZERO
		if Input.is_key_pressed(KEY_W):
			move_dir.y -= 1
		if Input.is_key_pressed(KEY_S):
			move_dir.y += 1
		if Input.is_key_pressed(KEY_A):
			move_dir.x -= 1
		if Input.is_key_pressed(KEY_D):
			move_dir.x += 1
		
		c_input.movement_vector = move_dir.normalized()
		c_vel.direction = c_input.movement_vector

		# 8-way shooting input (Arrow Keys)
		var shoot_dir = Vector2.ZERO
		if Input.is_key_pressed(KEY_UP):
			shoot_dir.y -= 1
		if Input.is_key_pressed(KEY_DOWN):
			shoot_dir.y += 1
		if Input.is_key_pressed(KEY_LEFT):
			shoot_dir.x -= 1
		if Input.is_key_pressed(KEY_RIGHT):
			shoot_dir.x += 1
		
		c_input.shoot_vector = shoot_dir.normalized()

		# Interaction input (E key)
		var is_e_pressed = Input.is_key_pressed(KEY_E)
		c_input.interact_just_pressed = is_e_pressed and not c_input.interact_pressed
		c_input.interact_pressed = is_e_pressed
