class_name ModelSelection
extends Control

signal prompt_inject_requested(tokens)
signal model_modified(models_list)

var selected_models_list : Array = []
var model_refresh: float

onready var model_auto_complete = $"%ModelAutoComplete"
onready var selected_models = $"%SelectedModels"
onready var show_all_models = $"%ShowAllModels"

onready var model_select = $"%ModelSelect"
onready var stable_horde_models := $"%StableHordeModels"
onready var trigger_selection := $"%TriggerSelection"
onready var model_info_card := $"%ModelInfoCard"
onready var model_info_label := $"%ModelInfoLabel"
onready var popup_info := $"%PopupInfo"
onready var popup_info_label := $"%PopupInfoLabel"
onready var stable_horde_model_showcase = $"%StableHordeModelShowcase"
onready var model_showcase = $"%ModelShowcase"


func _ready():
	# warning-ignore:return_value_discarded
	stable_horde_models.connect("models_retrieved",self, "_on_models_retrieved")
	# warning-ignore:return_value_discarded
	trigger_selection.connect("id_pressed", self,"_on_trigger_selection_id_pressed")
	# warning-ignore:return_value_discarded
	model_auto_complete.connect("item_selected", self,"_on_model_selected")

	stable_horde_model_showcase.connect("showcase_retrieved",self, "_on_showcase_retrieved")
	
	selected_models.connect("meta_clicked",self,"_on_selected_models_meta_clicked")
	selected_models.connect("meta_hover_started",self,"_on_selected_models_meta_hover_started")
	selected_models.connect("meta_hover_ended",self,"_on_selected_models_meta_hover_ended")
	model_info_label.connect("meta_clicked",self,"_on_model_info_models_meta_clicked")
	show_all_models.connect("pressed",self,"_on_show_all_models_pressed")
# warning-ignore:return_value_discarded
	model_info_card.connect("hide",self,"_on_models_info_card_hide")
	stable_horde_models.emit_models_retrieved()
	yield(get_tree().create_timer(0.2), "timeout")
	selected_models_list = globals.config.get_value("Parameters", "models", [])
	_update_selected_models_label()
	_emit_selected_models()
	

func _process(delta):
	model_refresh += delta
	if model_refresh > 2.5:
		model_refresh = 0
		stable_horde_models.get_models()

func _on_models_retrieved(model_performances: Array, model_reference: Dictionary):
	var merged_reference = model_reference.duplicate(true)
	for model_performance in model_performances:
		var model_name = model_performance['name']
		if merged_reference.has(model_name):
			merged_reference[model_name]["worker_count"] = model_performance['count']
		else:
			merged_reference[model_name] = {}
			merged_reference[model_name]["worker_count"] = 0
	model_auto_complete.selections = merged_reference


func get_model_reference(model_name: String) -> Dictionary:
	var model_reference : Dictionary = stable_horde_models.model_reference.get_model_info(model_name)
	return(model_reference)


func get_model_performance(model_name: String) -> Dictionary:
	for m in stable_horde_models.model_performances:
		if m['name'] == model_name:
			return(m)
	var default_perf_dict = {
		"count": 'N/A',
		"performance": 1000000,
		"queued": 1,
		"eta": 4,
	}
	return(default_perf_dict)

func _on_request_initiated():
	stable_horde_models.get_models()

func _show_model_details(model_name: String) -> void:
	if model_name == "Any model":
		model_info_label.bbcode_text = """This option will cause each image in your request to be fulfilled by workers running any model.
As such, the result tend to be quite random as the image can be sent to something specialized which requires more specific triggers."""
	else:
		var model_reference := get_model_reference(model_name)
		stable_horde_model_showcase.get_model_showcase(model_reference)
		if model_reference.empty():
			model_info_label.bbcode_text = "No model info could not be retrieved at this time."
		else:
			var perf = _get_model_performance(model_name)
			var fmt = {
				"description": model_reference['description'],
				"version": model_reference['version'],
				"style": model_reference['style'],
				"trigger": model_reference.get('trigger'),
				"homepage": model_reference.get('homepage'),
				"eta": perf["eta"],
				"health_color": "#" + perf["health_color"],
				"workers": perf["workers"],
			}
			var label_text = "Description: {description}\nVersion: {version}\n".format(fmt)\
					+ "Style: {style}\nWorkers: {workers}. ETA: [color={health_color}]{eta}s[/color].".format(fmt)
			if fmt['trigger']:
				label_text += "\nTrigger token(s): {trigger}".format(fmt)
			if fmt['homepage']:
				label_text += "\nHomepage: [url={homepage}]{homepage}[/url]".format(fmt)
			model_info_label.bbcode_text = label_text
	model_info_card.rect_size = Vector2(0,0)
	model_info_card.popup()
	model_info_card.rect_global_position = get_global_mouse_position() + Vector2(30,-model_info_card.rect_size.y/2)

func _on_model_info_models_meta_clicked(meta) -> void:
# warning-ignore:return_value_discarded
	OS.shell_open(meta)

func _on_model_trigger_pressed(model_name) -> void:
	var model_reference := get_model_reference(model_name)
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
		trigger_selection.rect_global_position = selected_models.rect_global_position
	if selected_triggers.size() > 0:
		emit_signal("prompt_inject_requested", selected_triggers)

func _get_model_performance(model_name: String) -> Dictionary:
	var model_performance := get_model_performance(model_name)
	var healthy := Color(0,1,0)
	var unhealthy := Color(1,0,0)
	# We model the horde overloaded when there's a 20 seconds ETA to clear its current queue
	var current_pct = model_performance['eta'] / 40
	if current_pct > 1:
		current_pct = 1
	var health_color := healthy.linear_interpolate(unhealthy,current_pct)
	return {
		"health_color": health_color.to_html(false),
		"eta": model_performance['eta'],
		"workers": model_performance['count'],
	}

func _on_trigger_selection_id_pressed(id: int) -> void:
	if trigger_selection.is_item_checkable(id):
		trigger_selection.toggle_item_checked(id)
	else:
		var selected_triggers:= []
		for iter in range (trigger_selection.get_item_count()):
			if trigger_selection.is_item_checked(iter):
				selected_triggers.append(trigger_selection.get_item_text(iter))
		emit_signal("prompt_inject_requested", selected_triggers)


func _on_showcase_retrieved(img:ImageTexture, _model_name) -> void:
	model_showcase.texture = img
	model_showcase.rect_min_size = Vector2(400,400)

func replace_models(models_list: Array) -> void:
	selected_models_list = models_list
	_update_selected_models_label()
	_emit_selected_models()

func _on_model_selected(model_name: String) -> void:
	if model_name in selected_models_list:
		return
	selected_models_list.append(model_name)
	_update_selected_models_label()
	_emit_selected_models()

func _get_selected_models() -> Array:
	var model_defs = []
	for model_name in selected_models_list:
		if model_name == "SDXL_beta::stability.ai#6901":
			model_defs.append({
				"name": "SDXL_beta::stability.ai#6901",
				"baseline": "stable_diffusion_xl",
				"type": "SDXL",
				"version": "beta",
			})
		else:
			model_defs.append(get_model_reference(model_name))
	return model_defs

func get_all_baselines() -> Array:
	var baselines := []
	for model in _get_selected_models():
		if not model["baseline"] in baselines:
			baselines.append(model["baseline"])
	return baselines

func _emit_selected_models() -> void:
	EventBus.emit_signal("model_selected", _get_selected_models())
	emit_signal("model_modified", _get_selected_models())

func _update_selected_models_label() -> void:
	var bbtext := []
	var indexes_to_remove = []
	for index in range(selected_models_list.size()):
		var model_text = "[url={model_hover}]{model_name}[/url] ([url={model_trigger}]T[/url])([url={model_remove}]X[/url])"
		var model_name = selected_models_list[index]
		# This might happen for example when we added a NSFW lora
		# but then disabled NSFW which refreshed loras to only show SFW
		if not stable_horde_models.model_reference.is_model(model_name) and model_name != "SDXL_beta::stability.ai#6901":
			indexes_to_remove.append(index)
			continue
		if stable_horde_models.model_reference.get_model_info(model_name).get("trigger",[]).size() == 0:
			model_text = "[url={model_hover}]{model_name}[/url] ([url={model_remove}]X[/url])"
		var lora_fmt = {
			"model_name": model_name,
			"model_hover": 'hover:' + str(index),
			"model_remove": 'delete:' + str(index),
			"model_trigger": 'trigger:' + str(index),
		}
		bbtext.append(model_text.format(lora_fmt))
	selected_models.bbcode_text = ", ".join(bbtext)
	indexes_to_remove.invert()
	for index in indexes_to_remove:
		selected_models_list.remove(index)
	if selected_models_list.size() > 0:
		selected_models.show()
	else:
		selected_models.hide()

func _on_selected_models_meta_clicked(meta) -> void:
	var meta_split = meta.split(":")
	match meta_split[0]:
		"hover":
			_show_model_details(selected_models_list[int(meta_split[1])])
		"delete":
			selected_models_list.remove(int(meta_split[1]))
			_update_selected_models_label()
			_emit_selected_models()
		"trigger":
			_on_model_trigger_pressed(selected_models_list[int(meta_split[1])])

func _on_selected_models_meta_hover_started(meta: String) -> void:
	var meta_split = meta.split(":")
	var info = ''
	match meta_split[0]:
		"hover":
			info = "ModelHover"
		"delete":
			info = "ModelDelete"
		"trigger":
			info = "ModelTrigger"
	EventBus.emit_signal("rtl_meta_hovered",selected_models,info)

func _on_selected_models_meta_hover_ended(_meta: String) -> void:
	EventBus.emit_signal("rtl_meta_unhovered",selected_models)

func _on_lora_info_models_meta_clicked(meta) -> void:
# warning-ignore:return_value_discarded
	OS.shell_open(meta)

func _on_show_all_models_pressed() -> void:
	model_auto_complete.select_from_all()

class ModelSorter:
	static func sort(m1, m2):
		if m1["fmt"]["model_name"] < m2["fmt"]["model_name"]:
			return true
		return false
