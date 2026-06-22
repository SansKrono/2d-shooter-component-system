class_name C_Velocity
extends Component

# Pure intent: where does this entity want to move?
# Speed is NOT stored here — it belongs to C_Locomotion.
# For non-locomotion entities (projectiles), see note below.

@export var direction: Vector2 = Vector2.ZERO
@export var knockback: Vector2 = Vector2.ZERO

func _init(dir: Vector2 = Vector2.ZERO, kb: Vector2 = Vector2.ZERO) -> void:
	direction = dir
	knockback = kb


# ── Projectiles and non-locomotion entities ──────────────────────────────
#
# If you have projectiles that use C_Velocity but NOT C_Locomotion,
# they currently rely on the old c_vel.speed fallback in MovementSystem.
#
# Two clean options:
#
# Option A — keep a C_Projectile component that holds speed:
#
#   class_name C_Projectile extends Component
#   @export var speed: float = 400.0
#   @export var damage: float = 10.0
#
#   MovementSystem fallback becomes:
#     var c_proj = entity.get_component(C_Projectile)
#     var fallback_speed = c_proj.speed if c_proj else 200.0
#     entity.global_position += c_vel.direction * fallback_speed * delta
#
# Option B — give projectiles their own C_Locomotion with no friction/accel:
#
#   C_Locomotion.new(400.0, 99999.0, 99999.0)
#   # Instant acceleration, no decay — travels in straight line at full speed.
#   # Gets move_and_slide for free, so it collides correctly.
#
# Option B is cleaner architecturally. Option A is faster to implement now.
# ─────────────────────────────────────────────────────────────────────────
