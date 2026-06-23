class_name ButtonAtlas
extends Resource

# Shadow Series button grid: 465x132 (5 cols × 4 rows, ~93×33 px each)
# Row 1: NEWGAME,	CONTINUE,	SETTINGS,	QUIT,		START
# Row 2: MAINMENU, 	CREDITS,	BACK,		DELETE, 	EXIT
# Row 3: RESUME, 	OPTIONS,	SAVE,		RESTART,	YES
# Row 4: NO, 		CONTROLS

const BUTTON_TEXTURE = preload("res://ui/components/shadow_series/Button/UI - button.png")
const BUTTON_WIDTH = 93
const BUTTON_HEIGHT = 33

var buttons: Dictionary = {
	"newgame": Rect2(0, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"continue": Rect2(93, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"settings": Rect2(186, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"quit": Rect2(279, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"start": Rect2(372, 0, BUTTON_WIDTH, BUTTON_HEIGHT),
	"mainmenu": Rect2(0, 33, BUTTON_WIDTH, BUTTON_HEIGHT),
	"credits": Rect2(93, 33, BUTTON_WIDTH, BUTTON_HEIGHT),
	"back": Rect2(186, 33, BUTTON_WIDTH, BUTTON_HEIGHT),
	"delete": Rect2(279, 33, BUTTON_WIDTH, BUTTON_HEIGHT),
	"exit": Rect2(372, 33, BUTTON_WIDTH, BUTTON_HEIGHT),
	"resume": Rect2(0, 66, BUTTON_WIDTH, BUTTON_HEIGHT),
	"options": Rect2(93, 66, BUTTON_WIDTH, BUTTON_HEIGHT),
	"save": Rect2(186, 66, BUTTON_WIDTH, BUTTON_HEIGHT),
	"restart": Rect2(279, 66, BUTTON_WIDTH, BUTTON_HEIGHT),
	"yes": Rect2(372, 66, BUTTON_WIDTH, BUTTON_HEIGHT),
	"no": Rect2(0, 99, BUTTON_WIDTH, BUTTON_HEIGHT),
	"controls": Rect2(93, 99, BUTTON_WIDTH, BUTTON_HEIGHT),
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
