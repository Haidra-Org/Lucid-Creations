extends OptionButton

onready var stable_horde_models := $"%StableHordeModels"

func _ready():
	# warning-ignore:return_value_discarded
	stable_horde_models.connect("models_retrieved",self, "_on_models_retrieved")
	# warning-ignore:return_value_discarded
	stable_horde_models.connect("request_failed",self, "_on_request_failed")
	# warning-ignore:return_value_discarded
	stable_horde_models.connect("request_warning",self, "_on_request_warning")
	init_refresh_models()
	

func init_refresh_models() -> void:
	stable_horde_models.get_models()

func _on_models_retrieved(completed_payload: Array):
	var previous_selection = get_item_text(selected)
	clear()
	add_item("Any model")
	for model_name in completed_payload:
		add_item(model_name)
	for idx in range(get_item_count()):
		if get_item_text(idx) == previous_selection:
			selected = idx
			break
		

func _on_request_initiated():
	init_refresh_models()
