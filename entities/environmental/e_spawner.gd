@tool
class_name SpawnerEntity
extends Entity

func define_components() -> Array:
	return [
		C_InteractableDebug.new(Color(0.6, 0.2, 0.8, 0.3), 2.0)
	]


