extends Object
class_name NodeFX

static var flip_script = load("res://addons/node_fx/fx/node_fx_flip.gd")
static var pop_script = load("res://addons/node_fx/fx/node_fx_pop.gd")
static var change_color_script = load("res://addons/node_fx/fx/node_fx_change_color.gd")
static var fade_script = load("res://addons/node_fx/fx/node_fx_fade.gd")
static var shake_script = load("res://addons/node_fx/fx/node_fx_shake.gd")
static var pulse_script = load("res://addons/node_fx/fx/node_fx_pulse.gd")
static var hover_script = load("res://addons/node_fx/fx/node_fx_hover.gd")
static var save_original_data_script = load("res://addons/node_fx/utils/node_fx_save_original_data.gd")
static var stop_and_reset_script = load("res://addons/node_fx/utils/node_fx_stop_and_reset.gd")


# fx:
static func flip(node, duration, axis, reversed, snappy, variation): flip_script.flip(node, duration, axis, reversed, snappy, variation)
static func pop(node, duration, snappy): pop_script.pop(node, duration, snappy)
static func shake(node, duration, snappy, variation): shake_script.shake(node, duration, snappy, variation)
static func change_color(node, duration, color1, color2): change_color_script.change_color(node, duration, color1, color2)
static func color_flash(node, duration, color1, color2): change_color_script.color_flash(node, duration, color1, color2)
static func fade(node, duration, fade_in, fade_out): fade_script.fade(node, duration, fade_in, fade_out)
static func pulse(node, duration, loops): pulse_script.pulse(node, duration, loops)
static func hover(node, duration := 2.0, height := 10.0, loops := 0): hover_script.hover(node, duration, height, loops)


# utils:
static func save_original_data(node): save_original_data_script.save_original_data(node)
static func stop_and_reset(node): stop_and_reset_script.stop_and_reset(node)
static func kill_all_tweens(): stop_and_reset_script.kill_all_tweens()
static func kill_pulse_loop(node): pulse_script.kill_loop(node)
static func kill_hover(node: Node): hover_script.kill_hover(node)
static func reset_color(node): stop_and_reset_script.reset_color(node)
static func reset_position(node): stop_and_reset_script.reset_position(node)
static func reset_rotation(node): stop_and_reset_script.reset_rotation(node)
static func reset_scale(node): stop_and_reset_script.reset_scale(node)


# save original data:
static var ORIGINAL_MATERIALS: Dictionary = {}
static var ORIGINAL_COLORS: Dictionary = {}
static var ORIGINAL_SCALE 
static var ORIGINAL_POSITION 
static var ORIGINAL_ROTATION 
static var ORIGINAL_MODULATE := Color.WHITE 


# track running tweens
static var CURRENTLY_RUNNING_TWEENS: Array = []
static func erase_finished_tween(tween: Tween): 
	CURRENTLY_RUNNING_TWEENS.erase(tween)
	CURRENTLY_RUNNING_TWEENS = CURRENTLY_RUNNING_TWEENS.filter(
		func(t): return is_instance_valid(t)
	)
