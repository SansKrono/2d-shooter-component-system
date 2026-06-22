@tool
class_name Player
extends Entity

const C_TRANSFORM = preload("res://components/character/c_transform.gd")
const C_LOCOMOTION = preload("res://components/character/c_locomotion.gd")
const C_MASS = preload("res://components/character/c_mass.gd")
const C_ATTACK_MODE = preload("res://components/character/c_attack_mode.gd")

func define_components() -> Array:
	return [
		C_Health.new(100.0, 6, 0, 0, true),
		C_Velocity.new(Vector2.ZERO),
		C_Input.new(),
		C_Shooter.new(0.15, 500.0),
		C_Payload.new(12.0, 200.0),
		C_Trajectory.new(600.0, 8.0, 2.5),
		C_Volatility.new(0.3, 2.0),
		C_Luck.new(2.0),
		C_Currency.new(100),
		C_RelicInventory.new(),
		C_ATTACK_MODE.new("TECH"),
		C_TRANSFORM.new(Vector2.ZERO),
		C_LOCOMOTION.new(200.0, 900.0, 800.0),
		C_MASS.new(10.0),
		C_Physics.new(null)
	]

func on_ready():
	$PhysicsBody.global_position = self.get("global_position")
	var c_phys = get_component(C_Physics)
	if c_phys:
		c_phys.body = $PhysicsBody

	if not Engine.is_editor_hint():
		var trans = get_component(C_TRANSFORM)
		if trans and "global_position" in self:
			trans.position = self.get("global_position")
