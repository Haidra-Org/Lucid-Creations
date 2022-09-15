extends TabContainer

onready var stable_horde_client = $"%StableHordeClient"
onready var grid = $"%Grid"
onready var line_edit = $"%PromptLine"
onready var display = $"%Display"
onready var width = $"%Width"
onready var height = $"%Height"
onready var amount = $"%Amount"
onready var seed_edit = $"%Seed"
onready var config_slider = $"%ConfigSlider"
onready var generate_button = $"%GenerateButton"


func _ready():
	stable_horde_client.connect("images_generated",self, "_on_images_generated")
	generate_button.connect("pressed",self,"_on_GenerateButton_pressed")
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, '_on_viewport_resized')
	_on_viewport_resized()


func _on_GenerateButton_pressed():
	for slider_config in [width,height,config_slider,amount]:
		stable_horde_client.set(slider_config.config_setting, slider_config.h_slider.value)
	stable_horde_client.gen_seed = seed_edit.text
	stable_horde_client.generate(line_edit.text)
	for child in grid.get_children():
		child.queue_free()

func _on_images_generated(textures_list):
	for texture in textures_list:
		var tr = TextureRect.new()
		tr.rect_min_size = get_grid_min_size()
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = texture
		grid.add_child(tr)

func _on_viewport_resized() -> void:
	display.rect_min_size.x = (get_viewport().size.x - 200) * 0.75
	display.rect_min_size.y = get_viewport().size.y - 20
	var grid_min_size = get_grid_min_size()
	for tr in grid.get_children():
		tr.rect_min_size = grid_min_size
		tr.rect_size = grid_min_size

func get_grid_min_size() -> Vector2:
	var tr_min_size = Vector2(stable_horde_client.width,stable_horde_client.height)
	if tr_min_size.x > display.rect_min_size.x:
		tr_min_size.x = display.rect_min_size.x
	if tr_min_size.y > display.rect_min_size.y:
		tr_min_size.y = display.rect_min_size.y
	return(tr_min_size)
