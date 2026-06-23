extends Node

func _ready() -> void:
	# Load relics
	var aetheric = load("res://resources/relics/aetheric_kernel.tres") as Relic
	var seeking = load("res://resources/relics/seeking_algorithm.tres") as Relic
	var amplification = load("res://resources/relics/amplification_array.tres") as Relic
	var biotic = load("res://resources/relics/biotic_capacitor.tres") as Relic

	print("=== Synergy System Test ===")
	print("Loaded relics:")
	print("  - ", aetheric.name, " tags: ", aetheric.tags)
	print("  - ", seeking.name, " tags: ", seeking.tags)
	print("  - ", amplification.name, " tags: ", amplification.tags)
	print("  - ", biotic.name, " tags: ", biotic.tags)

	# Test synergy manager
	var synergy_mgr = get_node("/root/SynergyManager")
	if synergy_mgr:
		print("\nSynergies loaded: ", synergy_mgr.all_synergies.size())
		for synergy in synergy_mgr.all_synergies:
			var effect_count = synergy.synergy_effects.size()
			print("  - ", synergy.name, " (tags: ", synergy.required_tags, ", min: ", synergy.min_items_with_tags, ", effects: ", effect_count, ")")
			for effect in synergy.synergy_effects:
				if effect:
					print("    ✓ ", effect.get_class(), " — ", effect.description)
	else:
		print("ERROR: SynergyManager not found!")
		return

	# Test synergy detection
	print("\n=== Testing Synergy Detection ===")

	# Test 1: Empty inventory
	var test_items: Array[Relic] = []
	synergy_mgr.update_synergies(test_items)
	print("Empty inventory → ", synergy_mgr.get_active_synergies().size(), " active synergies")

	# Test 2: Add 1 magic + chaos item
	test_items.append(aetheric)
	synergy_mgr.update_synergies(test_items)
	print("1 magic+chaos → ", synergy_mgr.get_active_synergies().size(), " active synergies")

	# Test 3: Add 1 tech + precision item (should trigger Hybrid Balance if we had magic)
	test_items.append(seeking)
	synergy_mgr.update_synergies(test_items)
	print("1 magic+chaos + 1 tech+precision → ", synergy_mgr.get_active_synergies().size(), " active synergies")
	for syn in synergy_mgr.get_active_synergies():
		print("  ✓ ", syn.name)

	# Test 4: Add another magic item (should not trigger chaos_overload yet, need 2 magic+chaos)
	test_items.append(biotic)
	synergy_mgr.update_synergies(test_items)
	print("+ 1 defensive → ", synergy_mgr.get_active_synergies().size(), " active synergies")
	for syn in synergy_mgr.get_active_synergies():
		print("  ✓ ", syn.name)

	print("\n=== Test Complete ===")
