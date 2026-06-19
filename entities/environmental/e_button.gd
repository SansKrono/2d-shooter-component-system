@tool
class_name SpawnerButton
extends Entity

func define_components() -> Array:
	return [
		C_Interactable.new(80.0, Callable()),
		C_InteractableDebug.new(Color(0, 1, 0, 0.3), 2.0)
	]
