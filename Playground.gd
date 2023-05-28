extends Control
var model_reference: CivitAILoraReference

func _ready() -> void:
	model_reference = CivitAILoraReference.new()
	add_child(model_reference)

