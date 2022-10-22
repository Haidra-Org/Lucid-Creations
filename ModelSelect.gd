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
	clear()
	add_item("Any model")
	for model_name in completed_payload:
		add_item(model_name)
	set_previous_model() 
		

func set_previous_model() -> void:
	var config_models = globals.config.get_value("Parameters", "models")
	var previous_selection: String
	if config_models.empty():
		previous_selection = "Any model"
	else:
		previous_selection = config_models[0]
	selected = 0
	for idx in range(get_item_count()):
		if get_item_text(idx) == previous_selection:
			selected = idx
			break
	


func _on_request_initiated():
	init_refresh_models()
