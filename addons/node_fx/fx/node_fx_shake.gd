extends Object


static func shake(node, duration, snappy, variation):
	
	if not node is Node3D and not node is Node2D and not node is Control:
		# ERROR - NODE NOT ANIMATABLE 
		push_error("NodeFX: I can't animate this node. Give me Node3D, Node2D or Control.")
		return
	
	if node is Control:
		node.pivot_offset = node.size * 0.5
	
	var shake_tween = node.create_tween()
	NodeFX.CURRENTLY_RUNNING_TWEENS.append(shake_tween)
	shake_tween.finished.connect(func(): NodeFX.erase_finished_tween(shake_tween))
	
	var p = node.global_position
	
	var t := 0.02 # how fast the shake
	var r := 0.03 # how big the shake
	var frames : int = duration/t
	var offset 
	
	if snappy:
		t = 0.01
	if variation:
		r = 0.07
	if not node is Node3D: 
		r *= 300
	
	for f in range(frames):
		if node is Node3D:
			offset = Vector3(randf_range(-r, r),randf_range(-r, r),randf_range(-r, r))
		elif node is Node2D or node is Control:
			offset = Vector2(randf_range(-r, r),randf_range(-r, r))
		
		shake_tween.tween_property(node, "position", p + offset, t)
	shake_tween.tween_property(node, "position", p , 0.1)
