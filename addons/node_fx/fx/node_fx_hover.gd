extends Object

# Store active hover tweens so they don't overwrite each other and can be stopped individually
static var hover_tweens: Dictionary = {}

static func hover(node: Node, duration := 2.0, height := 10.0, loops := 0):
	if not node is Node3D and not node is Node2D and not node is Control:
		push_error("NodeFX: I can't animate this node. Give me Node3D, Node2D or Control.")
		return

	# Stop existing hover if any, to avoid stacking tweens
	kill_hover(node)

	# Adjust default height/amplitude for 3D nodes
	var final_height = height
	if node is Node3D and height == 10.0:
		final_height = 0.2

	var y_start = node.position.y

	var hover_tween = node.create_tween()
	NodeFX.CURRENTLY_RUNNING_TWEENS.append(hover_tween)
	hover_tween.finished.connect(func():
		NodeFX.erase_finished_tween(hover_tween)
		if hover_tweens.get(node) == hover_tween:
			hover_tweens.erase(node)
	)

	hover_tween.set_loops(loops)

	# Smooth lerp / ease back and forth
	# Step 1: Center to top (y_start to y_start - final_height)
	hover_tween.tween_property(node, "position:y", y_start - final_height, duration * 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	# Step 2: Top to bottom (y_start - final_height to y_start + final_height)
	hover_tween.tween_property(node, "position:y", y_start + final_height, duration * 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# Step 3: Bottom to center (y_start + final_height to y_start)
	hover_tween.tween_property(node, "position:y", y_start, duration * 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	hover_tweens[node] = hover_tween

static func kill_hover(node: Node):
	if hover_tweens.has(node):
		var tween = hover_tweens[node]
		if is_instance_valid(tween):
			tween.kill()
			NodeFX.erase_finished_tween(tween)
		hover_tweens.erase(node)
