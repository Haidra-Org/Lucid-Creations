extends TabContainer

onready var stable_horde_client := $"%StableHordeClient"
onready var grid := $"%Grid"
onready var line_edit := $"%PromptLine"
onready var display := $"%Display"
onready var width := $"%Width"
onready var height := $"%Height"
onready var amount := $"%Amount"
onready var seed_edit := $"%Seed"
onready var config_slider := $"%ConfigSlider"
onready var generate_button := $"%GenerateButton"
onready var sampler_method := $"%SamplerMethod"
onready var api_key := $"%APIKey"
onready var api_key_label := $"%APIKeyLabel"
onready var grid_scroll = $"%GridScroll"


func _ready():
	stable_horde_client.connect("images_generated",self, "_on_images_generated")
	generate_button.connect("pressed",self,"_on_GenerateButton_pressed")
	if globals.config.has_section("Parameters"):
		for key in globals.config.get_section_keys("Parameters"):
			# Fetch the data for each section.
			stable_horde_client.set(key, globals.config.get_value("Parameters", key))
		stable_horde_client.set("sampler_method", globals.config.get_value("Parameters", "sampler_method"))
	for slider_config in [width,height,config_slider,amount]:
		slider_config.set_value(stable_horde_client.get(slider_config.config_setting))
	var sampler_method_id = stable_horde_client.get_sampler_method_id()
	sampler_method.select(sampler_method_id)
	api_key.text = stable_horde_client.api_key
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, '_on_viewport_resized')
	_on_APIKey_text_changed('')
	_on_viewport_resized()

func _on_GenerateButton_pressed():
	_on_images_generated(_get_test_images())
	return
	for slider_config in [width,height,config_slider,amount]:
		stable_horde_client.set(slider_config.config_setting, slider_config.h_slider.value)
		globals.set_setting(slider_config.config_setting, slider_config.h_slider.value)
	var sampler_name = sampler_method.get_item_text(sampler_method.selected)
	stable_horde_client.set("sampler_name", sampler_name)
	globals.set_setting("sampler_name", sampler_name)
	stable_horde_client.set("api_key", api_key.text)
	globals.set_setting("api_key", api_key.text)
	stable_horde_client.generate(line_edit.text)
	for child in grid.get_children():
		child.queue_free()

func _on_images_generated(textures_list):
	for texture in textures_list:
		var tr = TextureRect.new()
		tr.rect_min_size = Vector2(128,128)
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = texture
		grid.add_child(tr)

func _on_viewport_resized() -> void:
	grid_scroll.rect_min_size.x = (get_viewport().size.x - 200) * 0.75
	grid_scroll.rect_min_size.y = get_viewport().size.y - 20
#	var grid_min_size = get_grid_min_size()
#	for tr in grid.get_children():
#		tr.rect_min_size = grid_min_size
#		tr.rect_size = grid_min_size

func get_grid_min_size() -> Vector2:
	var tr_min_size = Vector2(stable_horde_client.width,stable_horde_client.height)
	if tr_min_size.x > grid_scroll.rect_min_size.x:
		tr_min_size.x = grid_scroll.rect_min_size.x
	if tr_min_size.y > grid_scroll.rect_min_size.y:
		tr_min_size.y = grid_scroll.rect_min_size.y
	return(tr_min_size)


func _on_APIKeyLabel_meta_clicked(meta):
	match meta:
		"register":
			OS.shell_open("https://stablehorde.net/register")
		"anonymous":
			api_key.text = "0000000000"
			_on_APIKey_text_changed('')


func _on_APIKey_text_changed(_new_text):
	if api_key.text == "0000000000":
		api_key_label.bbcode_text = "API Key = Anonymous [url=register](Register)[/url]"
	else:
		api_key_label.bbcode_text = "API Key [url=anonymous](Anonymize?)[/url]"

func _get_test_images(amount = 10) -> Array:
	var test_array := []
	for iter in range(amount):
		var new_seed = str(rand_seed(iter)[0])
		var new_texture := AIImageTexture.new('Test', new_seed, 'Test', 0)
		var tex := preload("res://icon.png")
		new_texture.create_from_image(tex.get_data())
		test_array.append(new_texture)
	return(test_array)
