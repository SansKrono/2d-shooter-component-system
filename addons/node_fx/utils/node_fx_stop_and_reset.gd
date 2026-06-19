extends Object


static func stop_and_reset(node: Node):
	kill_all_tweens()
	NodeFX.kill_hover(node)
	reset_position(node)
	reset_rotation(node)
	reset_scale(node)
	reset_color(node)
	

static func kill_all_tweens():
	if not NodeFX.CURRENTLY_RUNNING_TWEENS.is_empty():
		for tween in NodeFX.CURRENTLY_RUNNING_TWEENS.duplicate():
			if is_instance_valid(tween):
				tween.kill()
				
		NodeFX.CURRENTLY_RUNNING_TWEENS.clear()


static func reset_position(node: Node):
	if not NodeFX.ORIGINAL_POSITION == null:
		node.global_position = NodeFX.ORIGINAL_POSITION


static func reset_rotation(node: Node):
	if node is Node3D and not NodeFX.ORIGINAL_ROTATION == null:
		node.global_rotation_degrees = NodeFX.ORIGINAL_ROTATION


static func reset_scale(node: Node):
	if not NodeFX.ORIGINAL_SCALE == null:
		node.scale = NodeFX.ORIGINAL_SCALE


static func reset_color(node: Node):
	
	if node is Node3D and not node is Sprite3D: 
		if not NodeFX.ORIGINAL_MATERIALS.is_empty():
			var reset := true
			Tool3D.get_materials(node, reset)
		
	elif node is Node2D or node is Control or node is Sprite3D:
		if not NodeFX.ORIGINAL_MODULATE == null:
			node.modulate = NodeFX.ORIGINAL_MODULATE
