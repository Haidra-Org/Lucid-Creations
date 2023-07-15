extends StableHordeClient

var kudos : float = 0
var countdown_timer : float = 0

func _ready():
	ParamBus.connect("params_changed",self,"_on_params_changed")

func _process(delta):
	if countdown_timer > 0:
		countdown_timer -= delta
		if countdown_timer <= 0:
			_init_calculate_kudos()

func _on_params_changed() -> void:
	countdown_timer = 2

func _init_calculate_kudos() -> void:
	prompt = ParamBus.get_prompt()
	
	
	EventBus.emit_signal("kudos_calculated",kudos)
#	prompt_node = _prompt_node
#	amount_node = _amount_node
#	width_node = _width_node
#	height_node = _height_node
#	steps_node = _steps_node
#	sampler_name_node = _sampler_name_node
#	cfg_scale_node = _cfg_scale_node
#	denoising_strength_node = _denoising_strength_node
#	gen_seed_node = _gen_seed_node
#	post_processing_node = _post_processing_node
#	karras_node = _karras_node
#	hires_fix_node = _hires_fix_node
#	nsfw_node = _nsfw_node
#	censor_nsfw_node = _censor_nsfw_node
#	trusted_workers_node = _trusted_workers_node
#	models_node = _models_node
#	source_image_node = _source_image_node
#	img2img_node = _img2img_node
#	shared_node = _shared_node
#	control_type_node = _control_type_node
#	loras_node = _loras_node
