extends Object


static func fade(node: Node, duration := 1.0, fade_in := false, fade_out := false):
	if not fade_in and not fade_out:
		return

	var fade_tween = node.create_tween()
	NodeFX.CURRENTLY_RUNNING_TWEENS.append(fade_tween)
	fade_tween.finished.connect(func(): NodeFX.erase_finished_tween(fade_tween))
	
	
	if node is Node2D or node is Control or node is Sprite3D:
		
		if fade_in:
			fade_tween.tween_property(node,"modulate:a", 0, 0)
			fade_tween.tween_property(node,"modulate:a", 1, duration)
		if fade_out:
			fade_tween.tween_property(node,"modulate:a", 1, 0)
			fade_tween.tween_property(node,"modulate:a", 0, duration)
		
		
	elif node is Node3D and not node is Sprite3D:
		
		var materials = Tool3D.get_materials(node)
		fade_tween.set_parallel(true)
		
		if fade_in:
			for material in materials:
				if material and material is BaseMaterial3D:
					var original_alpha = material.albedo_color.a
					material.albedo_color.a = 0
					fade_tween.tween_property(material, "albedo_color:a", original_alpha, duration)
			
		if fade_out:
			
			var delay := 0
			if fade_in:
				delay = duration
			
			for material in materials:
				if material and material is BaseMaterial3D:
					if materials.size() > 1:
						material.cull_mode = BaseMaterial3D.CULL_DISABLED
						material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					fade_tween.tween_property(material, "albedo_color:a", 0, duration).set_delay(delay)
		
	else:
		# ERROR - NODE NOT ANIMATABLE 
		push_error("NodeFX: I can't animate this node. Give me Node3D, Node2D or Control.")
		return
