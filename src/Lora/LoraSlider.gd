extends HBoxContainer

signal value_changed(value)

export(String) var slider_name :String = "LoraSlider"

onready var lora_slider_label = $"%LoraSliderLabel"
onready var lora_slider = $"%LoraSlider"
onready var lora_slider_value = $"%LoraSliderValue"

# Called when the node enters the scene tree for the first time.
func _ready():
	lora_slider_label.text = slider_name

func _on_LoraSliderValue_text_entered(new_text: String):
	if not new_text.is_valid_float():
		lora_slider_value.text = ''
	var new_value = float(new_text)
	if new_value > 2:
		new_value = 2
		lora_slider_value.text = '1'
	if new_value < -2:
		new_value = -2
		lora_slider_value.text = '0'
	lora_slider.value = new_value
	emit_signal("value_changed",int(new_text))

func _on_LoraSlider_value_changed(value):
	lora_slider_value.text = str(value)
	emit_signal("value_changed",value)

func set_value(value: float):
	lora_slider.value = value
	lora_slider_value.text = str(value)
