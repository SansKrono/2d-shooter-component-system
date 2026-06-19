extends Object

static var original_color: Color
static var target_color1
static var target_color2


# --- COLOR CHANGE ---
static func change_color(node: Node, duration := 1.0, color1 := "", color2 := ""):
	
	if color1 == "" and color2 == "":
		return
	
	if not color1 == "": target_color1 = Color.html(color1)
	if not color2 == "": target_color2 = Color.html(color2)
	
	var change_color_tween = node.create_tween()
	NodeFX.CURRENTLY_RUNNING_TWEENS.append(change_color_tween)
	change_color_tween.finished.connect(func(): NodeFX.erase_finished_tween(change_color_tween))
	
	
	if node is Node3D and not node is Sprite3D:
		var materials = Tool3D.get_materials(node)
		change_color_tween.set_parallel(true)
		
		for material in materials:
			original_color = material.albedo_color 
			
			if color1 == "": target_color1 = original_color
			if color2 == "" : target_color2 = original_color
			
			material.albedo_color = target_color1 
			change_color_tween.tween_property(material, "albedo_color", target_color2, duration)
		
		
	elif node is Node2D or node is Control or node is Sprite3D:
		NodeFX.ORIGINAL_MODULATE = node.modulate
		
		if color1 == "": target_color1 = NodeFX.ORIGINAL_MODULATE
		if color2 == "": target_color2 = NodeFX.ORIGINAL_MODULATE
		
		node.modulate = target_color1
		change_color_tween.tween_property(node, "modulate", target_color2, duration)
		
	else:
		# ERROR - NODE NOT ANIMATABLE 
		push_error("I can't animate this node. Give me Node3D, Node2D or Control.")
		return



# --- COLOR FLASH ---
static func color_flash(node: Node, duration := 1.0, color1 := "", color2 := ""):
	
	if color1 == "" and color2 == "":
		return
	
	if not color1 == "": target_color1 = Color.html(color1)
	if not color2 == "": target_color2 = Color.html(color2)
	var loops : int = roundi(duration / 0.1)
	
	var color_flash_tween = node.create_tween()
	NodeFX.CURRENTLY_RUNNING_TWEENS.append(color_flash_tween)
	color_flash_tween.finished.connect(func(): NodeFX.erase_finished_tween(color_flash_tween))
	color_flash_tween.set_loops(loops)
	
	
	if node is Node3D and not node is Sprite3D:
		var materials = Tool3D.get_materials(node)
		
		if not color1 == "":
			color_flash_tween.set_parallel(true)
			
			for material in materials:
				NodeFX.ORIGINAL_COLORS[material] = material.albedo_color
				color_flash_tween.tween_property(material, "albedo_color", target_color1, 0.01)
			
			color_flash_tween.set_parallel(false)
			color_flash_tween.tween_interval(0.01)
			color_flash_tween.set_parallel(true)
			
			for material in materials:
				color_flash_tween.tween_property(material, "albedo_color", NodeFX.ORIGINAL_COLORS[material], 0.09)
			
			color_flash_tween.set_parallel(false)
			color_flash_tween.tween_interval(0.01)
			
		if not color2 == "":
			color_flash_tween.set_parallel(true)
			
			for material in materials:
				NodeFX.ORIGINAL_COLORS[material] = material.albedo_color
				color_flash_tween.tween_property(material, "albedo_color", target_color2, 0.01)
			
			color_flash_tween.set_parallel(false)
			color_flash_tween.tween_interval(0.01)
			color_flash_tween.set_parallel(true)
			
			for material in materials:
				color_flash_tween.tween_property(material, "albedo_color", NodeFX.ORIGINAL_COLORS[material], 0.09)
			
			color_flash_tween.set_parallel(false)
			color_flash_tween.tween_interval(0.01)
		
		
	elif node is Node2D or node is Control or node is Sprite3D:
		
		if not color1 == "":
			color_flash_tween.tween_property(node, "modulate", target_color1, 0.01)
			color_flash_tween.tween_property(node, "modulate", NodeFX.ORIGINAL_MODULATE, 0.09)
		
		if not color2 == "":
			color_flash_tween.tween_property(node, "modulate", target_color2, 0.01)
			color_flash_tween.tween_property(node, "modulate", NodeFX.ORIGINAL_MODULATE, 0.09)
	
	else:
		# ERROR - NODE NOT ANIMATABLE 
		push_error("NodeFX: I can't animate this node. Give me Node3D, Node2D or Control.")
		return
