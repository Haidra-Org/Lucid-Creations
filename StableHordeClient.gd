extends TabContainer

onready var stable_horde_client = $"%StableHordeClient"
onready var grid = $"%Grid"
onready var line_edit = $"%PromptLine"

onready var display = $"%Display"
onready var width = $"%Width"
onready var height = $"%Height"
onready var amount = $"%Amount"


func _ready():
	stable_horde_client.connect("images_generated",self, "_on_images_generated")
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, '_on_viewport_resized')
	for slider_config in [width,height,amount]:
		slider_config.connect("value_changed", self, "_on_config_slider_value_changed", [slider_config])

func _on_Button_pressed():
	stable_horde_client.generate(line_edit.text)

func _on_images_generated(textures_list):
	for texture in textures_list:
		var tr = TextureRect.new()
		tr.rect_min_size = Vector2(128,128)
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = texture
		grid.add_child(tr)

func _on_viewport_resized() -> void:
	display.rect_min_size.x = get_viewport().size.x/2

func _on_config_slider_value_changed(slider_config: Control) -> void:
	stable_horde_client.set(slider_config.config_setting, slider_config.h_slider.value)
