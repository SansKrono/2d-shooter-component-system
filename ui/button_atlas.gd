class_name ButtonAtlas
extends Resource

# Shadow Series button grid: 465x132 (5 cols × 3 rows, ~93×44 px each)
# Row 1: NEWGAME, CONTINUE, SETTINGS, QUIT, START
# Row 2: MAINMENU, CREDITS, BACK, DELETE, EXIT
# Row 3: RESUME, OPTIONS, SAVE, RESTART, YES

const BUTTON_TEXTURE = preload("res://ui/components/SHADOW Series - Pixel UI/Button/UI - button.png")
const BUTTON_WIDTH = 93
const BUTTON_HEIGHT = 44

var buttons: Dictionary = {
	"newgame": Rect2(0, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"continue": Rect2(93, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"settings": Rect2(186, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"quit": Rect2(279, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"start": Rect2(372, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"mainmenu": Rect2(0, 44, BUTTON_WIDTH, BUTTON_HEIGHT),
	"credits": Rect2(93, 44, BUTTON_WIDTH, BUTTON_HEIGHT),
	"back": Rect2(186, 44, BUTTON_WIDTH, BUTTON_HEIGHT),
	"delete": Rect2(279, 44, BUTTON_WIDTH, BUTTON_HEIGHT),
	"exit": Rect2(372, 44, BUTTON_WIDTH, BUTTON_HEIGHT),
	"resume": Rect2(0, 88, BUTTON_WIDTH, BUTTON_HEIGHT),
	"options": Rect2(93, 88, BUTTON_WIDTH, BUTTON_HEIGHT),
	"save": Rect2(186, 88, BUTTON_WIDTH, BUTTON_HEIGHT),
	"restart": Rect2(279, 88, BUTTON_WIDTH, BUTTON_HEIGHT),
	"yes": Rect2(372, 88, BUTTON_WIDTH, BUTTON_HEIGHT),
}

func get_button_atlas(button_name: String) -> AtlasTexture:
	var lower = button_name.to_lower()
	if lower not in buttons:
		push_error("Button '%s' not found in atlas" % button_name)
		return null

	var atlas = AtlasTexture.new()
	atlas.atlas = BUTTON_TEXTURE
	atlas.region = buttons[lower]
	return atlas
