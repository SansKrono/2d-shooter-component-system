extends Object

static var pulse_tween

static func pulse(node, duration, loops := 20): # 20 loops for safety
	
	if not node is Node3D and not node is Node2D and not node is Control:
		# ERROR - NODE NOT ANIMATABLE 
		push_error("NodeFX: I can't animate this node. Give me Node3D, Node2D or Control.")
		return
	
	if node is Control:
		node.pivot_offset = node.size * 0.5
	
	var s = node.scale
	
	pulse_tween = node.create_tween()
	NodeFX.CURRENTLY_RUNNING_TWEENS.append(pulse_tween)
	pulse_tween.finished.connect(func():
		NodeFX.erase_finished_tween(pulse_tween)
		)
	
	pulse_tween.set_loops(loops) # 0 for infinite loop
	pulse_tween.tween_property(node, "scale", s * 1.08, duration * 0.25)
	pulse_tween.tween_property(node, "scale", s * 0.98, duration * 0.25)
	pulse_tween.tween_property(node, "scale", s * 1.04, duration * 0.25)
	pulse_tween.tween_property(node, "scale", s , duration * 0.25)


static func kill_loop(node: Node):
	if pulse_tween:
		pulse_tween.kill()
		NodeFX.erase_finished_tween(pulse_tween)
		NodeFX.stop_and_reset(node)
