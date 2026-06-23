class_name VisibilitySystem
extends System

const C_TRANSFORM = preload("res://components/movement/c_transform.gd")
const C_OFFSCREEN = preload("res://components/status/c_offscreen.gd")

func query() -> QueryBuilder:
	return q.with_all([C_TRANSFORM])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	# Avoid adding nodes in the editor viewport if running as @tool
	if Engine.is_editor_hint():
		return

	for entity in entities:
		if not (entity as Node) is Node2D:
			continue

		var notifier = entity.get_node_or_null("VisibilityNotifier") as VisibleOnScreenNotifier2D
		if not notifier:
			# Search for any pre-existing VisibleOnScreenNotifier2D child
			for child in entity.get_children():
				if child is VisibleOnScreenNotifier2D:
					notifier = child
					break

			if not notifier:
				notifier = VisibleOnScreenNotifier2D.new()
				notifier.name = "VisibilityNotifier"
				# Standard bounding box size for general entities
				notifier.rect = Rect2(-16, -16, 32, 32)
				entity.add_child(notifier)

				# Use a weak reference check to avoid memory safety issues if entity is destroyed
				var entity_ref = entity
				notifier.screen_entered.connect(func():
					if is_instance_valid(entity_ref):
						if entity_ref.has_component(C_OFFSCREEN):
							entity_ref.remove_component(C_OFFSCREEN)
							print("[VisibilitySystem] Entity %s entered screen, removed C_Offscreen" % entity_ref.name)
				)
				notifier.screen_exited.connect(func():
					if is_instance_valid(entity_ref):
						if not entity_ref.has_component(C_OFFSCREEN):
							entity_ref.add_component(C_OFFSCREEN.new(true))
							print("[VisibilitySystem] Entity %s exited screen, added C_Offscreen" % entity_ref.name)
				)

				# Establish initial state
				if notifier.is_on_screen():
					if entity.has_component(C_OFFSCREEN):
						entity.remove_component(C_OFFSCREEN)
				else:
					if not entity.has_component(C_OFFSCREEN):
						entity.add_component(C_OFFSCREEN.new(true))
