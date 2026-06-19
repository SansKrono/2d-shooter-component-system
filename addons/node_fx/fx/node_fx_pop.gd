extends Object


static func pop(node, duration, snappy := false):
	
	if not node is Node3D and not node is Node2D and not node is Control:
		# ERROR - NODE NOT ANIMATABLE 
		push_error("NodeFX: I can't animate this node. Give me Node3D, Node2D or Control.")
		return
	
	if node is Control:
		node.pivot_offset = node.size * 0.5
	
	var pop_tween = node.create_tween()
	NodeFX.CURRENTLY_RUNNING_TWEENS.append(pop_tween)
	pop_tween.finished.connect(func(): NodeFX.erase_finished_tween(pop_tween))
	
	var s = node.scale
	var t = 0.272
	
	if snappy:
		t = 0.172
		
	pop_tween.tween_property(node, "scale", s * 0, 0)
	pop_tween.tween_property(node, "scale", s * 1.1, duration * t)
	pop_tween.tween_property(node, "scale", s * 0.95, duration * 0.144)
	pop_tween.tween_property(node, "scale", s * 1.05, duration * 0.128)
	pop_tween.tween_property(node, "scale", s * 0.98, duration * 0.128)
	pop_tween.tween_property(node, "scale", s * 1.01, duration * 0.112)
	pop_tween.tween_property(node, "scale", s * 1, duration * 0.08)
