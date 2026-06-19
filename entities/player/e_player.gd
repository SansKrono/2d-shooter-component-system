@tool
class_name Player
extends Entity

func define_components() -> Array:
	return [
		C_Health.new(100),
		C_Velocity.new(Vector2.ZERO, 200.0),
		C_Input.new(),
		C_Shooter.new(0.15, 500.0),
		C_Payload.new(12.0, 200.0),
		C_Trajectory.new(600.0, 8.0, 2.5),
		C_Volatility.new(0.3, 2.0),
		C_Resilience.new(1.0, 1.2),
		C_Luck.new(2.0),
		C_Currency.new(100),
		C_RelicInventory.new()
	]
