extends MarginContainer

onready var remember_prompt = $"%RememberPrompt"

func _ready():
	remember_prompt.pressed = globals.config.get_value("Options", "remember_prompt", false)
	remember_prompt.connect("toggled",self,"_on_remember_prompt_pressed")

func _on_remember_prompt_pressed(pressed: bool) -> void:
	globals.set_setting("remember_prompt", pressed, "Options")
