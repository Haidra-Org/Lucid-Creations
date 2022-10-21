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
onready var steps_slider := $"%StepsSlider"
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
onready var worker_name = $"%WorkerName"
onready var save_dir = $"%SaveDir"
onready var save = $"%Save"
onready var save_all = $"%SaveAll"
onready var status_text = $"%StatusText"
onready var controls_right := $"%ControlsRight"
onready var controls_left := $"%ControlsLeft"
onready var generations_processing = $"%GenerationsProcessing"
onready var generations_done = $"%GenerationsDone"
onready var cancel_button = $"%CancelButton"
onready var _tween = $"%Tween"
onready var progress_text = $"%ProgressText"
onready var prompt_cover = $"%PromptCover"
onready var nsfw = $"%NSFW"
onready var censor_nsfw = $"%CensorNSFW"
onready var trusted_workers = $"%TrustedWorkers"
onready var model_select = $"%ModelSelect"


var controls_width := 500

func _ready():
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("images_generated",self, "_on_images_generated")
	stable_horde_client.connect("request_initiated",model_select, "_on_request_initiated")
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("request_failed",self, "_on_request_failed")
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("request_warning",self, "_on_request_warning")
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("image_processing",self, "_on_image_process_update")
	save_dir.connect("text_entered",self,"_on_savedir_entered")
	save.connect("pressed", self, "_on_save_pressed")
	save_all.connect("pressed", self, "_on_save_all_pressed")
	# warning-ignore:return_value_discarded
	generate_button.connect("pressed",self,"_on_GenerateButton_pressed")
	# warning-ignore:return_value_discarded
	cancel_button.connect("pressed",self,"_on_CancelButton_pressed")
	_check_html5()
	if globals.config.has_section("Parameters"):
		for key in globals.config.get_section_keys("Parameters"):
			# Fetch the data for each section.
			stable_horde_client.set(key, globals.config.get_value("Parameters", key))
		stable_horde_client.set("sampler_name", globals.config.get_value("Parameters", "sampler_name"))
		stable_horde_client.set("models", globals.config.get_value("Parameters", "models"))
	for slider_config in [width,height,config_slider,steps_slider,amount]:
		slider_config.set_value(stable_horde_client.get(slider_config.config_setting))
	var sampler_method_id = stable_horde_client.get_sampler_method_id()
	sampler_method.select(sampler_method_id)
	api_key.text = stable_horde_client.api_key
	var default_save_dir = globals.config.get_value("Config", "default_save_dir", "user://")
	if default_save_dir in ["user://", '']:
		_set_default_savedir_path()
	else:
		save_dir.text = default_save_dir
		_set_default_savedir_path(true)

	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, '_on_viewport_resized')
	_on_APIKey_text_changed('')
	_on_viewport_resized()
#	var tween2 = create_tween()
#	print_debug(tween2)
#	var t = tween2.tween_property(generations_processing, "value", 15, 2)
#	print_debug(t)


func _on_GenerateButton_pressed():
	status_text.text = ''
	for slider_config in [width,height,config_slider,steps_slider,amount]:
		stable_horde_client.set(slider_config.config_setting, slider_config.h_slider.value)
		globals.set_setting(slider_config.config_setting, slider_config.h_slider.value)
	var sampler_name = sampler_method.get_item_text(sampler_method.selected)
	stable_horde_client.set("sampler_name", sampler_name)
	globals.set_setting("sampler_name", sampler_name)
	var model_name = model_select.get_item_text(model_select.selected)
	var models = []
	if model_name != "Any model":
		models = [model_name]
	stable_horde_client.set("model_names", models)
	globals.set_setting("models", models)
	stable_horde_client.set("api_key", api_key.text)
	globals.set_setting("api_key", api_key.text)
	stable_horde_client.set("nsfw", nsfw.pressed)
	globals.set_setting("nsfw", nsfw.pressed)
	stable_horde_client.set("censor_nsfw", censor_nsfw.pressed)
	globals.set_setting("censor_nsfw", censor_nsfw.pressed)
	stable_horde_client.set("trusted_workers", trusted_workers.pressed)
	globals.set_setting("trusted_workers", trusted_workers.pressed)
	stable_horde_client.set("gen_seed", seed_edit.text)
	if line_edit.text != '':
		stable_horde_client.prompt = line_edit.text
	else:
		stable_horde_client.prompt = line_edit.placeholder_text
	close_focus()
	for child in grid.get_children():
		child.queue_free()
	## DEBUG
#	_on_images_generated(_get_test_images())
#	return
	## END DEBUG
	generate_button.visible = false
	cancel_button.visible = true
	prompt_cover.visible = true
	progress_text.visible = true
	stable_horde_client.generate(line_edit.text)


func _on_CancelButton_pressed():
	progress_text.text = "Cancelling request..."
	stable_horde_client.cancel_request()

func _on_images_generated(completed_payload: Dictionary):
	_reset_input()
	for texture in completed_payload["image_textures"]:
		var tr := GRID_TEXTURE_RECT.instance()
		tr.texture = texture
		# warning-ignore:return_value_discarded
		tr.connect("left_mouse_mouse_clicked", self, "_on_grid_texture_left_clicked", [tr])
#		tr.connect("right_mouse_mouse_clicked", self, "_on_grid_texture_right_clicked", [tr])
		grid.add_child(tr)

func _on_image_process_update(stats: Dictionary) -> void:
#	print_debug(stats)
	var total_images = stats.finished + stats.waiting + stats.processing
	generations_processing.max_value = total_images
	generations_done.max_value = total_images
	# warning-ignore:return_value_discarded
	_tween.interpolate_property(generations_processing, 'value', generations_processing.value, stats.finished + stats.processing, 0.9, Tween.TRANS_SINE, Tween.EASE_IN)
	_tween.interpolate_property(generations_done, 'value', generations_done.value, stats.finished, 1, Tween.TRANS_SINE, Tween.EASE_IN)
	# warning-ignore:return_value_discarded
	_tween.start()
#	if tween and not tween.is_valid():
#		tween.stop()
#	if not tween:
#		tween = create_tween().set_parallel(true)
#		print_debug(tween)
#		tween.tween_property(generations_processing, "value", stats.finished + stats.processing, 0.8).set_trans(Tween.TRANS_SINE)
#		tween.tween_property(generations_done, "value", stats.finished, 1).set_trans(Tween.TRANS_SINE)
#	tween.set_trans(Tween.TRANS_SINE).start()
	var stats_format = {
		"waiting": stats.waiting,
		"finished": stats.finished,
		"processing":  + stats.processing,
		"elapsed": str(ceil(stats.elapsed_time / 1000)),
		"eta": str(stats.wait_time)
	}
	progress_text.text = " {waiting} Waiting. {processing} Processing. {finished} Finished. ETA {eta} sec. Elapsed {elapsed} sec.".format(stats_format)
	if stats.queue_position == 0:
		status_text.bbcode_text = "Thank you for using the horde!\n"\
			+ "If you enjoy this service join us in [url=discord]discord[/url] or subscribe on [url=patreon]patreon[/url]"
		status_text.modulate = Color(0,1,0)
	elif stats.wait_time > 200 or stats.elapsed_time / 1000> 150:
		status_text.bbcode_text = "Unfortunately the Hoard appears to be under heavy load at the moment! Your queue position is {queue}.\n".format({"queue":stats.queue_position})\
				+ "If you can, please consider [url=worker]adding your own GPU[/url] to the horde to get more generation priority!"
		status_text.modulate = Color(0.84,0.47,0)
	else:
		status_text.bbcode_text = "Your queue position is {queue}.\n".format({"queue":stats.queue_position})
		status_text.modulate = Color(0,1,0)


func _on_viewport_resized() -> void:
	if not display_focus.visible:
		_sets_size_without_display_focus()
	else:
		_sets_size_with_display_focus()


func _sets_size_without_display_focus() -> void:
	grid_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	grid_scroll.rect_min_size.x = (get_viewport().size.x - controls_width) * 0.75
	grid_scroll.rect_size.x = grid_scroll.rect_min_size.x
#	grid_scroll.rect_min_size.y = get_viewport().size.y - image_info.rect_size.y - 100
	grid_scroll.rect_min_size.y = 0
	for tr in grid.get_children():
		tr.rect_min_size = Vector2(128,128)
	grid.columns = int(grid_scroll.rect_min_size.x / 128)

func _sets_size_with_display_focus() -> void:
	grid_scroll.size_flags_vertical = SIZE_FILL
	grid_scroll.rect_min_size.x = (get_viewport().size.x - controls_width) * 0.75
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

func _on_StatusText_meta_clicked(meta):
	match meta:
		"discord":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://discord.gg/3DxrhksKzn")
		"patreon":
			OS.shell_open("https://www.patreon.com/db0")
		"worker":
			OS.shell_open("https://github.com/db0/AI-Horde/blob/main/README_StableHorde.md#joining-the-horde")

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
		var new_texture := AIImageTexture.new('Test Prompt', {"sampler_name":"Test", "steps":0}, new_seed, 'Test worker', 'Test worker ID', img)
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

func _fill_in_details(imagetex: AIImageTexture) -> void:
	image_prompt.text = "Prompt: " + imagetex.prompt
	image_seed.text = "Seed: " + imagetex.gen_seed
	image_width.text = "Width: " + str(imagetex.get_width())
	image_length.text = "Height: " + str(imagetex.get_height())
	worker_name.text = "Worker Name: " + str(imagetex.worker_name)

func _on_savedir_entered(path: String) -> void:
	match path:
		'%APPDATA%\\Godot\\app_userdata\\Stable Horde Client\\':
			globals.set_setting('default_save_dir', "user://", "Config")
		'${HOME}/.local/share/godot/app_userdata/Stable Horde Client/':
			globals.set_setting('default_save_dir', "user://", "Config")
		'~/Library/Application Support/Godot/app_userdata/Stable Horde Client/':
			globals.set_setting('default_save_dir', "user://", "Config")
		'':
			_set_default_savedir_path()
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

func _on_request_failed(error_msg: String) -> void:
	status_text.text = error_msg
	status_text.modulate = Color(1,0,0)
	_reset_input()

func _on_request_warning(warning_msg: String) -> void:
	status_text.text = warning_msg
	status_text.modulate = Color(0.84,0.47,0)

func _check_html5() -> void:
	if OS.get_name() != "HTML5":
		return
	controls_width = 200
	save.hide()
	save_all.hide()
	save_dir.hide()
	controls_right.hide()
	$"%SaveDirLabel".hide()
	controls_right.remove_child(status_text)
	controls_left.add_child(status_text)
	status_text.text = "Warning: Saving disabled in browser version due to sandboxing. Please download the local executable to save your generations!"
	status_text.modulate = Color(1,1,0)

func _reset_input() -> void:
	_tween.interpolate_property(generations_processing, 'value', generations_processing.value, 0, 1, Tween.TRANS_SINE, Tween.EASE_IN)
	_tween.interpolate_property(generations_done, 'value', generations_done.value, 0, 0.9, Tween.TRANS_SINE, Tween.EASE_IN)
	# warning-ignore:return_value_discarded
	_tween.start()
#	generations_processing.value = 0
#	generations_done.value = 0
	generate_button.visible = true
	cancel_button.visible = false
	progress_text.visible = false
	prompt_cover.visible = false
	progress_text.text = "Request initiating..."


func _set_default_savedir_path(only_placholder = false) -> void:
	match OS.get_name():
		"Windows":
			if not only_placholder:
				save_dir.text = '%APPDATA%\\Godot\\app_userdata\\Stable Horde Client\\'
			save_dir.placeholder_text = '%APPDATA%\\Godot\\app_userdata\\Stable Horde Client\\'
		"X11":
			if not only_placholder:
				save_dir.text = '${HOME}/.local/share/godot/app_userdata/Stable Horde Client/'
			save_dir.placeholder_text = '${HOME}/.local/share/godot/app_userdata/Stable Horde Client/'
			
		_:
			if not only_placholder:
				save_dir.text = '~/Library/Application Support/Godot/app_userdata/Stable Horde Client/'
			save_dir.placeholder_text = '~/Library/Application Support/Godot/app_userdata/Stable Horde Client/'

