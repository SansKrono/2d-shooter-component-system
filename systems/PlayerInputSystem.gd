class_name PlayerInputSystem
extends System

var _rmb_was_pressed: bool = false
var _last_aim_direction: Vector2 = Vector2.RIGHT

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

		# Mouse aim direction using PhysicsBody for get_global_mouse_position
		var c_phys = entity.get_component(C_Physics)
		if c_phys and is_instance_valid(c_phys.body):
			var raw_aim = c_phys.body.get_global_mouse_position() - c_phys.body.global_position
			if raw_aim.length() > 1.0:
				_last_aim_direction = raw_aim.normalized()
		c_input.aim_direction = _last_aim_direction

		# LMB fire button — edge detection same as interact_just_pressed
		var lmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		c_input.fire_button_just_pressed = lmb and not c_input.fire_button_held
		c_input.fire_button_just_released = not lmb and c_input.fire_button_held
		c_input.fire_button_held = lmb

		# RMB mode toggle — edge detection
		var rmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		c_input.mode_toggle_just_pressed = rmb and not _rmb_was_pressed
		_rmb_was_pressed = rmb
