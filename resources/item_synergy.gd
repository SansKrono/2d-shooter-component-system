class_name ItemSynergy
extends Resource

@export var name: String = ""
@export var description: String = ""
@export var required_tags: Array[String] = []
@export var min_items_with_tags: int = 2
@export var rarity: String = "common"
@export var build_identity: String = ""
@export var visual_effect: String = "default"
@export var synergy_effects: Array[Resource] = []

func matches_inventory(items: Array[Relic]) -> bool:
	if items.is_empty():
		return false

	var matching_count = 0
	for item in items:
		var has_all_tags = true
		for tag in required_tags:
			if not item.tags.has(tag):
				has_all_tags = false
				break
		if has_all_tags:
			matching_count += 1

	return matching_count >= min_items_with_tags
