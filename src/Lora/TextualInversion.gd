class_name TISelection
extends Control

enum TICompatible {
	YES=0
	NO
	MAYBE
}

signal prompt_inject_requested(tokens)
signal tis_modified(tis_list)

var ti_reference_node: CivitAITIReference
var selected_tis_list : Array = []
var viewed_ti_index : int = 0
var civitai_search_initiated = false
var current_models := []

onready var ti_auto_complete = $"%TIAutoComplete"
onready var stable_horde_models := $"%StableHordeModels"
onready var ti_trigger_selection := $"%TITriggerSelection"
onready var ti_info_card := $"%TIInfoCard"
onready var ti_info_label := $"%TIInfoLabel"
onready var civitai_showcase0 = $"%TICivitAIShowcase0"
onready var civitai_showcase1 = $"%TICivitAIShowcase1"
onready var ti_showcase0 = $"%TIShowcase0"
onready var ti_showcase1 = $"%TIShowcase1"
onready var selected_tis = $"%SelectedTIs"
onready var show_all_tis = $"%ShowAllTIs"
onready var ti_model_strength = $"%TIModelStrength"
onready var ti_inject = $"%TIInject"
onready var fetch_tis_from_civitai = $"%FetchTIsFromCivitAI"

func _ready():
	# warning-ignore:return_value_discarded
	EventBus.connect("model_selected",self,"on_model_selection_changed")
	# warning-ignore:return_value_discarded
	EventBus.connect("cache_wipe_requested",self,"on_cache_wipe_requested")
	ti_reference_node = CivitAITIReference.new()
	ti_reference_node.nsfw = globals.config.get_value("Parameters", "nsfw")
	# warning-ignore:return_value_discarded
	ti_reference_node.connect("reference_retrieved",self, "_on_reference_retrieved")
	# warning-ignore:return_value_discarded
	ti_reference_node.connect("cache_wiped",self, "_on_cache_wiped")
	add_child(ti_reference_node)
	# warning-ignore:return_value_discarded
	ti_auto_complete.connect("item_selected", self,"_on_ti_selected")
	# warning-ignore:return_value_discarded
	ti_trigger_selection.connect("id_pressed", self,"_on_trigger_selection_id_pressed")
	# warning-ignore:return_value_discarded
	civitai_showcase0.connect("showcase_retrieved",self, "_on_showcase0_retrieved")
	# warning-ignore:return_value_discarded
	civitai_showcase1.connect("showcase_retrieved",self, "_on_showcase1_retrieved")
	# warning-ignore:return_value_discarded
	selected_tis.connect("meta_clicked",self,"_on_selected_tis_meta_clicked")
	# warning-ignore:return_value_discarded
	selected_tis.connect("meta_hover_started",self,"_on_selected_tis_meta_hover_started")
	# warning-ignore:return_value_discarded
	selected_tis.connect("meta_hover_ended",self,"_on_selected_tis_meta_hover_ended")
	# warning-ignore:return_value_discarded
	ti_info_label.connect("meta_clicked",self,"_on_ti_info_label_meta_clicked")
	# warning-ignore:return_value_discarded
	show_all_tis.connect("pressed",self,"_on_show_all_tis_pressed")
	# warning-ignore:return_value_discarded
	ti_info_card.connect("hide",self,"_on_ti_info_card_hide")
	# warning-ignore:return_value_discarded
	ti_model_strength.connect("value_changed",self,"_on_ti_model_strength_value_changed")
	# warning-ignore:return_value_discarded
	ti_inject.connect("value_changed",self,"_on_ti_inject_value_changed")
	# warning-ignore:return_value_discarded
	fetch_tis_from_civitai.connect("pressed",self,"_on_fetch_tis_from_civitai_pressed")
	_on_reference_retrieved(ti_reference_node.ti_reference)
	selected_tis_list = globals.config.get_value("Parameters", "tis", [])
	update_selected_tis_label()

func replace_tis(tis: Array) -> void:
	selected_tis_list = tis
	for ti in selected_tis_list:
		ti["name"] = ti_reference_node.get_ti_name(ti["name"])
	update_selected_tis_label()
	emit_signal("tis_modified", selected_tis_list)

func _on_ti_selected(ti_name: String) -> void:
	if selected_tis_list.size() >= 5:
		return
	selected_tis_list.append(
		{
			"name": ti_name,
			"strength": 1.0,
			"inject_ti": "prompt",
			"id": ti_reference_node.get_ti_info(ti_name)["id"],
		}
	)
	update_selected_tis_label()
	EventBus.emit_signal("ti_selected", ti_reference_node.get_ti_info(ti_name))
	emit_signal("tis_modified", selected_tis_list)

func _on_reference_retrieved(model_reference: Dictionary):
	ti_auto_complete.selections = model_reference
	fetch_tis_from_civitai.disabled = false
	if civitai_search_initiated:
		civitai_search_initiated = false
		ti_auto_complete.initiate_search()

func _show_ti_details(ti_name: String) -> void:
	var ti_reference := ti_reference_node.get_ti_info(ti_name)
	if ti_reference.empty():
		ti_info_label.bbcode_text = "No ti info could not be retrieved at this time."
	else:
		civitai_showcase0.get_model_showcase(ti_reference)
		civitai_showcase1.get_model_showcase(ti_reference)
		var fmt = {
			"name": ti_reference['name'],
			"description": ti_reference['description'],
			"version": ti_reference['version'],
			"trigger": ", ".join(ti_reference['triggers']),
			"url": "https://civitai.com/models/" + str(ti_reference['id']),
			"unusable": "",
		}
		var compatibility = check_baseline_compatibility(ti_name)
		if ti_reference.get("unusable"):
			fmt["unusable"] = "[color=red]" + ti_reference.get("unusable") + "[/color]\n"
		elif compatibility == TICompatible.NO:
			fmt["unusable"] = "[color=red]This Textual Inversion base model version is incompatible with the selected Model[/color]\n"
		elif compatibility == TICompatible.MAYBE:
			fmt["unusable"] = "[color=yellow]You have selected multiple models of varying base versions. This Textual Inversion is not compatible with all of them and will be ignored by the incompatible ones.[/color]\n"
		elif not ti_reference_node.nsfw and ti_reference.get("nsfw", false):
			fmt["unusable"] = "[color=#FF00FF]SFW workers which pick up the request, will ignore this Textual Inversion.[/color]\n"
		var label_text = "{unusable}[b]Name: {name}[/b]\nDescription: {description}\nVersion: {version}\n".format(fmt)
		label_text += "\nTriggers: {trigger}".format(fmt)
		label_text += "\nCivitAI page: [url={url}]{url}[/url]".format(fmt)
		ti_info_label.bbcode_text = label_text
	ti_info_card.rect_size = Vector2(0,0)
	ti_info_card.popup()
	ti_info_card.rect_global_position = get_global_mouse_position() + Vector2(30,-ti_info_card.rect_size.y/2)

func _on_selected_tis_meta_clicked(meta) -> void:
	var meta_split = meta.split(":")
	match meta_split[0]:
		"hover":
			viewed_ti_index = int(meta_split[1])
			ti_model_strength.set_value(selected_tis_list[viewed_ti_index]["strength"])
			ti_inject.set_value(selected_tis_list[viewed_ti_index].get("inject_ti"))
			_show_ti_details(selected_tis_list[viewed_ti_index]["name"])
		"delete":
			selected_tis_list.remove(int(meta_split[1]))
			update_selected_tis_label()
			emit_signal("tis_modified", selected_tis_list)
		"trigger":
			_on_ti_trigger_pressed(int(meta_split[1]))
		"embed":
			_on_ti_embed_pressed(int(meta_split[1]))

func _on_selected_tis_meta_hover_started(meta: String) -> void:
	var meta_split = meta.split(":")
	var info = ''
	match meta_split[0]:
		"hover":
			info = "TIHover"
		"delete":
			info = "TIDelete"
		"trigger":
			info = "TITrigger"
		"embed":
			info = "TIEmbed"
		"inject":
			info = "TIInject"
	EventBus.emit_signal("rtl_meta_hovered",selected_tis,info)

func _on_selected_tis_meta_hover_ended(_meta: String) -> void:
	EventBus.emit_signal("rtl_meta_unhovered",selected_tis)

func _on_ti_info_label_meta_clicked(meta) -> void:
	OS.shell_open(meta)

func update_selected_tis_label() -> void:
	var bbtext := []
	var indexes_to_remove = []
	for index in range(selected_tis_list.size()):
		var ti_text = "[url={ti_hover}]{ti_name}[/url]{strengths}{inject} ([url={ti_embed}]E[/url])([url={ti_trigger}]T[/url])([url={ti_remove}]X[/url])"
		var ti_name = selected_tis_list[index]["name"]
		# This might happen for example when we added a NSFW ti
		# but then disabled NSFW which refreshed tis to only show SFW
		if not ti_reference_node.is_ti(ti_name):
			indexes_to_remove.append(index)
			continue
		var ti_reference = ti_reference_node.get_ti_info(ti_name)
		if ti_reference["triggers"].size() == 0:
			ti_text = "[url={ti_hover}]{ti_name}[/url]{strengths}{inject} ([url={ti_remove}]X[/url])"
		var compatibility = check_baseline_compatibility(ti_name)
		if ti_reference.get("unusable"):
			ti_text = "[color=red]" + ti_text + "[/color]"
		elif compatibility == TICompatible.NO:
			ti_text = "[color=red]" + ti_text + "[/color]"
		elif compatibility == TICompatible.MAYBE:
			ti_text = "[color=yellow]" + ti_text + "[/color]"
		elif not ti_reference_node.nsfw and ti_reference.get("nsfw", false):
			ti_text = "[color=#FF00FF]" + ti_text + "[/color]"
			
		var strengths_string = ''
		if selected_tis_list[index]["strength"] != 1:
			strengths_string += ' S:'+str(selected_tis_list[index]["strength"])
		var inject_string = ''
		if selected_tis_list[index].get("inject_ti"):
			var inject_type = ''
			if selected_tis_list[index].get("inject_ti") == 'prompt':
				inject_type = 'p'
			else:
				inject_type = 'n'
			inject_string += ' I:' + inject_type
		var ti_fmt = {
			"ti_name": ti_name.left(25),
			"ti_hover": 'hover:' + str(index),
			"ti_remove": 'delete:' + str(index),
			"ti_trigger": 'trigger:' + str(index),
			"ti_embed": 'embed:' + str(index),
			"strengths": strengths_string,
			"inject": inject_string,
		}
		bbtext.append(ti_text.format(ti_fmt))
	selected_tis.bbcode_text = ", ".join(bbtext)
	indexes_to_remove.invert()
	for index in indexes_to_remove:
		selected_tis_list.remove(index)
	if selected_tis_list.size() > 0:
		selected_tis.show()
	else:
		selected_tis.hide()

func _on_ti_trigger_pressed(index: int) -> void:
	var ti_reference := ti_reference_node.get_ti_info(selected_tis_list[index]["name"])
	var selected_triggers: Array = []
	if ti_reference['triggers'].size() == 1:
		selected_triggers = [ti_reference['triggers'][0]]
	else:
		ti_trigger_selection.clear()
		for t in ti_reference['triggers']:
			ti_trigger_selection.add_check_item(t)
		ti_trigger_selection.add_item("Select")
		ti_trigger_selection.popup()
#		ti_trigger_selection.rect_global_position = ti_trigger.rect_global_position
	if selected_triggers.size() > 0:
		emit_signal("prompt_inject_requested", selected_triggers)

func _on_ti_embed_pressed(index: int) -> void:
	var ti_reference := ti_reference_node.get_ti_info(selected_tis_list[index]["name"])
	var inject_format = {
		"ti_id": ti_reference['id'],
		"ti_strength": selected_tis_list[index]["strength"],
	}
	var ti_id: String = "(embedding:{ti_id}:{ti_strength})".format(inject_format)
	emit_signal("prompt_inject_requested", [ti_id])

func _on_trigger_selection_id_pressed(id: int) -> void:
	if ti_trigger_selection.is_item_checkable(id):
		ti_trigger_selection.toggle_item_checked(id)
	else:
		var selected_triggers:= []
		for iter in range (ti_trigger_selection.get_item_count()):
			if ti_trigger_selection.is_item_checked(iter):
				selected_triggers.append(ti_trigger_selection.get_item_text(iter))
		emit_signal("prompt_inject_requested", selected_triggers)


func _on_showcase0_retrieved(img:ImageTexture, _model_name) -> void:
	ti_showcase0.texture = img
	ti_showcase0.rect_min_size = Vector2(300,300)

func _on_showcase1_retrieved(img:ImageTexture, _model_name) -> void:
	ti_showcase1.texture = img
	ti_showcase1.rect_min_size = Vector2(300,300)

func clear_textures() -> void:
	ti_showcase1.texture = null
	ti_showcase0.texture = null

func _on_ti_info_card_hide() -> void:
	clear_textures()
	update_selected_tis_label()

func _on_show_all_tis_pressed() -> void:
	ti_auto_complete.select_from_all()

func _on_ti_model_strength_value_changed(value) -> void:
	selected_tis_list[viewed_ti_index]["strength"] = value
	emit_signal("tis_modified", selected_tis_list)

func _on_ti_inject_value_changed(value) -> void:
	if not value:
		selected_tis_list[viewed_ti_index].erase("inject_ti")
	else:
		selected_tis_list[viewed_ti_index]["inject_ti"] = value
	emit_signal("tis_modified", selected_tis_list)

func _on_fetch_tis_from_civitai_pressed() -> void:
	fetch_tis_from_civitai.disabled = true
	civitai_search_initiated = true
	ti_reference_node.seek_online(ti_auto_complete.text)

func on_model_selection_changed(models_list) -> void:
	current_models = models_list
	update_selected_tis_label()

func check_baseline_compatibility(ti_name) -> int:
	var baselines = []
	for model in current_models:
		if not model["baseline"] in baselines:
			baselines.append(model["baseline"])
	if baselines.size() == 0:
		return TICompatible.MAYBE
	var ti_to_model_baseline_map = {
		"SD 1.5": "stable diffusion 1",
		"SD 2.1 768": "stable diffusion 2",
		"SD 2.1 512": "stable diffusion 2",
		"Other": null,
	}
	var ti_baseline = ti_to_model_baseline_map[ti_reference_node.get_ti_info(ti_name)["base_model"]]
	if ti_baseline == null:
		return TICompatible.NO
	if ti_baseline in baselines:
		if baselines.size() > 1:
			return TICompatible.MAYBE
		else:
			return TICompatible.YES
	return TICompatible.NO

func _on_cache_wiped() -> void:
	replace_tis([])

func on_cache_wipe_requested() -> void:
	ti_reference_node.wipe_cache()
