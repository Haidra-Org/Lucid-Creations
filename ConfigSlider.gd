tool
class_name ConfigSlider
extends VBoxContainer

signal value_changed

# I can't figure out a way to use const as export variable hints. Therefore I have to duplicate the export hints in this const
const CONFIG := {
	"amount": {
		"label": "Number of images to generate",
		"min": 1,
		"max": 20,
		"step": 1,
	},
	"width": {
		"label": "Width",
		"min": 64,
		"max": 3072,
		"upfront_limit": 576,
		"step": 64,
	},
	"height": {
		"label": "Height",
		"min": 64,
		"max": 3072,
		"upfront_limit": 576,
		"step": 64,
	},
	"steps": {
		"label": "Sampling Steps",
		"min": 1,
		"max": 500,
		"upfront_limit": 50,
		"step": 1,
	},
	"cfg_scale": {
		"label": "Guidance",
		"min": 0,
		"max": 30,
		"step": 0.5,
	},
	"clip_skip": {
		"label": "Clip Skip",
		"min": 1,
		"max": 12,
		"step": 1,
	},
	"denoising_strength": {
		"label": "Denoising Strength (how strongly the image should follow the source image)",
		"min": 0,
		"max": 1,
		"step": 0.01,
	},
}
var upfront_limit = null
var stored_sister_slider = null
var generation_kudos = 0
onready var h_slider = $"%HSlider"
onready var config_name = $"%ConfigName"
onready var config_value = $"%ConfigValue"

export(String, "amount", "width", "height", "steps", "cfg_scale", "clip_skip", "denoising_strength") var config_setting := 'amount' setget set_config_name

func _ready():
	_adapt_to_config_name()
	# warning-ignore:return_value_discarded
	globals.connect("setting_changed", self, "_on_setting_changed")
	if config_setting == "width":
		# warning-ignore:return_value_discarded
		EventBus.connect("height_changed", self, "_on_wh_changed")
	if config_setting == "height":
		# warning-ignore:return_value_discarded
		EventBus.connect("width_changed", self, "_on_wh_changed")
	if config_setting in ["width", "height"]:
		# warning-ignore:return_value_discarded
		ParamBus.connect("models_changed",self,"_on_models_changed")
# warning-ignore:return_value_discarded
	EventBus.connect("kudos_calculated", self, "_on_kudos_calculated")
	ParamBus.connect("params_changed",self,"_on_params_changed")

func set_value(value) -> void:
	$"%HSlider".value = value
	$"%ConfigValue".text = str(value)

func set_max_value(max_value) -> void:
	if h_slider.value > max_value:
		$"%ConfigValue".text = str(max_value)
	$"%HSlider".max_value = max_value

func set_upfront_limit(_upfront_limit) -> void:
	upfront_limit = _upfront_limit
	if not globals.config.get_value("Options", "larger_values", false):
		$"%HSlider".max_value = upfront_limit

func reset_upfront_limit() -> void:
	if not CONFIG[config_setting].has('upfront_limit'):
		return
	upfront_limit = CONFIG[config_setting].upfront_limit
	if not globals.config.get_value("Options", "larger_values", false):
		$"%HSlider".max_value = upfront_limit

func reset_max_value() -> void:
	$"%HSlider".max_value = CONFIG[config_setting].max
	reset_upfront_limit()
	
func _on_HSlider_drag_ended(value_changed):
	if not value_changed:
		return
	emit_signal("value_changed")

func set_config_name(value) -> void:
	config_setting = value
	_adapt_to_config_name()
	
func _adapt_to_config_name() -> void:
	if Engine.editor_hint and get_child_count() == 0:
		return
	# WARNING: Can't use the onready names as they're not set in the editor
	$"%ConfigName".text = CONFIG[config_setting].label
	$"%HSlider".min_value = CONFIG[config_setting].min
	$"%HSlider".step = CONFIG[config_setting].step
	reset_max_value()

func _on_HSlider_value_changed(value):
	config_value.text = str(value)
	if config_setting == "width":
		EventBus.emit_signal("width_changed", self)
	elif config_setting == "height":
		EventBus.emit_signal("height_changed", self)
	else:
		_on_config_slider_changed()

func _on_setting_changed(setting_name):
	if setting_name == "larger_values" and CONFIG[config_setting].has('upfront_limit'):
		if globals.config.get_value("Options", "larger_values", false):
			$"%HSlider".max_value = CONFIG[config_setting].max
		else:
			$"%HSlider".max_value = CONFIG[config_setting].upfront_limit
		_on_params_changed()

# Only called for width/height changes
func _on_config_slider_changed() -> void:
	if upfront_limit != null and upfront_limit < h_slider.value and globals.user_kudos < generation_kudos:
		config_value.modulate = Color(1,0,0)
		$"%HSlider".modulate = Color(1,0,0)
	else:
		config_value.modulate = Color(1,1,1)
		$"%HSlider".modulate = Color(1,1,1)
		
# Only called for width/height changes
func _on_wh_changed(sister_slider) -> void:
	stored_sister_slider = sister_slider
	if not ParamBus.models_node:
		return
	var baselines = ParamBus.models_node.get_all_baselines()
	if "stable diffusion 1" in baselines:
		upfront_limit = 576
	if "stable diffusion 2" in baselines:
		upfront_limit = 768
	if "stable_diffusion_xl" in baselines:
		upfront_limit = 1024
	if not globals.config.get_value("Options", "larger_values", false):
		$"%HSlider".max_value = upfront_limit
		if int(config_value.text) > upfront_limit:
			config_value.text = str(upfront_limit)
	if sister_slider.h_slider.value * h_slider.value > upfront_limit * upfront_limit and globals.user_kudos < generation_kudos:
		for n in [sister_slider, self]:
			n.config_value.modulate = Color(1,0,0)
			n.h_slider.modulate = Color(1,0,0)
	else:
		for n in [sister_slider, self]:
			n.config_value.modulate = Color(1,1,1)
			n.h_slider.modulate = Color(1,1,1)


func _on_models_changed(_models) -> void:
	if not stored_sister_slider:
		return
	_on_wh_changed(stored_sister_slider)

func _on_kudos_calculated(kudos) -> void:
	generation_kudos = kudos
	if config_setting in ["width", "height"]:
		_on_wh_changed(stored_sister_slider)
	else:
		_on_config_slider_changed()

func _on_params_changed() -> void:
	if config_setting == "steps":
		if ParamBus.has_controlnet() or ParamBus.is_lcm_payload():
			if ParamBus.is_lcm_payload():
				# Protect the user a bit during switching to LCM
				if h_slider.value > 40:
					h_slider.value = 8
				set_upfront_limit(10)
			else:
				reset_upfront_limit()
				if h_slider.value > 40:
					h_slider.value = 20
			set_max_value(40)
		else:
			reset_max_value()
	if config_setting == "cfg_scale":
		if ParamBus.is_lcm_payload():
			# Protect the user a bit
			if h_slider.value > 4:
				h_slider.value = 2
			set_max_value(4)
		else:
			reset_max_value()
	
