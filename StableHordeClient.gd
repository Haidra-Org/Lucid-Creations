extends TabContainer

const GRID_TEXTURE_RECT = preload("res://GridTextureRect.tscn")
var placeholder_prompts := [
	"Surface photo of planet made of cheese, space background",
	"A legion of cute monster toys",
	"giant magical gemstone, crystal, magical, colorful, fantasy ore, high detail, illustration, bright lighting, glow, wide focus, rough, raw, gem, octane render, valuables, 3d, galaxy, pretty, reflection, smooth, glass, mana ### haze, fog, text, watermark, bloom, fuzz, blur",
	"professional portrait render head shot of a simplified minimalist cute synthwave panda, looking sideways, happy, side profile, covered in blue pink fur, teal body, photorealist, perfect cuddly panda face, perfect panda eyes, in colored smoke, dark purple studio background, volumetric lighting, ultra-hd, intricate, stunning anime painting, dof",
	"Psychedelic Surreal victorian landscape art, dark shadows, muted colors, intricate brush strokes, masterpiece oil painting, intricate brush strokes, muted colour palette, hard lighting, dark, eerie",
	"photorealistic rendering of a vast landscape, vivid colors, fantasy landscape",
	"Rainbow jellyfish on a a deep colorful ocean, reef coral, concept art by senior character artist, cgsociety, plasticien, unreal engine 5, artstation, hd, concept art, an ambient occlusion render by Raphael, featured on zbrush central, photorealism, reimagined by industrial light and magic, rendered in maya, rendered in cinema4d !!!!Centered composition!!!###bad art, strange colors, sketch ,lacklustre, repetitive, lowres, deformed, old, childish",
]

onready var options = $"%Options"
onready var stable_horde_client := $"%StableHordeClient"
onready var stable_horde_rate_generation := $"%StableHordeRateGeneration"
onready var grid := $"%Grid"
onready var prompt_line_edit := $"%PromptLine"
onready var negative_prompt_line_edit := $"%NegativePromptLine"
onready var display := $"%Display"
onready var width := $"%Width"
onready var height := $"%Height"
onready var amount := $"%Amount"
onready var seed_edit := $"%Seed"
onready var config_slider := $"%ConfigSlider"
onready var steps_slider := $"%StepsSlider"
onready var generate_button := $"%GenerateButton"
onready var sampler_method := $"%SamplerMethod"
onready var karras := $"%Karras"
onready var grid_scroll = $"%GridScroll"
onready var display_focus = $"%DisplayFocus"
onready var focused_image = $"%FocusedImage"
onready var image_seed = $"%ImageSeed"
onready var image_width = $"%ImageWidth"
onready var image_length = $"%ImageLength"
onready var image_prompt = $"%ImagePrompt"
onready var image_info = $"%ImageInfo"
onready var image_buttons = $"%ImageButtons"
onready var generation_model = $"%GenerationModel"
onready var worker_name = $"%WorkerName"
onready var worker_id = $"%WorkerID"
onready var save = $"%Save"
onready var save_all = $"%SaveAll"
onready var status_text = $"%StatusText"
onready var controls_basic := $"%Basic"
onready var control_advanced := $"%Advanced"
onready var generations_processing = $"%GenerationsProcessing"
onready var generations_done = $"%GenerationsDone"
onready var cancel_button = $"%CancelButton"
onready var _tween = $"%Tween"
onready var progress_text = $"%ProgressText"
onready var prompt_cover = $"%PromptCover"
onready var nsfw = $"%NSFW"
onready var negative_prompt = $"%NegativePrompt"
onready var censor_nsfw = $"%CensorNSFW"
onready var trusted_workers = $"%TrustedWorkers"
onready var controls = $"%Controls"
# img2img
onready var img_2_img_enabled = $"%Img2ImgEnabled"
onready var denoising_strength = $"%DenoisingStrength"
onready var select_image = $"%SelectImage"
onready var open_image = $"%OpenImage"
onready var image_preview = $"%ImagePreview"
# model
onready var model = $"%Model"
# ratings
onready var aesthetic_rating = $"%AestheticRating"
onready var best_of = $"%BestOf"
onready var submit_ratings = $"%SubmitRatings"

func _ready():
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("request_initiated", model, "_on_request_initiated")
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("images_generated",self, "_on_images_generated")
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("request_failed",self, "_on_request_failed")
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("request_warning",self, "_on_request_warning")
	# warning-ignore:return_value_discarded
	stable_horde_client.connect("image_processing",self, "_on_image_process_update")
	# warning-ignore:return_value_discarded
	img_2_img_enabled.connect("toggled",self,"on_img2img_toggled")
	# warning-ignore:return_value_discarded
	select_image.connect("pressed",self,"on_image_select_pressed")
	# warning-ignore:return_value_discarded
	open_image.connect("file_selected",self,"_on_source_image_selected")
	_connect_hover_signals()
	save.connect("pressed", self, "_on_save_pressed")
	save_all.connect("pressed", self, "_on_save_all_pressed")
	# warning-ignore:return_value_discarded
	generate_button.connect("pressed",self,"_on_GenerateButton_pressed")
	# warning-ignore:return_value_discarded
	cancel_button.connect("pressed",self,"_on_CancelButton_pressed")
	model.connect("prompt_inject_requested",self,"_on_prompt_inject")
	# Ratings
	EventBus.connect("shared_toggled", self, "_on_shared_toggled")
	best_of.connect("toggled",self,"on_bestof_toggled")
	aesthetic_rating.connect("item_selected",self,"on_aethetic_rating_selected")
	submit_ratings.connect("pressed", self, "_on_submit_ratings_pressed")
	stable_horde_rate_generation.connect("generation_rated",self, "_on_generation_rated")
	stable_horde_rate_generation.connect("request_failed",self, "_on_generation_rating_failed")
	_on_shared_toggled()
	_check_html5()
	if globals.config.has_section("Parameters"):
		for key in globals.config.get_section_keys("Parameters"):
			# Fetch the data for each section.
			stable_horde_client.set(key, globals.config.get_value("Parameters", key))
		stable_horde_client.set("sampler_name", globals.config.get_value("Parameters", "sampler_name", stable_horde_client.sampler_name))
		stable_horde_client.set("models", globals.config.get_value("Parameters", "models", stable_horde_client.models))
	for slider_config in [width,height,config_slider,steps_slider,amount,denoising_strength]:
		slider_config.set_value(stable_horde_client.get(slider_config.config_setting))
	karras.pressed = stable_horde_client.karras
	negative_prompt.pressed = globals.config.get_value("Options", "negative_prompt", false)
	nsfw.pressed = stable_horde_client.nsfw
	censor_nsfw.pressed = stable_horde_client.censor_nsfw
	var sampler_method_id = stable_horde_client.get_sampler_method_id()
	sampler_method.select(sampler_method_id)
	_on_SamplerMethod_item_selected(sampler_method_id)
	# The stable horde client is set from the Parameters settings
	options.set_api_key(stable_horde_client.api_key)
	options.login()
	if globals.config.get_value("Options", "remember_prompt", false):
		prompt_line_edit.text = globals.config.get_value("Options", "saved_prompt", '')
		negative_prompt_line_edit.text = globals.config.get_value("Options", "saved_negative_prompt", '')

	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, '_on_viewport_resized')
	_on_viewport_resized()
	randomize()
	var rand_index : int = randi() % placeholder_prompts.size()
	prompt_line_edit.placeholder_text = placeholder_prompts[rand_index]
	
#	var tween2 = create_tween()
#	print_debug(tween2)
#	var t = tween2.tween_property(generations_processing, "value", 15, 2)
#	print_debug(t)


func _on_GenerateButton_pressed():
	status_text.text = ''
	for slider_config in [width,height,config_slider,steps_slider,amount,denoising_strength]:
		stable_horde_client.set(slider_config.config_setting, slider_config.h_slider.value)
		globals.set_setting(slider_config.config_setting, slider_config.h_slider.value)
	var sampler_name = sampler_method.get_item_text(sampler_method.selected)
	stable_horde_client.set("sampler_name", sampler_name)
	globals.set_setting("sampler_name", sampler_name)
	var model_name = model.get_selected_model()
	var models = []
	if model_name != "Any model":
		models = [model_name]
	stable_horde_client.set("models", models)
	globals.set_setting("models", models)
	stable_horde_client.set("api_key", options.get_api_key())
	stable_horde_client.set("karras", karras.pressed)
	globals.set_setting("karras", karras.pressed)
	stable_horde_client.set("nsfw", nsfw.pressed)
	globals.set_setting("nsfw", nsfw.pressed)
	stable_horde_client.set("censor_nsfw", censor_nsfw.pressed)
	globals.set_setting("censor_nsfw", censor_nsfw.pressed)
	stable_horde_client.set("trusted_workers", trusted_workers.pressed)
	globals.set_setting("trusted_workers", trusted_workers.pressed)
	stable_horde_client.set("shared", globals.config.get_value("Options", "share", true))
	stable_horde_client.set("gen_seed", seed_edit.text)
	stable_horde_client.set("post_processing", globals.config.get_value("Parameters", "post_processing", stable_horde_client.post_processing))
	if prompt_line_edit.text != '':
		stable_horde_client.prompt = prompt_line_edit.text
	else:
		stable_horde_client.prompt = prompt_line_edit.placeholder_text
	if globals.config.get_value("Options", "negative_prompt", false) and negative_prompt_line_edit.text != '':
		stable_horde_client.prompt += '###' + negative_prompt_line_edit.text
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
	stable_horde_client.generate()
	globals.set_setting("saved_prompt", prompt_line_edit.text, "Options")
	globals.set_setting("saved_negative_prompt", negative_prompt_line_edit.text, "Options")


func _on_CancelButton_pressed():
	progress_text.text = "Cancelling request..."
	stable_horde_client.cancel_request()

func _on_images_generated(completed_payload: Dictionary):
	_reset_input()
	save_all.disabled = false
	for texture in completed_payload["image_textures"]:
		var tr := GRID_TEXTURE_RECT.instance()
		tr.set_texture(texture)
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
		"processing": stats.processing,
		"restarted": '',
		"elapsed": str(ceil(stats.elapsed_time / 1000)),
		"eta": str(stats.wait_time)
	}
	if stats.restarted > 0:
		stats_format["restarted"] = " Restarted:" + str(stats.restarted) + '.'
	progress_text.text = " {waiting} Waiting. {processing} Processing.{restarted} {finished} Finished. ETA {eta} sec. Elapsed {elapsed} sec.".format(stats_format)
	if stats.queue_position == 0:
		status_text.bbcode_text = "Thank you for using the horde! "\
			+ "If you enjoy this service join us in [url=discord]discord[/url] or subscribe on [url=patreon]patreon[/url] if you haven't already."
		status_text.modulate = Color(0,1,0)
	elif stats.wait_time > 200 or stats.elapsed_time / 1000> 150:
		status_text.bbcode_text = "The Horde appears to be under heavy load at the moment! Your queue position is {queue}. ".format({"queue":stats.queue_position})\
				+ "Please consider [url=worker]adding your own GPU[/url] to the horde to get more generation priority!"
		status_text.modulate = Color(0.84,0.47,0)
	else:
		status_text.bbcode_text = "Your queue position is {queue}.".format({"queue":stats.queue_position})
		status_text.modulate = Color(0,1,0)


func _on_viewport_resized() -> void:
	# Disabling now with the tabs
#	return
	# warning-ignore:unreachable_code
	if not display_focus.visible:
		_sets_size_without_display_focus()
	else:
		_sets_size_with_display_focus()


func _sets_size_without_display_focus() -> void:
	grid_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	grid_scroll.rect_min_size.x = (get_viewport().size.x - controls.rect_size.x) * 0.84
	grid_scroll.rect_size.x = grid_scroll.rect_min_size.x
#	grid_scroll.rect_min_size.y = get_viewport().size.y - image_info.rect_size.y - 100
	grid_scroll.rect_min_size.y = 0
	for tr in grid.get_children():
		tr.rect_min_size = Vector2(128,128)
	grid.columns = int(grid_scroll.rect_min_size.x / 128)

func _sets_size_with_display_focus() -> void:
	grid_scroll.size_flags_vertical = SIZE_FILL
	grid_scroll.rect_min_size.x = (get_viewport().size.x - controls.rect_size.x) * 0.84
	grid_scroll.rect_size.x = grid_scroll.rect_min_size.x
	grid_scroll.rect_min_size.y = 150
	for tr in grid.get_children():
		tr.rect_min_size = Vector2(64,64)
	grid.columns = int(grid_scroll.rect_min_size.x / 128)

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
			# warning-ignore:return_value_discarded
			OS.shell_open("https://www.patreon.com/db0")
		"worker":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://github.com/db0/AI-Horde/blob/main/README_StableHorde.md#joining-the-horde")


func _get_test_images(n = 10) -> Array:
	var test_array := []
	for iter in range(n):
		var new_seed = str(rand_seed(iter)[0])
		var tex := preload("res://icon.png")
		var img := tex.get_data()
		var new_texture := AIImageTexture.new(
			'Test Prompt', 
			{"sampler_name":"Test", 
			"steps":0}, 
			new_seed, 
			"Test Model", 
			'Test worker', 
			'Test worker ID', 
			OS.get_unix_time(), 
			img,
			'Test Image ID')
		new_texture.create_from_image(img)
		test_array.append(new_texture)
	return(test_array)

func focus_on_image(imagetex: AIImageTexture) -> void:
	_sets_size_with_display_focus()
	focused_image.texture = imagetex
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
	best_of.pressed = tr.bestof
	aesthetic_rating.select(tr.aesthetic_rating)

func clear_all_highlights_except(exception:GridTextureRect = null) -> void:
	for tr in grid.get_children():
		if tr != exception:
			tr.clear_highlight()

func _fill_in_details(imagetex: AIImageTexture) -> void:
	image_prompt.text = "Prompt: " + imagetex.prompt
	image_seed.text = "Seed: " + imagetex.gen_seed
	image_width.text = "Width: " + str(imagetex.get_width())
	image_length.text = "Height: " + str(imagetex.get_height())
	generation_model.text = "Model: " + str(imagetex.model)
	worker_name.text = "Worker Name: " + str(imagetex.worker_name)
	worker_id.text = "Worker ID: " + str(imagetex.worker_id)

func _on_save_pressed() -> void:
	var save_dir_path : String = globals.config.get_value("Options", "default_save_dir", "user://")
	if img_2_img_enabled.pressed:
		focused_image.texture.set_source_image_path(image_preview.source_path)
	focused_image.texture.save_in_dir(save_dir_path)

func _on_save_all_pressed() -> void:
	var save_dir_path : String = globals.config.get_value("Options", "default_save_dir", "user://")
	for imgtex in grid.get_children():
		imgtex.texture.save_in_dir(save_dir_path)

func _on_request_failed(error_msg: String) -> void:
	status_text.text = error_msg
	status_text.modulate = Color(1,0.4,0.2)
	_reset_input()

func _on_request_warning(warning_msg: String) -> void:
	status_text.text = warning_msg
	status_text.modulate = Color(0.84,0.47,0)

func _check_html5() -> void:
	if OS.get_name() != "HTML5":
		return
	save.hide()
	save_all.hide()
#	save_dir.hide()
#	controls_right.hide()
	$"%SaveDirLabel".hide()
#	controls_right.remove_child(status_text)
#	controls_left.add_child(status_text)
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

func on_img2img_toggled(pressed: bool) -> void:
	for node in [denoising_strength,select_image,image_preview]:
		node.visible = pressed
	if not pressed:
		stable_horde_client.source_image = null

func on_image_select_pressed() -> void:
	var prev_path = globals.config.get_value("Options", "last_img2img_path", open_image.current_dir)
	if prev_path:
		open_image.current_dir = prev_path
	open_image.popup_centered(Vector2(500,500))

func _on_source_image_selected(path: String) -> void:
	globals.set_setting("last_img2img_path", open_image.current_dir, "Options")
	image_preview.load_image_from_path(path)
	stable_horde_client.source_image = image_preview.source_image

func _on_prompt_inject(tokens: Array) -> void:
	for token in tokens:
		if token in prompt_line_edit.text:
			continue
		prompt_line_edit.text += ', ' + token

func _on_NegativePrompt_toggled(pressed: bool) -> void:
	negative_prompt.pressed = pressed
	globals.set_setting("negative_prompt", negative_prompt.pressed, "Options")
	$"%NegPromptHBC".visible = pressed
	
func _on_PromptLine_text_changed(new_text: String) -> void:
	if '###' in new_text:
		var textsplit = new_text.split('###')
		_on_NegativePrompt_toggled(true)
		if negative_prompt_line_edit.text == '':
			negative_prompt_line_edit.text = textsplit[1]
		else:
			negative_prompt_line_edit.text += ', ' + textsplit[1]
		prompt_line_edit.text = textsplit[0]
		status_text.bbcode_text = "It appears you have enterred a negative prompt. Please use the negative prompt textbox"
		status_text.modulate = Color(1,1,0)

func _on_SamplerMethod_item_selected(index: int) -> void:
	# Adaptive doesn't have steps
	if sampler_method.get_item_text(index) == "k_dpm_adaptive":
		steps_slider.h_slider.editable = false
		steps_slider.config_value.text = '-'
	else:
		steps_slider.h_slider.editable = true
		steps_slider.config_value.text = str(steps_slider.h_slider.value)
	
func _connect_hover_signals() -> void:
	for node in [
		negative_prompt,
		amount,
		$"%ModelInfo",
		$"%ModelTrigger",
		$"%ModelSelect",
		trusted_workers,
		nsfw,
		censor_nsfw,
		save_all,
		width,
		height,
		steps_slider,
		config_slider,
		sampler_method,
		seed_edit,
		karras,
		denoising_strength,
		$"%PP",
		$"%RememberPrompt",
		$"%LargerValues",
		$"%Shared",
		aesthetic_rating,
		best_of,
		submit_ratings,
	]:
		node.connect("mouse_entered", EventBus, "_on_node_hovered", [node])
		node.connect("mouse_exited", EventBus, "_on_node_unhovered", [node])


func on_aethetic_rating_selected(index: int) -> void:
	var tr = get_active_image_tr()
	tr.aesthetic_rating = index
	set_submit_button_state()


func on_bestof_toggled(pressed: bool) -> void:
	# This is called even when we changed the value by code
	# So we don't want it unckecking all bestof when
	# we switch between images
	if not pressed:
		return
	for tr in grid.get_children():
		if tr.bestof and not tr.is_highlighted():
			tr.bestof = false
		if tr.is_highlighted():
			tr.bestof = pressed
	set_submit_button_state()


func get_active_image_tr() -> GridTextureRect:
	for tr in grid.get_children():
		if tr.is_highlighted():
			return tr
	return null


func has_any_ratings() -> bool:
	for tr in grid.get_children():
		if tr.bestof or tr.aesthetic_rating:
			return true
	return false

func set_submit_button_state() -> void:
	submit_ratings.disabled = !has_any_ratings()


func _on_shared_toggled() -> void:

	best_of.disabled = !globals.config.get_value("Options", "shared", true)
	aesthetic_rating.disabled = !globals.config.get_value("Options", "shared", true)
	submit_ratings.disabled = !globals.config.get_value("Options", "shared", true)
	if not has_any_ratings():
		submit_ratings.disabled = true


func _on_submit_ratings_pressed() -> void:
	var submit_dict := {}
	for tr in grid.get_children():
		if tr.bestof:
			submit_dict["best"] = tr.texture.image_horde_id
		if tr.aesthetic_rating:
			if not submit_dict.has("ratings"):
				submit_dict["ratings"] = []
			var rating_dict = {
				"id": tr.texture.image_horde_id,
				"rating": tr.aesthetic_rating
			}
			submit_dict.ratings.append(rating_dict)
	print_debug(submit_dict)
	stable_horde_rate_generation.submit_rating(
		stable_horde_client.async_request_id,
		submit_dict
	)

func _on_generation_rated(kudos: int) -> void:
#	print_debug(stats)
	status_text.modulate = Color(0,1,0)
	status_text.bbcode_text = "Thank for you rating your images. You have received a refund of {kudos} kudos.".format({"kudos":kudos})

func _on_generation_rating_failed(message: String) -> void:
	status_text.modulate = Color(1,1,0)
	status_text.bbcode_text = message
