extends OptionButton

var model_id_map := {"Any model": 0}

onready var stable_horde_models := $"%StableHordeModels"

func _ready():
	# warning-ignore:return_value_discarded
	stable_horde_models.connect("models_retrieved",self, "_on_models_retrieved")
	# warning-ignore:return_value_discarded
	stable_horde_models.connect("request_failed",self, "_on_request_failed")
	# warning-ignore:return_value_discarded
	stable_horde_models.connect("request_warning",self, "_on_request_warning")
	# warning-ignore:return_value_discarded
#	connect("item_selected",self,"_on_item_selected") # Debug
	init_refresh_models()
	

func get_selected_model() -> String:
	for model_name in model_id_map:
		if model_id_map[model_name] == selected:
			return(model_name)
	push_error("Current selection does not match a model in the model_id_map!")
	return('')

func init_refresh_models() -> void:
	stable_horde_models.get_models()

func _on_models_retrieved(model_names: Array, model_reference: Dictionary):
	clear()
	model_id_map = {"Any model": 0}
#	print_debug(model_names, model_reference)
	add_item("Any model")
	# We start at 1 because "Any model" is 0
	for iter in range(model_names.size()):
		var id = iter + 1
		var model_name = model_names[iter]
		model_id_map[model_name] = id
		var model_fmt = {
			"model_name": model_name,
		}
		var model_entry = "{model_name}"
		if not model_reference.empty():
			model_fmt["style"] = model_reference[model_name].get("style",'')
			model_entry = "{model_name} ({style})"
		add_item(model_entry.format(model_fmt))
	set_previous_model() 
		

func set_previous_model() -> void:
	var config_models = globals.config.get_value("Parameters", "models", ["stable_diffusion"])
	var previous_selection: String
	if config_models.empty():
		previous_selection = "Any model"
	else:
		previous_selection = config_models[0]
	selected = 0
	for idx in range(get_item_count()):
#		if get_item_text(idx) == previous_selection:
		if get_item_id(idx) == model_id_map.get(previous_selection,-1):
			selected = idx
			break
	
func _on_request_initiated():
	init_refresh_models()

func _on_item_selected(_index):
	print_debug(get_selected_model())
