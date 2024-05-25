extends HBoxContainer

var is_optional := false
onready var reference: Label = $"%Reference"
onready var text: LineEdit = $"%Text"

func _ready():
	pass # Replace with function body.

func intiate_extra_text(reference_string: String, _is_optional: bool, description = null):
	is_optional = _is_optional	
	reference.text = reference_string
	if not is_optional:
		reference.text += '*'
	text.text = globals.config.get_value("ExtraTexts", reference_string, '')
	if not description:
		return
	connect("mouse_entered", EventBus, "_on_node_hovered", 
		[
			self,
			description
		]
	)
	connect("mouse_exited", EventBus, "_on_node_unhovered", [self])
	
func get_and_store_extra_text():
	if text.text == '':
		return null
	globals.config.set_value("ExtraTexts", reference.text, text.text)
	return {
		"reference": reference.text.rstrip('*'),
		"text": text.text
	}
