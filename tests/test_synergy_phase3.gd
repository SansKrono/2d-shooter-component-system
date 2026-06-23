extends Node

func _ready() -> void:
	print("=== Phase 3 Integration Test ===\n")

	# Setup
	var synergy_mgr = get_tree().root.get_node_or_null("SynergyManager")
	if not synergy_mgr:
		print("ERROR: SynergyManager not found!")
		return

	print("1. Testing synergy detection + effect application")

	# Load relics
	var tech_items = [
		load("res://resources/relics/seeking_algorithm.tres") as Relic,
		load("res://resources/relics/amplification_array.tres") as Relic,
	]

	# Update synergies
	synergy_mgr.update_synergies(tech_items)
	var active = synergy_mgr.get_active_synergies()
	print("   Collected 2 items (tech+precision, offensive)")
	print("   Active synergies: ", active.size())
	for syn in active:
		print("     ✓ ", syn.name)
		print("       Effects: ", syn.synergy_effects.size())
		for effect in syn.synergy_effects:
			if effect:
				print("         — ", effect.description)
				print("           damage mult: ", effect.get_stat_multiplier("damage"))
				print("           accuracy add: ", effect.get_stat_additive("accuracy"))

	print("\n2. Testing synergy aura component")
	var test_entity = Entity.new()
	test_entity.add_component(C_SynergyState.new())
	test_entity.add_component(C_SynergyAura.new())

	var aura = test_entity.get_component(C_SynergyAura) as C_SynergyAura
	if active.size() > 0:
		aura.add_synergy_visual(active[0])
		print("   Added synergy visual for: ", active[0].name)
		print("   Has active synergies: ", aura.has_active_synergies())
		print("   Combined color: ", aura.get_combined_color())

	print("\n3. Testing stat recalculation with synergies")
	print("   Base damage: 3.5")
	var dmg_mult = 1.0
	for syn in active:
		for effect in syn.synergy_effects:
			if effect:
				var mult = effect.get_stat_multiplier("damage")
				print("   Apply ", effect.description, " → mult *= ", mult)
				dmg_mult *= mult
	var final_dmg = 3.5 * dmg_mult
	print("   Final damage: ", final_dmg, " (", (final_dmg / 3.5 - 1) * 100, "% bonus)")

	print("\n4. Testing signal integration")
	var signal_fired = false
	synergy_mgr.synergy_activated.connect(func(_syn): signal_fired = true)
	synergy_mgr.update_synergies([])
	synergy_mgr.update_synergies(tech_items)
	print("   Signal fired on synergy activation: ", signal_fired)

	print("\n=== Phase 3 Test Complete ===")
