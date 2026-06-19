extends Object


static func flip(node, duration := 1.0, axis := "x", reversed := false, snappy := false, variation := false):
	
	var flip_tween = node.create_tween()
	NodeFX.CURRENTLY_RUNNING_TWEENS.append(flip_tween)
	flip_tween.finished.connect(func(): NodeFX.erase_finished_tween(flip_tween))
	
	var t = 1
	if snappy: 
		t = 0.7
	
	if node is Node3D:
		
		var m = 1
		var r = node.rotation_degrees.x
		var mesh_material 
		
		if axis == "y":
			r = node.rotation_degrees.y
		elif axis == "z":
			r = node.rotation_degrees.z
		
		if reversed:
			m = -1
		
		if variation:
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 90 * m, duration * 0.35 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 190 * m, duration * 0.1 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 150 * m, duration * 0.1 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 185 * m, duration * 0.09 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 165 * m, duration * 0.09 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 181 * m, duration * 0.07 )
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 175 * m, duration * 0.05 )
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 180 * m, duration * 0.05 )
			
		else:
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 185 * m, duration * 0.5 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 165 * m, duration * 0.1 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 183 * m, duration * 0.2 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 177 * m, duration * 0.1 * t)
			flip_tween.tween_property(node, "rotation_degrees:"+axis, r + 180 * m, duration * 0.1 * t)
		
		
	elif node is Node2D or node is Control:
		
		if node is Control:
			node.pivot_offset = node.size * 0.5
		
		var s = node.scale.x
		if axis == "y":
			s = node.scale.y
		if axis == "z":
			axis = "x"
		
		if variation:
			flip_tween.tween_property(node, "scale:"+axis, s * 0, duration * 0.15)
			flip_tween.tween_property(node, "scale:"+axis, s * 0.5, duration * 0.2 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 1.045, duration * 0.1 * t)
			flip_tween.tween_property(node, "scale:"+axis,s * 0.825, duration * 0.1 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 1.02, duration * 0.09 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 0.9, duration * 0.09 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 1.01, duration * 0.07 )
			flip_tween.tween_property(node, "scale:"+axis, s * 0.96, duration * 0.05 )
			flip_tween.tween_property(node, "scale:"+axis, s * 1, duration * 0.05 )
			
		else:
			flip_tween.tween_property(node, "scale:"+axis, s * 0, duration * 0.25 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 1.02, duration * 0.25 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 0.91, duration * 0.1 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 1.01, duration * 0.2 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 0.99, duration * 0.1 * t)
			flip_tween.tween_property(node, "scale:"+axis, s * 1, duration * 0.1 * t)
		
	else:
		# ERROR - NODE NOT ANIMATABLE 
		push_error("NodeFX: I can't animate this node. Give me Node3D, Node2D or Control.")
		return
