extends Node

# warning-ignore:unused_signal
signal params_changed
# warning-ignore:unused_signal
signal api_key_changed(text)
# warning-ignore:unused_signal
signal prompt_changed(text)
# warning-ignore:unused_signal
signal amount_changed(number)
# warning-ignore:unused_signal
signal width_changed(number)
# warning-ignore:unused_signal
signal height_changed(number)
# warning-ignore:unused_signal
signal steps_changed(number)
# warning-ignore:unused_signal
signal sampler_name_changed(text)
# warning-ignore:unused_signal
signal cfg_scale_changed(number)
# warning-ignore:unused_signal
signal denoising_strength_changed(number)
# warning-ignore:unused_signal
signal gen_seed_changed(text)
# warning-ignore:unused_signal
signal post_processing_changed(list)
# warning-ignore:unused_signal
signal karras_changed(boolean)
# warning-ignore:unused_signal
signal hires_fix_changed(boolean)
# warning-ignore:unused_signal
signal nsfw_changed(boolean)
# warning-ignore:unused_signal
signal censor_nsfw_changed(boolean)
# warning-ignore:unused_signal
signal trusted_workers_changed(boolean)
# warning-ignore:unused_signal
signal models_changed(list)
# warning-ignore:unused_signal
signal source_image_changed(image)
# warning-ignore:unused_signal
signal shared_changed(boolean)
# warning-ignore:unused_signal
signal control_type_changed(text)
# warning-ignore:unused_signal
signal loras_changed(list)
# warning-ignore:unused_signal
signal tis_changed(list)
# warning-ignore:unused_signal
signal img2img_changed(source_image)


var api_key_node: LineEdit
var prompt_node: TextEdit
var negprompt_node: TextEdit
var amount_node: ConfigSlider
var width_node: ConfigSlider
var height_node: ConfigSlider
var steps_node: ConfigSlider
var sampler_name_node: OptionButton
var cfg_scale_node: ConfigSlider
var clip_skip_node: ConfigSlider
var denoising_strength_node: ConfigSlider
var gen_seed_node: LineEdit
var post_processing_node: PostProcessingSelection
var karras_node: CheckButton
var hires_fix_node: CheckButton
var nsfw_node: CheckButton
var censor_nsfw_node: CheckButton
var trusted_workers_node: CheckButton
var models_node: ModelSelection
var img2img_node: CheckButton
var source_image_node: TextureRect
var shared_node: CheckButton
var control_type_node: OptionButton
var loras_node: LoraSelection
var tis_node: TISelection

func setup(
	_api_key_node: LineEdit,
	_prompt_node: TextEdit,
	_negprompt_node: TextEdit,
	_amount_node: ConfigSlider,
	_steps_node: ConfigSlider,
	_width_node: ConfigSlider,
	_height_node: ConfigSlider,
	_sampler_name_node: OptionButton,
	_cfg_scale_node: ConfigSlider,
	_clip_skip_node: ConfigSlider,
	_denoising_strength_node: ConfigSlider,
	_gen_seed_node: LineEdit,
	_post_processing_node: PostProcessingSelection,
	_karras_node: CheckButton,
	_hires_fix_node: CheckButton,
	_nsfw_node: CheckButton,
	_censor_nsfw_node: CheckButton,
	_trusted_workers_node: CheckButton,
	_models_node: ModelSelection,
	_img2img_node: CheckButton,
	_source_image_node: TextureRect,
	_shared_node: CheckButton,
	_control_type_node: OptionButton,
	_loras_node: LoraSelection,
	_tis_node: TISelection
) -> void:
	api_key_node = _api_key_node
	prompt_node = _prompt_node
	negprompt_node = _negprompt_node
	amount_node = _amount_node
	width_node = _width_node
	height_node = _height_node
	steps_node = _steps_node
	sampler_name_node = _sampler_name_node
	cfg_scale_node = _cfg_scale_node
	clip_skip_node = _clip_skip_node
	denoising_strength_node = _denoising_strength_node
	gen_seed_node = _gen_seed_node
	post_processing_node = _post_processing_node
	karras_node = _karras_node
	hires_fix_node = _hires_fix_node
	nsfw_node = _nsfw_node
	censor_nsfw_node = _censor_nsfw_node
	trusted_workers_node = _trusted_workers_node
	models_node = _models_node
	source_image_node = _source_image_node
	img2img_node = _img2img_node
	shared_node = _shared_node
	control_type_node = _control_type_node
	loras_node = _loras_node
	tis_node = _tis_node
	for le_node in [prompt_node, negprompt_node, gen_seed_node, api_key_node]:
		# warning-ignore:return_value_discarded
		le_node.connect("text_changed", self, "_on_line_edit_changed", [le_node])
	for slider in [
		amount_node,
		width_node,
		height_node,
		steps_node,
		cfg_scale_node,
		clip_skip_node,
		denoising_strength_node
	]:
		# warning-ignore:return_value_discarded
		slider.connect("value_changed", self, "_on_hslider_changed", [slider])
	for cbutton in [
		karras_node,
		hires_fix_node,
		nsfw_node,
		censor_nsfw_node,
		trusted_workers_node,
		img2img_node,
		shared_node
	]:
		cbutton.connect("pressed", self, "_on_cbutton_changed", [cbutton])
	# warning-ignore:return_value_discarded
	post_processing_node.connect("pp_modified",self,"_on_listnode_changed", [post_processing_node])
	# warning-ignore:return_value_discarded
	models_node.connect("model_modified",self,"_on_listnode_changed", [models_node])
	# warning-ignore:return_value_discarded
	loras_node.connect("loras_modified",self,"_on_listnode_changed", [loras_node])
	tis_node.connect("tis_modified",self,"_on_listnode_changed", [tis_node])
	for obutton in [
		control_type_node,
		sampler_name_node,
	]:
		obutton.connect("item_selected",self,"_on_option_changed", [obutton])
	

func get_prompt() -> String:
	if negprompt_node.text == '':
		return prompt_node.text
	else:
		return prompt_node.text + "###" + negprompt_node.text

func get_api_key() -> String:
	return api_key_node.text

func get_amount() -> int:
	return amount_node.h_slider.value

func get_width() -> int:
	return width_node.h_slider.value

func get_height() -> int:
	return height_node.h_slider.value

func get_steps() -> int:
	return steps_node.h_slider.value

func get_sampler_name() -> String:
	return sampler_name_node.get_item_text(sampler_name_node.selected)

func get_cfg_scale() -> float:
	return cfg_scale_node.h_slider.value

func get_clip_skip() -> float:
	return clip_skip_node.h_slider.value

func get_denoising_strength() -> float:
	return denoising_strength_node.h_slider.value

func get_gen_seed() -> String:
	return gen_seed_node.text

func get_post_processing() -> Array:
	return post_processing_node.selected_pp

func get_karras() -> bool:
	return karras_node.pressed

func get_hires_fix() -> bool:
	return hires_fix_node.pressed

func get_nsfw() -> bool:
	return nsfw_node.pressed

func get_censor_nsfw() -> bool:
	return censor_nsfw_node.pressed

func get_trusted_workers() -> bool:
	return trusted_workers_node.pressed

func get_models() -> Array:
	return models_node.selected_models_list

func get_source_image() -> Image:
	if img2img_node.pressed:
		return source_image_node.source_image
	return null

func get_shared() -> bool:
	return shared_node.pressed

func get_control_type() -> String:
	if img2img_node.pressed:
		return control_type_node.get_item_text(control_type_node.selected)
	return "none"

func get_loras() -> Array:
	return loras_node.selected_loras_list

func get_tis() -> Array:
	return tis_node.selected_tis_list

func _on_line_edit_changed(line_edit_node) -> void:
	match line_edit_node:
		prompt_node, negprompt_node:
			emit_signal("prompt_changed", get_prompt())
		gen_seed_node:
			emit_signal("gen_seed_changed", get_gen_seed())
	emit_signal("params_changed")

func _on_hslider_changed(hslider: ConfigSlider) -> void:
	match hslider:
		amount_node:
			emit_signal("amount_changed", get_amount())
		width_node:
			emit_signal("width_changed", get_width())
		height_node:
			emit_signal("height_changed", get_height())
		steps_node:
			emit_signal("steps_changed", get_steps())
		cfg_scale_node:
			emit_signal("cfg_scale_changed", get_cfg_scale())
		denoising_strength_node:
			emit_signal("denoising_strength_changed", get_denoising_strength())
	emit_signal("params_changed")

func _on_option_changed(_index: int, option_button: OptionButton) -> void:
	match option_button:
		sampler_name_node:
			emit_signal("sampler_name_changed")
		control_type_node:
			emit_signal("control_type_changed")
	emit_signal("params_changed")

func _on_cbutton_changed(cbutton: CheckButton) -> void:
	match cbutton:
		karras_node:
			emit_signal("karras_changed", get_karras())
		hires_fix_node:
			emit_signal("hires_fix_changed", get_hires_fix())
		nsfw_node:
			emit_signal("nsfwt_changed", get_nsfw())
		censor_nsfw_node:
			emit_signal("censor_nsfw_changed", get_censor_nsfw())
		trusted_workers_node:
			emit_signal("trusted_workers_changed", get_trusted_workers())
		img2img_node:
			emit_signal("img2img_changed", get_source_image())
		shared_node:
			emit_signal("shared_changed", get_shared())
	emit_signal("params_changed")

func _on_listnode_changed(_thing_list: Array, thing_node: Node) -> void:
	match thing_node:
		post_processing_node:
			emit_signal("post_processing_changed", get_post_processing())
		models_node:
			emit_signal("models_changed", get_models())
		loras_node:
			emit_signal("loras_changed", get_loras())
		tis_node:
			emit_signal("tis_changed", get_tis())
	emit_signal("params_changed")

func is_lcm_payload() -> bool:
	if loras_node.has_lcm_loras():
		return true
	if sampler_name_node.get_item_text(sampler_name_node.selected) == 'lcm':
		return true
	return false

func is_sdxl_payload() -> bool:
	return models_node.get_all_baselines().has("stable_diffusion_xl")

func has_controlnet() -> bool:
	if not img2img_node.pressed:
		return false
	return control_type_node.selected == 0
