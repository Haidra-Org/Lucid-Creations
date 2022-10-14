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
		"max": 1024,
		"step": 64,
	},
	"height": {
		"label": "Height",
		"min": 64,
		"max": 1024,
		"step": 64,
	},
	"steps": {
		"label": "Sampling Steps",
		"min": 1,
		"max": 100,
		"step": 1,
	},
	"cfg_scale": {
		"label": "Classifier Free Guidance Scale (how strongly the image should follow the prompt)",
		"min": -40,
		"max": 30,
		"step": 0.5,
	},
}
onready var h_slider = $"%HSlider"
onready var config_name = $"%ConfigName"
onready var config_value = $"%ConfigValue"

export(String, "amount", "width", "height","steps", "cfg_scale") var config_setting := 'amount' setget set_config_name

func _ready():
	_adapt_to_config_name()

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
	# Can't use the onready names as they're not set in the editor
	$"%ConfigName".text = CONFIG[config_setting].label
	$"%HSlider".min_value = CONFIG[config_setting].min
	$"%HSlider".max_value = CONFIG[config_setting].max
	$"%HSlider".step = CONFIG[config_setting].step


func _on_HSlider_value_changed(value):
	config_value.text = str(value)
