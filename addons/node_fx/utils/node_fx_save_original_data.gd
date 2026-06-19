extends Object


static func save_original_data(node: Node):
	
	if node is Node2D or node is Control or node is Sprite3D:
		NodeFX.ORIGINAL_MODULATE = node.modulate
		NodeFX.ORIGINAL_POSITION = node.global_position
		NodeFX.ORIGINAL_SCALE = node.scale
		
	elif node is Node3D or node is Sprite3D:
		NodeFX.ORIGINAL_POSITION = node.global_position
		NodeFX.ORIGINAL_ROTATION = node.global_rotation_degrees
		NodeFX.ORIGINAL_SCALE = node.scale

	else:
		# ERROR - NODE NOT ANIMATABLE 
		push_error("NodeFX: I can't animate this node. Give me Node3D, Node2D or Control.")
		return
