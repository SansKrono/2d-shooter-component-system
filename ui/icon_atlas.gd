class_name IconAtlas
extends Resource

# Shadow Series icons2 grid: cyan-outlined icons
# Used for hearts, status, UI indicators

const ICONS_TEXTURE = preload("res://ui/components/shadow_series/Icons/UI - icons2.png")
const ICON_SIZE = 16

var icons: Dictionary = {
	"heart_full": Rect2(0, 0, ICON_SIZE, ICON_SIZE),
	"heart_half": Rect2(16, 0, ICON_SIZE, ICON_SIZE),
	"heart_empty": Rect2(32, 0, ICON_SIZE, ICON_SIZE),
	"shield": Rect2(48, 0, ICON_SIZE, ICON_SIZE),
	"star": Rect2(64, 0, ICON_SIZE, ICON_SIZE),
	"lightning": Rect2(80, 0, ICON_SIZE, ICON_SIZE),
	"fire": Rect2(96, 0, ICON_SIZE, ICON_SIZE),
	"ice": Rect2(112, 0, ICON_SIZE, ICON_SIZE),
	"poison": Rect2(128, 0, ICON_SIZE, ICON_SIZE),
	"soul": Rect2(144, 0, ICON_SIZE, ICON_SIZE),
}

func get_icon_atlas(icon_name: String) -> AtlasTexture:
	var lower = icon_name.to_lower()
	if lower not in icons:
		push_error("Icon '%s' not found in atlas" % icon_name)
		return null

	var atlas = AtlasTexture.new()
	atlas.atlas = ICONS_TEXTURE
	atlas.region = icons[lower]
	return atlas
