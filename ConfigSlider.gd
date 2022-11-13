tool
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
		"min": -40,
		"max": 30,
		"step": 0.5,
	},
	"denoising_strength": {
		"label": "Denoising Strength (how strongly the image should follow the source image)",
		"min": 0,
		"max": 1,
		"step": 0.01,
	},
}
var upfront_limit = null
onready var h_slider = $"%HSlider"
onready var config_name = $"%ConfigName"
onready var config_value = $"%ConfigValue"

export(String, "amount", "width", "height", "steps", "cfg_scale", "denoising_strength") var config_setting := 'amount' setget set_config_name

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

func set_value(value) -> void:
	$"%HSlider".value = value
	$"%ConfigValue".text = str(value)

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
	$"%HSlider".max_value = CONFIG[config_setting].max
	$"%HSlider".step = CONFIG[config_setting].step
	if CONFIG[config_setting].has('upfront_limit'):
		upfront_limit = CONFIG[config_setting].upfront_limit
		if not globals.config.get_value("Options", "larger_values", false):
			$"%HSlider".max_value = CONFIG[config_setting].upfront_limit


func _on_HSlider_value_changed(value):
	config_value.text = str(value)
	if config_setting == "width":
		EventBus.emit_signal("width_changed", self)
	elif config_setting == "height":
		EventBus.emit_signal("height_changed", self)
	elif upfront_limit != null and upfront_limit < value:
		config_value.modulate = Color(1,0,0)
		h_slider.modulate = Color(1,0,0)
	else:
		config_value.modulate = Color(1,1,1)
		h_slider.modulate = Color(1,1,1)

func _on_setting_changed(setting_name):
	if setting_name == "larger_values" and CONFIG[config_setting].has('upfront_limit'):
		if globals.config.get_value("Options", "larger_values", false):
			h_slider.max_value = CONFIG[config_setting].max
		else:
			h_slider.max_value = CONFIG[config_setting].upfront_limit
			

func _on_wh_changed(sister_slider):
	if sister_slider.h_slider.value * h_slider.value > upfront_limit * upfront_limit:
		for n in [sister_slider, self]:
			n.config_value.modulate = Color(1,0,0)
			n.h_slider.modulate = Color(1,0,0)
	else:
		for n in [sister_slider, self]:
			n.config_value.modulate = Color(1,1,1)
			n.h_slider.modulate = Color(1,1,1)
		
