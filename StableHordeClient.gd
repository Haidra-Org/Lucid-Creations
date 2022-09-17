extends TabContainer

const GRID_TEXTURE_RECT = preload("res://GridTextureRect.tscn")
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
onready var display_focus = $"%DisplayFocus"
onready var image_seed = $"%ImageSeed"
onready var image_width = $"%ImageWidth"
onready var image_length = $"%ImageLength"
onready var image_prompt = $"%ImagePrompt"
onready var image_info = $"%ImageInfo"
onready var server_name = $"%ServerName"
onready var save_dir = $"%SaveDir"
onready var save = $"%Save"
onready var save_all = $"%SaveAll"

var grid_textures_size := 128

func _ready():
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("images_generated",self, "_on_images_generated")
	save_dir.connect("text_entered",self,"_on_savedir_entered")
	save.connect("pressed", self, "_on_save_pressed")
	save_all.connect("pressed", self, "_on_save_all_pressed")
	# warning-ignore:return_value_discarded
	generate_button.connect("pressed",self,"_on_GenerateButton_pressed")
	if globals.config.has_section("Parameters"):
		for key in globals.config.get_section_keys("Parameters"):
			# Fetch the data for each section.
			stable_horde_client.set(key, globals.config.get_value("Parameters", key))
		stable_horde_client.set("sampler_name", globals.config.get_value("Parameters", "sampler_name"))
	for slider_config in [width,height,config_slider,amount]:
		slider_config.set_value(stable_horde_client.get(slider_config.config_setting))
	var sampler_method_id = stable_horde_client.get_sampler_method_id()
	sampler_method.select(sampler_method_id)
	api_key.text = stable_horde_client.api_key
	var default_save_dir = globals.config.get_value("Config", "default_save_dir", "user://")
	if default_save_dir == "user://":
		match OS.get_name():
			"Windows":
				save_dir.text = '%APPDATA%\\Godot\\app_userdata\\Stable Horde Client\\'
			"X11":
				save_dir.text = '${HOME}/.local/share/godot/app_userdata/Stable Horde Client/'
	else:
		save_dir.text = default_save_dir

	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, '_on_viewport_resized')
	_on_APIKey_text_changed('')
	_on_viewport_resized()

func _on_GenerateButton_pressed():
	for slider_config in [width,height,config_slider,amount]:
		stable_horde_client.set(slider_config.config_setting, slider_config.h_slider.value)
		globals.set_setting(slider_config.config_setting, slider_config.h_slider.value)
	var sampler_name = sampler_method.get_item_text(sampler_method.selected)
	stable_horde_client.set("sampler_name", sampler_name)
	globals.set_setting("sampler_name", sampler_name)
	stable_horde_client.set("api_key", api_key.text)
	globals.set_setting("api_key", api_key.text)
	close_focus()
	for child in grid.get_children():
		child.queue_free()
	## DEBUG
#	_on_images_generated(_get_test_images())
#	return
	## END DEBUG
	stable_horde_client.generate(line_edit.text)

func _on_images_generated(textures_list):
	for texture in textures_list:
		var tr := GRID_TEXTURE_RECT.instance()
		tr.texture = texture
		# warning-ignore:return_value_discarded
		tr.connect("left_mouse_mouse_clicked", self, "_on_grid_texture_left_clicked", [tr])
#		tr.connect("right_mouse_mouse_clicked", self, "_on_grid_texture_right_clicked", [tr])
		grid.add_child(tr)

func _on_viewport_resized() -> void:
	if not display_focus.visible:
		_sets_size_without_display_focus()
	else:
		_sets_size_with_display_focus()


func _sets_size_without_display_focus() -> void:
	grid_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	grid_scroll.rect_min_size.x = (get_viewport().size.x - 500) * 0.75
	grid_scroll.rect_size.x = grid_scroll.rect_min_size.x
#	grid_scroll.rect_min_size.y = get_viewport().size.y - image_info.rect_size.y - 100
	grid_scroll.rect_min_size.y = 0
	for tr in grid.get_children():
		tr.rect_min_size = Vector2(128,128)
	grid.columns = int(grid_scroll.rect_min_size.x / 128)
	
func _sets_size_with_display_focus() -> void:
	grid_scroll.size_flags_vertical = SIZE_FILL
	grid_scroll.rect_min_size.x = (get_viewport().size.x - 500) * 0.75
	grid_scroll.rect_size.x = grid_scroll.rect_min_size.x
	grid_scroll.rect_min_size.y = 140
	for tr in grid.get_children():
		tr.rect_min_size = Vector2(64,64)
	grid.columns = int(grid_scroll.rect_min_size.x / 64)
	
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
			# warning-ignore:return_value_discarded
			OS.shell_open("https://stablehorde.net/register")
		"anonymous":
			api_key.text = "0000000000"
			_on_APIKey_text_changed('')


func _on_APIKey_text_changed(_new_text):
	if api_key.text == "0000000000":
		api_key_label.bbcode_text = "API Key = Anonymous [url=register](Register)[/url]"
	else:
		api_key_label.bbcode_text = "API Key [url=anonymous](Anonymize?)[/url]"

func _get_test_images(n = 10) -> Array:
	var test_array := []
	for iter in range(n):
		var new_seed = str(rand_seed(iter)[0])
		var tex := preload("res://icon.png")
		var img := tex.get_data()
		var new_texture := AIImageTexture.new('Test', new_seed, 'Test', "0000", "Test Server", 0, img)
		new_texture.create_from_image(img)
		test_array.append(new_texture)
	return(test_array)

func focus_on_image(imagetex: AIImageTexture) -> void:
	_sets_size_with_display_focus()
	display_focus.texture = imagetex
	display_focus.show()
	_fill_in_details(imagetex)
	save.disabled = false

func close_focus() -> void:
	save.disabled = true
	_sets_size_without_display_focus()
	display_focus.hide()

func _on_grid_texture_left_clicked(tr: GridTextureRect) -> void:
	if tr.is_highlighted():
		close_focus()
		return
	focus_on_image(tr.texture)
	clear_all_highlights_except(tr)

func clear_all_highlights_except(exception:GridTextureRect = null) -> void:
	for tr in grid.get_children():
		if tr != exception:
			tr.clear_highlight()
			print(tr)

func _fill_in_details(imagetex: AIImageTexture) -> void:
	image_prompt.text = "Prompt: " + imagetex.prompt
	image_seed.text = "Seed: " + imagetex.gen_seed
	image_width.text = "Width: " + str(imagetex.get_width())
	image_length.text = "Height: " + str(imagetex.get_height())
	server_name.text = "Server Name: " + str(imagetex.server_name)

func _on_savedir_entered(path: String) -> void:
	match path:
		'%APPDATA%\\Godot\\app_userdata\\Stable Horde Client\\':
			globals.set_setting('default_save_dir', "user://", "Config")
		'${HOME}/.local/share/godot/app_userdata/Stable Horde Client/':
			globals.set_setting('default_save_dir', "user://", "Config")
		_:
			globals.set_setting('default_save_dir', path, "Config")

func _on_save_pressed() -> void:
	_on_savedir_entered(save_dir.text)
	var save_dir_path : String = globals.config.get_value("Config", "default_save_dir", "user://")
	display_focus.texture.save_in_dir(save_dir_path)

func _on_save_all_pressed() -> void:
	var save_dir_path : String = globals.config.get_value("Config", "default_save_dir", "user://")
	for imgtex in grid.get_children():
		imgtex.texture.save_in_dir(save_dir_path)
