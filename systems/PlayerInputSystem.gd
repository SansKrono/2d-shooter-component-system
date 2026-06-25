class_name PlayerInputSystem
extends System

var _rmb_was_pressed: bool = false
var _q_was_pressed: bool = false
var _e_was_pressed: bool = false
var _last_aim_direction: Vector2 = Vector2.RIGHT


func query() -> QueryBuilder:
	return q.with_all([C_Input]).with_none([C_AIStateMachine])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return

	for entity in entities:
		if not entity is Player:
			continue
		var c_input = entity.get_component(C_Input) as C_Input
		if not c_input:
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

		# Interaction input (F key)
		var is_f_pressed = Input.is_key_pressed(KEY_F)
		c_input.interact_just_pressed = is_f_pressed and not c_input.interact_pressed
		c_input.interact_pressed = is_f_pressed

		# World-space mouse via viewport canvas transform (no C_Physics dependency)
		var viewport = entity.get_viewport()
		if viewport:
			var world_mouse: Vector2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
			var player_pos: Vector2 = entity.get("global_position") if "global_position" in entity else Vector2.ZERO
			var raw_aim = world_mouse - player_pos
			if raw_aim.length() > 1.0:
				_last_aim_direction = raw_aim.normalized()
		c_input.aim_direction = _last_aim_direction

		# LMB fire button — edge detection same as interact_just_pressed
		var lmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		c_input.fire_button_just_pressed = lmb and not c_input.fire_button_held
		c_input.fire_button_just_released = not lmb and c_input.fire_button_held
		c_input.fire_button_held = lmb

		# RMB magic button — edge detection
		var rmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		c_input.magic_button_just_pressed = rmb and not _rmb_was_pressed
		c_input.magic_button_just_released = not rmb and _rmb_was_pressed
		c_input.magic_button_held = rmb
		_rmb_was_pressed = rmb

		# Q key charged tech spells — edge detection
		var q_pressed = Input.is_key_pressed(KEY_Q)
		c_input.tech_charged_just_pressed = q_pressed and not _q_was_pressed
		c_input.tech_charged_just_released = not q_pressed and _q_was_pressed
		c_input.tech_charged_held = q_pressed
		_q_was_pressed = q_pressed

		# E key charged magic spells — edge detection
		var e_pressed = Input.is_key_pressed(KEY_E)
		c_input.magic_charged_just_pressed = e_pressed and not _e_was_pressed
		c_input.magic_charged_just_released = not e_pressed and _e_was_pressed
		c_input.magic_charged_held = e_pressed
		_e_was_pressed = e_pressed
