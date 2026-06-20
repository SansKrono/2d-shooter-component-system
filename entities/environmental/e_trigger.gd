@tool
class_name TriggerArea
extends Entity

func define_components() -> Array:
	return [
		C_InteractableDebug.new(Color(0.0, 0.5, 1.0, 0.3), 2.0)
	]
