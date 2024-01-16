extends Control

const GRID_TEXTURE_RECT = preload("res://GridTextureRect.tscn")
var placeholder_prompts := [
	"Surface photo of planet made of cheese, space background",
	"A legion of cute monster toys",
	"giant magical gemstone, crystal, magical, colorful, fantasy ore, high detail, illustration, bright lighting, glow, wide focus, rough, raw, gem, octane render, valuables, 3d, galaxy, pretty, reflection, smooth, glass, mana ### haze, fog, text, watermark, bloom, fuzz, blur",
	"professional portrait render head shot of a simplified minimalist cute synthwave panda, looking sideways, happy, side profile, covered in blue pink fur, teal body, photorealist, perfect cuddly panda face, perfect panda eyes, in colored smoke, dark purple studio background, volumetric lighting, ultra-hd, intricate, stunning anime painting, dof",
	"Psychedelic Surreal victorian landscape art, dark shadows, muted colors, intricate brush strokes, masterpiece oil painting, intricate brush strokes, muted colour palette, hard lighting, dark, eerie",
	"photorealistic rendering of a vast landscape, vivid colors, fantasy landscape",
	"Rainbow jellyfish on a a deep colorful ocean, reef coral, concept art by senior character artist, cgsociety, plasticien, unreal engine 5, artstation, hd, concept art, an ambient occlusion render by Raphael, featured on zbrush central, photorealism, reimagined by industrial light and magic, rendered in maya, rendered in cinema4d !!!!Centered composition!!!###bad art, strange colors, sketch ,lacklustre, repetitive, lowres, deformed, old, childish",
	"tiny cute isometric Livingroom, soft smooth lighting, soft colors, dark color scheme, soft colors, 100mm, 3d blender render, octane render, global illumination, sharp focus in the middle###blurry, bad, text",
]

onready var options = $"%Options"
onready var stable_horde_client := $"%StableHordeClient"
onready var kudos_cost := $"%KudosCost"
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
onready var clip_skip_slider := $"%ClipSkipSlider"
onready var steps_slider := $"%StepsSlider"
onready var generate_button := $"%GenerateButton"
onready var sampler_method : OptionButton = $"%SamplerMethod"
onready var karras := $"%Karras"
onready var hires_fix = $"%HiResFix"
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
onready var load_from_disk = $"%LoadFromDisk"
onready var status_text = $"%StatusText"
onready var kudos_text = $"%KudosText"
onready var controls_basic := $"%Basic"
onready var control_advanced := $"%Advanced"
onready var generations_processing = $"%GenerationsProcessing"
onready var generations_done = $"%GenerationsDone"
onready var cancel_button = $"%CancelButton"
# Prompts
onready var _tween = $"%Tween"
onready var prompt_cc = $"%PromptCC"
onready var progress_text = $"%ProgressText"
onready var prompt_cover = $"%PromptCover"
onready var negative_prompt = $"%NegativePrompt"
onready var neg_prompt_hbc = $"%NegPromptHBC"
## 
onready var nsfw = $"%NSFW"
onready var censor_nsfw = $"%CensorNSFW"
onready var trusted_workers = $"%TrustedWorkers"
onready var controls = $"%Controls"
# img2img
onready var img_2_img_enabled = $"%Img2ImgEnabled"
onready var denoising_strength = $"%DenoisingStrength"
onready var select_image = $"%SelectImage"
onready var image_preview = $"%ImagePreview"
onready var control_net = $"%ControlNet"
onready var control_type = $"%ControlType"
onready var image_is_control = $"%ImageIsControl"
# model
onready var model = $"%Model"
onready var lora:LoraSelection = $"%Lora"
onready var ti:TISelection = $"%TextualInversions"
onready var workers: WorkerSelection = $"%WorkersVBC"
# post-processing
onready var pp = $"%PP"
# ratings
onready var aesthetic_rating = $"%AestheticRating"
onready var artifacts_rating = $"%ArtifactsRating"
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
	select_image.connect("image_selected",self,"_on_source_image_selected")
	# warning-ignore:return_value_discarded
	EventBus.connect("kudos_calculated",self, "_on_kudos_calculated")
	EventBus.connect("cache_wipe_requested",self, "_on_cache_wipe_requested")
	stable_horde_client.client_agent = "Lucid Creations:" + ToolConsts.VERSION + ":(discord)db0#1625"
	stable_horde_client.aihorde_url = globals.aihorde_url

	_connect_hover_signals()
	# warning-ignore:return_value_discarded
	save.connect("pressed", self, "_on_save_pressed")
	# warning-ignore:return_value_discarded
	save_all.connect("pressed", self, "_on_save_all_pressed")
	load_from_disk.connect("gensettings_loaded", self, "_on_load_from_disk_gensettings_loaded")
	# warning-ignore:return_value_discarded
	generate_button.connect("pressed",self,"_on_GenerateButton_pressed")
	# warning-ignore:return_value_discarded
	cancel_button.connect("pressed",self,"_on_CancelButton_pressed")
	# warning-ignore:return_value_discarded
	model.connect("prompt_inject_requested",self,"_on_prompt_inject")
	# warning-ignore:return_value_discarded
	lora.connect("prompt_inject_requested",self,"_on_prompt_inject")
	# warning-ignore:return_value_discarded
	ti.connect("prompt_inject_requested",self,"_on_prompt_inject")
	# Ratings
	# warning-ignore:return_value_discarded
	EventBus.connect("shared_toggled", self, "_on_shared_toggled")
	# warning-ignore:return_value_discarded
	best_of.connect("toggled",self,"on_bestof_toggled")
	# warning-ignore:return_value_discarded
	aesthetic_rating.connect("item_selected",self,"on_aethetic_rating_selected")
	# warning-ignore:return_value_discarded
	artifacts_rating.connect("item_selected",self,"on_artifacts_rating_selected")
	# warning-ignore:return_value_discarded
	submit_ratings.connect("pressed", self, "_on_submit_ratings_pressed")
	# warning-ignore:return_value_discarded
	stable_horde_rate_generation.connect("generation_rated",self, "_on_generation_rated")
	# warning-ignore:return_value_discarded
	stable_horde_rate_generation.connect("request_failed",self, "_on_generation_rating_failed")
	nsfw.connect("toggled", self,"_on_nsfw_toggled")
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
	hires_fix.pressed = stable_horde_client.hires_fix
	negative_prompt.pressed = globals.config.get_value("Options", "negative_prompt", false)
	nsfw.pressed = stable_horde_client.nsfw
	censor_nsfw.pressed = stable_horde_client.censor_nsfw
	var sampler_method_id = stable_horde_client.get_sampler_method_id()
	sampler_method.select(sampler_method_id)
	_on_SamplerMethod_item_selected(sampler_method_id)
	var control_type_id = stable_horde_client.get_control_type_id()
	control_type.select(control_type_id)
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
	if prompt_line_edit.text == '':
		prompt_line_edit.text = _get_random_placeholder_prompt()
	ParamBus.setup(
		options.api_key,
		prompt_line_edit,
		negative_prompt_line_edit,
		amount,
		steps_slider,
		width,
		height,
		sampler_method,
		config_slider,
		clip_skip_slider,
		denoising_strength,
		seed_edit,
		pp,
		karras,
		hires_fix,
		nsfw,
		censor_nsfw,
		trusted_workers,
		model,
		img_2_img_enabled,
		image_preview,
		options.shared,
		control_type,
		lora,
		ti
	)
#	_models_node: ModelSelection,
#	_img2img_node: CheckButton,
#	_source_image_node: TextureRect,
#	_shared_node: CheckButton,
#	_control_type_node: OptionButton,
#	_loras_node: LoraSelection


#	var tween2 = create_tween()
#	print_debug(tween2)
#	var t = tween2.tween_property(generations_processing, "value", 15, 2)
#	print_debug(t)

func _get_random_placeholder_prompt() -> String:
	var rand_index : int = randi() % placeholder_prompts.size()
	return placeholder_prompts[rand_index]	

func _on_GenerateButton_pressed():
	status_text.text = ''
	_accept_settings()
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
	prompt_cc.collapse()
	neg_prompt_hbc.collapse()
	stable_horde_client.generate()
	globals.set_setting("saved_prompt", prompt_line_edit.text, "Options")
	globals.set_setting("saved_negative_prompt", negative_prompt_line_edit.text, "Options")


func _on_CancelButton_pressed():
	progress_text.text = "Cancelling request..."
	stable_horde_client.cancel_request()

func _on_images_generated(completed_payload: Dictionary):
	_reset_input()
	save_all.disabled = false
	status_text.bbcode_text = "[color=green]Your images are ready![/color]"
#		+ "[color=yellow]Remember to rate them to receive a kudos refund![/color]"
	status_text.modulate = Color(1,1,1)
	for texture in completed_payload["image_textures"]:
		var tr := GRID_TEXTURE_RECT.instance()
		tr.set_texture(texture)
		# warning-ignore:return_value_discarded
		tr.connect("left_mouse_mouse_clicked", self, "_on_grid_texture_left_clicked", [tr])
#		tr.connect("right_mouse_mouse_clicked", self, "_on_grid_texture_right_clicked", [tr])
		grid.add_child(tr)
	EventBus.emit_signal("generation_completed")

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
		status_text.bbcode_text = "Thank you for using the AI Horde! "\
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
			OS.shell_open("https://github.com/Haidra-Org/AI-Horde/blob/main/README_StableHorde.md#joining-the-horde")

func _on_ControlNet_meta_clicked(meta):
	match meta:
		"cn_url":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://bootcamp.uxdesign.cc/controlnet-and-stable-diffusion-a-game-changer-for-ai-image-generation-83555cb942fc")


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
			"none",
			img,
			'Test Image ID',
			"Test Request ID",
			[])
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
	if tr.artifacts_rating == null:
		artifacts_rating.select(0)
	else:
		artifacts_rating.select(tr.artifacts_rating + 1)

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
	for node in [denoising_strength,select_image,image_preview,control_net,control_type]:
		node.visible = pressed

func _on_source_image_selected(path: String) -> void:
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
	
func _on_PromptLine_text_changed() -> void:
	var new_text = prompt_line_edit.text
	if _set_prompt(new_text):
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
		$"%ModelSelect",
		trusted_workers,
		nsfw,
		censor_nsfw,
		save_all,
		width,
		height,
		steps_slider,
		config_slider,
		clip_skip_slider,
		sampler_method,
		seed_edit,
		karras,
		hires_fix,
		denoising_strength,
		$"%PP",
		$"%RememberPrompt",
		$"%LargerValues",
		$"%LoadSeedFromDisk",
		$"%Shared",
		aesthetic_rating,
		artifacts_rating,
		best_of,
		submit_ratings,
		control_type,
		image_is_control,
		$"%FetchFromCivitAI",
		$"%ShowAllModels",
		$"%ShowAllLoras",
		$"%FetchTIsFromCivitAI",
		$"%ShowAllTIs",
		$"%WipeCache",
		$"%BlockList",
		$"%WorkerAutoComplete",
		$"%ShowAllWorkers",
	]:
		node.connect("mouse_entered", EventBus, "_on_node_hovered", [node])
		node.connect("mouse_exited", EventBus, "_on_node_unhovered", [node])


func on_aethetic_rating_selected(index: int) -> void:
	var tr = get_active_image_tr()
	tr.aesthetic_rating = index
	set_submit_button_state()


func on_artifacts_rating_selected(index: int) -> void:
	var tr = get_active_image_tr()
	if index == 0:
		tr.artifacts_rating = null
	else:
		tr.artifacts_rating = index - 1
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
	artifacts_rating.disabled = !globals.config.get_value("Options", "shared", true)
	submit_ratings.disabled = !globals.config.get_value("Options", "shared", true)
	if not has_any_ratings():
		submit_ratings.disabled = true


func _on_submit_ratings_pressed() -> void:
#	submit_ratings.disabled = true
	var submit_dict := {}
	for tr in grid.get_children():
		if tr.bestof:
			submit_dict["best"] = tr.texture.image_horde_id
		if tr.aesthetic_rating:
			if not submit_dict.has("ratings"):
				submit_dict["ratings"] = []
			var rating_dict = {
				"id": tr.texture.image_horde_id,
				"rating": tr.aesthetic_rating,
			}
			if tr.artifacts_rating != null:
				rating_dict["artifacts"] = tr.artifacts_rating
			submit_dict.ratings.append(rating_dict)
#	print_debug(submit_dict)
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
	submit_ratings.disabled = true

func _on_nsfw_toggled(button_pressed: bool) -> void:
	lora.lora_reference_node.nsfw = button_pressed
	ti.ti_reference_node.nsfw = button_pressed
	lora.update_selected_loras_label()
	ti.update_selected_tis_label()

func _accept_settings() -> void:
	for slider_config in [
		width,
		height,
		config_slider,
		steps_slider,
		amount,
		denoising_strength,
		clip_skip_slider
	]:
		stable_horde_client.set(slider_config.config_setting, slider_config.h_slider.value)
		globals.set_setting(slider_config.config_setting, slider_config.h_slider.value)
	var sampler_name = sampler_method.get_item_text(sampler_method.selected)
	stable_horde_client.set("sampler_name", sampler_name)
	globals.set_setting("sampler_name", sampler_name)
	var models = model.selected_models_list
	stable_horde_client.set("models", models)
	globals.set_setting("models", models)
	if "SDXL_beta::stability.ai#6901" in models:
		globals.set_setting("shared", true, "Options")
		EventBus.emit_signal("shared_toggled")
	else:
		globals.set_setting("shared", false, "Options")
		EventBus.emit_signal("shared_toggled")
	var loras = lora.selected_loras_list
	globals.set_setting("loras",loras)
	stable_horde_client.set("lora", loras)
	var tis = ti.selected_tis_list
	globals.set_setting("tis",tis)
	stable_horde_client.set("tis", tis)
	var wks = workers.get_worker_ids()
	globals.set_setting("workers", workers.selected_workers_list, "Options")
	globals.set_setting("blocklist", workers.blocklist, "Options")
	stable_horde_client.set("workers", wks)
	stable_horde_client.set("worker_blacklist", workers.blocklist)
	stable_horde_client.set("api_key", options.get_api_key())
	stable_horde_client.set("karras", karras.pressed)
	globals.set_setting("karras", karras.pressed)
	stable_horde_client.set("hires_fix", hires_fix.pressed)
	globals.set_setting("hires_fix", hires_fix.pressed)
	stable_horde_client.set("nsfw", nsfw.pressed)
	globals.set_setting("nsfw", nsfw.pressed)
	stable_horde_client.set("censor_nsfw", censor_nsfw.pressed)
	globals.set_setting("censor_nsfw", censor_nsfw.pressed)
	stable_horde_client.set("trusted_workers", trusted_workers.pressed)
	globals.set_setting("trusted_workers", trusted_workers.pressed)
	stable_horde_client.set("shared", globals.config.get_value("Options", "share", true))
	stable_horde_client.set("gen_seed", seed_edit.text)
	stable_horde_client.set("post_processing", globals.config.get_value("Parameters", "post_processing", stable_horde_client.post_processing))
	stable_horde_client.set("lora", globals.config.get_value("Parameters", "loras", stable_horde_client.lora))
	stable_horde_client.set("tis", globals.config.get_value("Parameters", "tis", stable_horde_client.tis))
	if prompt_line_edit.text == '':
		prompt_line_edit.text = _get_random_placeholder_prompt()
	stable_horde_client.prompt = prompt_line_edit.text
	if globals.config.get_value("Options", "negative_prompt", false) and negative_prompt_line_edit.text != '':
		stable_horde_client.prompt += '###' + negative_prompt_line_edit.text
	if img_2_img_enabled.pressed:
		stable_horde_client.source_image = image_preview.source_image
		var cn_name = control_type.get_item_text(control_type.selected)
		stable_horde_client.set("control_type", cn_name)
		globals.set_setting("control_type", cn_name)
	else:
		stable_horde_client.source_image = null
		stable_horde_client.control_type = "none"
		globals.set_setting("control_type", "none")

func _on_load_from_disk_gensettings_loaded(settings) -> void:
	width.set_value(settings["width"])
	height.set_value(settings["height"])
	steps_slider.set_value(settings["steps"])
	config_slider.set_value(settings["cfg_scale"])
	for idx in range(sampler_method.get_item_count()):
		if sampler_method.get_item_text(idx) == settings["sampler_name"]:
			sampler_method.select(idx)
	karras.pressed = settings.get("karras", true)
	hires_fix.pressed = settings.get("hires_fix", false)
	if globals.config.get_value("Options", "load_seed_from_disk", false):
		seed_edit.text = settings["seed"]
	if _set_prompt(settings["prompt"], true) == false:
		negative_prompt_line_edit.text = ''
	pp.replace_pp(settings["post_processing"])
	model.replace_models([settings["model"]])
	if settings.has("loras"):
		lora.replace_loras(settings["loras"])
	else:
		lora.replace_loras([])
	if settings.has("tis"):
		ti.replace_tis(settings["tis"])
	else:
		ti.replace_tis([])
	denoising_strength.set_value(settings.get("denoising_strength", 0.7))
	if settings.has("control_type"):
		for idx in range(control_type.get_item_count()):
			if control_type.get_item_text(idx) == settings["control_type"]:
				control_type.select(idx)
	if settings.has("source_image_path"):
		if image_preview.load_image_from_path(settings["source_image_path"]):
			stable_horde_client.source_image = image_preview.source_image
			on_img2img_toggled(true)
			img_2_img_enabled.pressed = true
	else:
		on_img2img_toggled(false)
		img_2_img_enabled.pressed = false
		stable_horde_client.source_image = null
		stable_horde_client.control_type = "none"

func _set_prompt(prompt: String, force = false) -> bool:
	"""Sets prompt and negative prompt
	Returns true if there's negative text
	else returns false
	"""
	if not '###' in prompt:
		if force: 
			prompt_line_edit.text = prompt
		return false
	var textsplit = prompt.split('###')
	_on_NegativePrompt_toggled(true)
	if negative_prompt_line_edit.text == '' or force:
		negative_prompt_line_edit.text = textsplit[1]
	else:
		negative_prompt_line_edit.text += ', ' + textsplit[1]
	prompt_line_edit.text = textsplit[0]
	return true

func _on_kudos_calculated(kudos: int) -> void:
	var fmt = {
		"color": "white",
		"kudos": str(kudos)
	}
	if kudos > options.stable_horde_login.get_kudos():
		fmt["color"] = "#FFA500"
	kudos_text.bbcode_text = "[color={color}]Kudos: {kudos}[/color]".format(fmt)

func _on_cache_wipe_requested() -> void:
	status_text.text = 'CivitAI Caches Wiped'
