extends TextureRect

onready var tutorial = $"%Tutorial"

func _ready():
	texture = Utils.get_random_background()
	if not globals.config.get_value("Options", "tutorial_seen", false):
		tutorial.popup_centered_clamped(Vector2(0,0), 0.5)
		globals.set_setting("tutorial_seen", true, "Options")
	
