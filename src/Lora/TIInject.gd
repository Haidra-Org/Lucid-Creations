extends HBoxContainer

signal value_changed(value)

onready var ti_inject_button := $"%TIInjectButton"
onready var ti_inject_label = $"%TIInjectLabel"

func _ready():
	var popup = ti_inject_button.get_popup()
	popup.connect("index_pressed", self, "on_index_pressed")

func on_index_pressed(index) -> void:
	match index:
		0:
			emit_signal("value_changed", "prompt")
			ti_inject_label.text = "Prompt"
		1:
			emit_signal("value_changed", "negprompt")
			ti_inject_label.text = "Negative prompt"
		2:
			emit_signal("value_changed", null)
			ti_inject_label.text = "No"

func set_value(value):
	match value:
		"prompt":
			ti_inject_label.text = "Prompt"
		"negprompt":
			ti_inject_label.text = "Negative prompt"
		null:
			ti_inject_label.text = "No"
