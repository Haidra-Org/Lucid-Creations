extends StableHordeClient

var kudos : float = 0
var countdown_timer : float = 0

func _ready():
	# warning-ignore:return_value_discarded
	ParamBus.connect("params_changed",self,"_on_params_changed")
	# warning-ignore:return_value_discarded
	connect("kudos_calculated", self, "_on_kudos_calculated")
	dry_run = true

func _process(delta):
	if countdown_timer > 0:
		countdown_timer -= delta
		if countdown_timer <= 0:
			_init_calculate_kudos()

func _on_params_changed() -> void:
	if state == States.READY:
		countdown_timer = 0.5

func _init_calculate_kudos() -> void:
	api_key = ParamBus.get_api_key()
	prompt = ParamBus.get_prompt()
	amount = ParamBus.get_amount()
	width = ParamBus.get_width()
	height = ParamBus.get_height()
	steps = ParamBus.get_steps()
	sampler_name = ParamBus.get_sampler_name()
	cfg_scale = ParamBus.get_cfg_scale()
	denoising_strength = ParamBus.get_denoising_strength()
	gen_seed = ParamBus.get_gen_seed()
	post_processing = ParamBus.get_post_processing()
	karras = ParamBus.get_karras()
	hires_fix = ParamBus.get_hires_fix()
	nsfw = ParamBus.get_nsfw()
	censor_nsfw = ParamBus.get_censor_nsfw()
	trusted_workers = ParamBus.get_trusted_workers()
	models = ParamBus.get_models()
	source_image = ParamBus.get_source_image()
	shared = ParamBus.get_shared()
	control_type = ParamBus.get_control_type()
	lora = ParamBus.get_loras()
	tis = ParamBus.get_tis()
	generate()

func _on_kudos_calculated(kudos_payload: Dictionary) -> void:
	EventBus.emit_signal("kudos_calculated", kudos_payload["kudos"])
