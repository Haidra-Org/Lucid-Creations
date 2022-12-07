extends Control

signal prompt_inject_requested(tokens)
signal model_changed(model_name)

var model_id_map := {"Any model": 0}

onready var model_select = $"%ModelSelect"
onready var stable_horde_models := $"%StableHordeModels"
onready var model_info := $"%ModelInfo"
onready var model_trigger := $"%ModelTrigger"
onready var trigger_selection := $"%TriggerSelection"
onready var model_info_card := $"%ModelInfoCard"
onready var model_info_label := $"%ModelInfoLabel"
onready var model_health  : TextureRect = $"%ModelHealth"
onready var model_eta = $"%ModelETA"
onready var popup_info := $"%PopupInfo"
onready var popup_info_label := $"%PopupInfoLabel"
onready var stable_horde_model_showcase = $"%StableHordeModelShowcase"
onready var model_showcase = $"%ModelShowcase"


var model_refresh: float
var previous_selection: String

func _ready():
	# warning-ignore:return_value_discarded
	stable_horde_models.connect("models_retrieved",self, "_on_models_retrieved")
	# warning-ignore:return_value_discarded
	model_info.connect("pressed", self, "_on_model_info_pressed")
	# warning-ignore:return_value_discarded
	model_trigger.connect("pressed", self, "_on_model_trigger_pressed")
	# warning-ignore:return_value_discarded
	trigger_selection.connect("id_pressed", self,"_on_trigger_selection_id_pressed")
#	connect("item_selected",self,"_on_item_selected") # Debug
	# warning-ignore:return_value_discarded
	model_info_label.connect("meta_clicked",self, "_on_model_info_meta_clicked")
	model_select.connect("item_selected",self,"_on_model_changed")
	# warning-ignore:return_value_discarded
	model_health.connect("mouse_entered", self, "_on_model_health_mouse_enterred")
	# warning-ignore:return_value_discarded
	model_health.connect("mouse_exited", self, "_on_model_health_mouse_exited")
	stable_horde_model_showcase.connect("showcase_retrieved",self, "_on_showcase_retrieved")
	init_refresh_models()

func _process(delta):
	model_refresh += delta
	if model_refresh > 2.5:
		model_refresh = 0
		init_refresh_models()

func get_selected_model() -> String:
	for model_name in model_id_map:
		if model_id_map[model_name] == model_select.selected:
			return(model_name)
	push_error("Current selection does not match a model in the model_id_map!")
	return('')


func init_refresh_models() -> void:
	if model_select.get_popup().visible:
		return
	if previous_selection == '':
		var config_models = globals.config.get_value("Parameters", "models", ["stable_diffusion"])
		if config_models.empty():
			previous_selection = "Any model"
		else:
			previous_selection = config_models[0]
	else:
		previous_selection = get_selected_model()
	stable_horde_models.get_models()


func _on_models_retrieved(model_performances: Array, model_reference: Dictionary):
	if model_select.get_popup().visible:
		return
	model_select.clear()
	model_id_map = {"Any model": 0}
#	print_debug(model_names, model_reference)
	model_select.add_item("Any model")
	# We start at 1 because "Any model" is 0
	for iter in range(model_performances.size()):
		var model_performance : Dictionary = model_performances[iter]
		var model_name = model_performance['name']
		var worker_count = model_performance['count']
		# We ignore unknown model names
		if not model_reference.empty() and not model_reference.has(model_name):
			continue
		var id = iter + 1
		model_id_map[model_name] = id
		var model_fmt = {
			"model_name": model_name,
			"worker_count": worker_count,
		}
		var model_entry = "{model_name}"
		if not model_reference.empty():
			model_fmt["style"] = model_reference[model_name].get("style",'')
			model_entry = "{model_name}: {style} ({worker_count})"
		model_select.add_item(model_entry.format(model_fmt))
	set_previous_model()
#	print_debug(model_reference)
	_refresh_model_performance()

func set_previous_model() -> void:
	model_select.selected = 0
	for idx in range(model_select.get_item_count()):
#		if get_item_text(idx) == previous_selection:
		if model_select.get_item_id(idx) == model_id_map.get(previous_selection,-1):
			model_select.selected = idx
			break


func get_selected_model_reference() -> Dictionary:
	var model_reference : Dictionary = stable_horde_models.model_reference.get_model_info(get_selected_model())
	return(model_reference)

func get_selected_model_performance() -> Dictionary:
	for m in stable_horde_models.model_performances:
		if m['name'] == get_selected_model():
			return(m)
	var default_perf_dict = {
		"count": 'N/A',
		"performance": 1000000,
		"queued": 1,
		"eta": 4,
	}
	return(default_perf_dict)


func _on_request_initiated():
	init_refresh_models()

#func _on_item_selected(_index):
#	print_debug(get_selected_model())


func _on_model_info_pressed() -> void:
	var model_name = get_selected_model()
	if model_name == "Any model":
		model_info_label.bbcode_text = """This option will cause each image in your request to be fulfilled by workers running any model.
As such, the result tend to be quite random as the image can be sent to something specialized which requires more specific triggers."""
	else:
		var model_reference := get_selected_model_reference()
		if model_reference.empty():
			model_info_label.bbcode_text = "No model info could not be retrieved at this time."
		else:
			var fmt = {
				"description": model_reference['description'],
				"version": model_reference['version'],
				"style": model_reference['style'],
				"trigger": model_reference.get('trigger'),
				"homepage": model_reference.get('homepage'),
			}
			var label_text = "Description: {description}\nVersion: {version}\n".format(fmt)\
					+ "Style: {style}".format(fmt)
			if fmt['trigger']:
				label_text += "\nTrigger token(s): '{trigger}'".format(fmt)
			if fmt['homepage']:
				label_text += "\nHomepage: [url=homepage]{homepage}[/url]".format(fmt)
			model_info_label.bbcode_text = label_text
	model_info_card.rect_size = Vector2(0,0)
	model_info_card.popup()
	model_info_card.rect_global_position = get_global_mouse_position() + Vector2(30,0)

func _on_model_info_meta_clicked(meta):
	match meta:
		"homepage":
			var model_reference := get_selected_model_reference()
			# warning-ignore:return_value_discarded
			OS.shell_open(model_reference['homepage'])

func _on_model_trigger_pressed() -> void:
	var model_reference := get_selected_model_reference()
	var selected_triggers: Array = []
	if typeof(model_reference['trigger']) == TYPE_STRING:
		selected_triggers =  [model_reference['trigger']]
	elif model_reference['trigger'].size() == 1:
		selected_triggers = [model_reference['trigger'][0]]
	else:
		trigger_selection.clear()
		for t in model_reference['trigger']:
			trigger_selection.add_check_item(t)
		trigger_selection.add_item("Select")
		trigger_selection.popup()
		trigger_selection.rect_global_position = model_trigger.rect_global_position
	if selected_triggers.size() > 0:
		emit_signal("prompt_inject_requested", selected_triggers)


func _on_model_changed(_selected_item = null) -> void:
	var model_reference := get_selected_model_reference()
	if model_reference.empty() and get_selected_model() != "Any model":
		model_info.disabled = true
	else:
		model_info.disabled = false
	if model_reference.get('trigger'):
		model_trigger.disabled = false
	else:
		model_trigger.disabled = true
	model_showcase.rect_min_size = Vector2(0,0)
	stable_horde_model_showcase.get_model_showcase(model_reference)
	emit_signal("model_changed",get_selected_model())
	_refresh_model_performance()
	_update_popup_info_label()


func _refresh_model_performance() -> void:
	var model_performance := get_selected_model_performance()
	if get_selected_model() == "Any model":
		model_health.self_modulate = Color(0,1,0)
		model_eta.text = '0'
	else:
		var healthy := Color(0,1,0)
		var unhealthy := Color(1,0,0)
		# We model the horde overloaded when there's a 20 seconds ETA to clear its current queue
		var current_pct = model_performance['eta'] / 40
		if current_pct > 1:
			current_pct = 1
		model_health.self_modulate = healthy.linear_interpolate(unhealthy,current_pct)
		model_eta.text = str(model_performance['eta'])

func _on_model_health_mouse_enterred() -> void:
	popup_info.show()
	popup_info.rect_global_position = get_global_mouse_position() + Vector2(30,-40)
	_update_popup_info_label()

func _on_model_health_mouse_exited() -> void:
	popup_info.hide()

func _update_popup_info_label() -> void:
	if get_selected_model() == "Any model":
		popup_info_label.bbcode_text = "'Any model' will process your request the fastest of all options, but the model which will process each image can differ."
		return
	var model_performance := get_selected_model_performance()
	var t = "Available workers: {count}\n"\
			+ "Average Speed per worker: {performance} MPS/s\n"\
			+ "Queued MPS: {mps}\nEst. time to clear queue: {eta} seconds."
	var fmt = {
		"count": model_performance["count"],
		"performance": stepify(model_performance["performance"] / 1000000, 0.1),
		"mps": stepify(model_performance["queued"] / 1000000, 0.1),
		"eta": model_performance["eta"],
	}
	popup_info_label.bbcode_text = t.format(fmt)

func _on_trigger_selection_id_pressed(id: int) -> void:
	if trigger_selection.is_item_checkable(id):
		trigger_selection.toggle_item_checked(id)
	else:
		var selected_triggers:= []
		for iter in range (trigger_selection.get_item_count()):
			if trigger_selection.is_item_checked(iter):
				selected_triggers.append(trigger_selection.get_item_text(iter))
		emit_signal("prompt_inject_requested", selected_triggers)

func _on_showcase_retrieved(img:ImageTexture, model_name) -> void:
	model_showcase.texture = img
	model_showcase.rect_min_size = Vector2(400,400)
