class_name LoraSelection
extends Control

enum LoraCompatible {
	YES=0
	NO
	MAYBE
}

const LCM_LORAS := [
	"216190",
	"195519",
]

signal prompt_inject_requested(tokens)
signal loras_modified(loras_list)

var lora_reference_node: CivitAILoraReference
var selected_loras_list : Array = []
var viewed_lora_index : int = 0
var civitai_search_initiated = false
var current_models := []

onready var lora_auto_complete = $"%LoraAutoComplete"
onready var stable_horde_models := $"%StableHordeModels"
onready var lora_trigger_selection := $"%LoraTriggerSelection"
onready var lora_info_card := $"%LoraInfoCard"
onready var lora_info_label := $"%LoraInfoLabel"
onready var civitai_showcase0 = $"%CivitAIShowcase0"
onready var civitai_showcase1 = $"%CivitAIShowcase1"
onready var lora_showcase0 = $"%LoraShowcase0"
onready var lora_showcase1 = $"%LoraShowcase1"
onready var selected_loras = $"%SelectedLoras"
onready var show_all_loras = $"%ShowAllLoras"
onready var lora_model_strength = $"%LoraModelStrength"
onready var lora_clip_strength = $"%LoraClipStrength"
onready var fetch_from_civitai = $"%FetchFromCivitAI"
onready var lora_version_selection = $"%LoraVersionSelection"

func _ready():
	# warning-ignore:return_value_discarded
	EventBus.connect("model_selected",self,"on_model_selection_changed")
	# warning-ignore:return_value_discarded
	EventBus.connect("cache_wipe_requested",self,"on_cache_wipe_requested")
	lora_reference_node = CivitAILoraReference.new()
	lora_reference_node.nsfw = globals.config.get_value("Parameters", "nsfw")
	# warning-ignore:return_value_discarded
	lora_reference_node.connect("reference_retrieved",self, "_on_reference_retrieved")
	# warning-ignore:return_value_discarded
	lora_reference_node.connect("cache_wiped",self, "_on_cache_wiped")
	add_child(lora_reference_node)
	# warning-ignore:return_value_discarded
	lora_auto_complete.connect("item_selected", self,"_on_lora_selected")
	# warning-ignore:return_value_discarded
	lora_trigger_selection.connect("id_pressed", self,"_on_trigger_selection_id_pressed")
	# warning-ignore:return_value_discarded
	lora_version_selection.get_popup().connect("id_pressed", self, "_on_lora_version_selected")
	# warning-ignore:return_value_discarded
	civitai_showcase0.connect("showcase_retrieved",self, "_on_showcase0_retrieved")
	# warning-ignore:return_value_discarded
	civitai_showcase1.connect("showcase_retrieved",self, "_on_showcase1_retrieved")
	# warning-ignore:return_value_discarded
	civitai_showcase0.connect("showcase_failed",self, "_on_showcase0_failed")
	# warning-ignore:return_value_discarded
	civitai_showcase1.connect("showcase_failed",self, "_on_showcase1_failed")
	# warning-ignore:return_value_discarded
	selected_loras.connect("meta_clicked",self,"_on_selected_loras_meta_clicked")
	# warning-ignore:return_value_discarded
	selected_loras.connect("meta_hover_started",self,"_on_selected_loras_meta_hover_started")
	# warning-ignore:return_value_discarded
	selected_loras.connect("meta_hover_ended",self,"_on_selected_loras_meta_hover_ended")
	# warning-ignore:return_value_discarded
	lora_info_label.connect("meta_clicked",self,"_on_lora_info_label_meta_clicked")
	# warning-ignore:return_value_discarded
	show_all_loras.connect("pressed",self,"_on_show_all_loras_pressed")
	# warning-ignore:return_value_discarded
	lora_info_card.connect("hide",self,"_on_lora_info_card_hide")
	# warning-ignore:return_value_discarded
	lora_model_strength.connect("value_changed",self,"_on_lora_model_strength_value_changed")
	# warning-ignore:return_value_discarded
	lora_clip_strength.connect("value_changed",self,"_on_lora_clip_strength_value_changed")
	# warning-ignore:return_value_discarded
	fetch_from_civitai.connect("pressed",self,"_on_fetch_from_civitai_pressed")
	_on_reference_retrieved(lora_reference_node.lora_reference)
	selected_loras_list = globals.config.get_value("Parameters", "loras", [])
	update_selected_loras_label()

func replace_loras(loras: Array) -> void:
	selected_loras_list = loras
	for lora in selected_loras_list:
		var is_version = lora.get("is_version", false)
		lora["name"] = lora_reference_node.get_lora_name(
			lora["name"], 
			is_version
		)
		if not is_version:
			lora["id"] = lora_reference_node.get_latest_version(lora["name"])
			lora["is_version"] = true
			lora["lora_id"] = lora_reference_node.get_lora_info(lora["id"], true)["id"]
	update_selected_loras_label()
	emit_signal("loras_modified", selected_loras_list)

func _on_lora_selected(lora_name: String, is_version = false) -> void:
	if selected_loras_list.size() >= 5:
		return
	var version_id: String
	var final_lora_name: String
	if is_version:
		version_id = lora_name
		final_lora_name = lora_reference_node.get_lora_name(lora_name)
	else:
		version_id = lora_reference_node.get_latest_version(lora_name)
		final_lora_name = lora_name
	selected_loras_list.append(
		{
			"name": final_lora_name,
			"model": 1.0,
			"clip": 1.0,
			"id": version_id, # ID holds just version ID. We always send version IDs
			"lora_id": lora_reference_node.get_lora_info(version_id, true)["id"],
			"is_version": true,
		}
	)
	update_selected_loras_label()
	EventBus.emit_signal("lora_selected", lora_reference_node.get_lora_info(lora_name))
	emit_signal("loras_modified", selected_loras_list)

func _on_reference_retrieved(model_reference: Dictionary):
	lora_auto_complete.selections = model_reference
	fetch_from_civitai.disabled = false
	if civitai_search_initiated:
		civitai_search_initiated = false
		lora_auto_complete.initiate_search()

func update_lora_details_texts(lora_reference, version_id) -> void:
	var fmt = {
		"name": lora_reference['name'],
		"description": lora_reference['description'],
		"trigger": ", ".join(lora_reference['versions'][version_id]['triggers']),
		"url": "https://civitai.com/models/" + str(lora_reference['id']) + "?modelVersionId=" + str(version_id),
		"unusable": "",
	}
	var compatibility = check_baseline_compatibility(version_id)
	if lora_reference['versions'][version_id].get("unusable"):
		fmt["unusable"] = "[color=red]" + lora_reference['versions'][version_id].get("unusable") + "[/color]\n"
	elif compatibility == LoraCompatible.NO:
		fmt["unusable"] = "[color=red]This LoRa base model version is impatible with the selected Model[/color]\n"
	elif compatibility == LoraCompatible.MAYBE:
		fmt["unusable"] = "[color=yellow]You have selected multiple models of varying base versions. This LoRa is not compatible with all of them and will be ignored by the incompatible ones.[/color]\n"
	elif not lora_reference_node.nsfw and lora_reference['versions'][version_id].get("nsfw", false):
		fmt["unusable"] = "[color=#FF00FF]SFW workers which pick up the request, will ignore this LoRA.[/color]\n"
	var label_text = "{unusable}[b]Name: {name}[/b]\nDescription: {description}\n".format(fmt)
	label_text += "\nTriggers: {trigger}".format(fmt)
	label_text += "\nCivitAI page: [url={url}]{url}[/url]".format(fmt)
	lora_info_label.bbcode_text = label_text
	

func _show_lora_details(version_id: String) -> void:
	var lora_reference := lora_reference_node.get_lora_info(version_id, true)
	if lora_reference.empty():
		lora_info_label.bbcode_text = "No lora info could not be retrieved at this time."
	else:
		civitai_showcase0.get_model_showcase(lora_reference, version_id)
		civitai_showcase1.get_model_showcase(lora_reference, version_id)
		update_lora_details_texts(lora_reference, version_id)
	var lora_versions_popup :PopupMenu = lora_version_selection.get_popup()
	lora_versions_popup.clear()
	for version in lora_reference['versions'].values():
		lora_versions_popup.add_item(version['name'], int(version['id']))
	lora_version_selection.text = lora_reference['versions'][version_id]['name']
	lora_info_card.rect_size = Vector2(0,0)
	lora_info_card.popup()
	lora_info_card.rect_global_position = get_global_mouse_position() + Vector2(30,-lora_info_card.rect_size.y/2)

func _on_selected_loras_meta_clicked(meta) -> void:
	var meta_split = meta.split(":")
	match meta_split[0]:
		"hover":
			viewed_lora_index = int(meta_split[1])
			lora_model_strength.set_value(selected_loras_list[viewed_lora_index]["model"])
			lora_clip_strength.set_value(selected_loras_list[viewed_lora_index]["clip"])
			_show_lora_details(selected_loras_list[viewed_lora_index]["id"])
		"delete":
			selected_loras_list.remove(int(meta_split[1]))
			update_selected_loras_label()
			emit_signal("loras_modified", selected_loras_list)
		"trigger":
			_on_lora_trigger_pressed(int(meta_split[1]))

func _on_selected_loras_meta_hover_started(meta: String) -> void:
	var meta_split = meta.split(":")
	var info = ''
	match meta_split[0]:
		"hover":
			info = "LoRaHover"
		"delete":
			info = "LoRaDelete"
		"trigger":
			info = "LoRaTrigger"
	EventBus.emit_signal("rtl_meta_hovered",selected_loras,info)

func _on_selected_loras_meta_hover_ended(_meta: String) -> void:
	EventBus.emit_signal("rtl_meta_unhovered",selected_loras)

func _on_lora_info_label_meta_clicked(meta) -> void:
	OS.shell_open(meta)

func update_selected_loras_label() -> void:
	var bbtext := []
	var indexes_to_remove = []
	for index in range(selected_loras_list.size()):
		var selected_lora : Dictionary = selected_loras_list[index]
		var version_id : String = selected_lora['id']
		var lora_text = "[url={lora_hover}]{lora_name}[/url]{strengths} ([url={lora_trigger}]T[/url])([url={lora_remove}]X[/url])"
		var lora_name = selected_lora["name"]
		# This might happen for example when we added a NSFW lora
		# but then disabled NSFW which refreshed loras to only show SFW
		if not lora_reference_node.is_lora(lora_name):
			indexes_to_remove.append(index)
			continue
		var lora_reference = lora_reference_node.get_lora_info(version_id, true)
		if lora_reference["versions"][version_id]["triggers"].size() == 0:
			lora_text = "[url={lora_hover}]{lora_name}[/url]{strengths} ([url={lora_remove}]X[/url])"
		var compatibility = check_baseline_compatibility(version_id)
		if lora_reference["versions"][version_id].get("unusable"):
			lora_text = "[color=red]" + lora_text + "[/color]"
		elif compatibility == LoraCompatible.NO:
			lora_text = "[color=red]" + lora_text + "[/color]"
		elif compatibility == LoraCompatible.MAYBE:
			lora_text = "[color=yellow]" + lora_text + "[/color]"
		elif not lora_reference_node.nsfw and lora_reference.get("nsfw", false):
			lora_text = "[color=#FF00FF]" + lora_text + "[/color]"
			
		var strengths_string = ''
		if selected_loras_list[index]["model"] != 1:
			strengths_string += ' M:'+str(selected_loras_list[index]["model"])
		if selected_loras_list[index]["clip"] != 1:
			strengths_string += ' C:'+str(selected_loras_list[index]["clip"])
		var lora_fmt = {
			"lora_name": lora_name.left(25),
			"lora_hover": 'hover:' + str(index),
			"lora_remove": 'delete:' + str(index),
			"lora_trigger": 'trigger:' + str(index),
			"strengths": strengths_string,
		}
		bbtext.append(lora_text.format(lora_fmt))
	selected_loras.bbcode_text = ", ".join(bbtext)
	indexes_to_remove.invert()
	for index in indexes_to_remove:
		selected_loras_list.remove(index)
	if selected_loras_list.size() > 0:
		selected_loras.show()
	else:
		selected_loras.hide()

func _on_lora_trigger_pressed(index: int) -> void:
	var version_id: String = selected_loras_list[index]["id"]
	var is_version: bool = selected_loras_list[index]["is_version"]
	var lora_reference := lora_reference_node.get_lora_info(version_id, is_version)
	var selected_triggers: Array = []
	if lora_reference['versions'][version_id]['triggers'].size() == 1:
		selected_triggers = [lora_reference['versions'][version_id]['triggers'][0]]
	else:
		lora_trigger_selection.clear()
		for t in lora_reference['versions'][version_id]['triggers']:
			lora_trigger_selection.add_check_item(t)
		lora_trigger_selection.add_item("Select")
		lora_trigger_selection.popup()
#		lora_trigger_selection.rect_global_position = lora_trigger.rect_global_position
	if selected_triggers.size() > 0:
		emit_signal("prompt_inject_requested", selected_triggers)

func _on_trigger_selection_id_pressed(id: int) -> void:
	if lora_trigger_selection.is_item_checkable(id):
		lora_trigger_selection.toggle_item_checked(id)
	else:
		var selected_triggers:= []
		for iter in range (lora_trigger_selection.get_item_count()):
			if lora_trigger_selection.is_item_checked(iter):
				selected_triggers.append(lora_trigger_selection.get_item_text(iter))
		emit_signal("prompt_inject_requested", selected_triggers)


func _on_showcase0_retrieved(img:ImageTexture, _model_name) -> void:
	lora_showcase0.texture = img
	lora_showcase0.rect_min_size = Vector2(300,300)

func _on_showcase0_failed() -> void:
	lora_showcase0.texture = null

func _on_showcase1_retrieved(img:ImageTexture, _model_name) -> void:
	lora_showcase1.texture = img
	lora_showcase1.rect_min_size = Vector2(300,300)

func _on_showcase1_failed() -> void:
	lora_showcase1.texture = null

func clear_textures() -> void:
	lora_showcase1.texture = null
	lora_showcase0.texture = null

func _on_lora_info_card_hide() -> void:
	clear_textures()
	update_selected_loras_label()

func _on_show_all_loras_pressed() -> void:
	lora_auto_complete.select_from_all()

func _on_lora_model_strength_value_changed(value) -> void:
	selected_loras_list[viewed_lora_index]["model"] = value
	emit_signal("loras_modified", selected_loras_list)

func _on_lora_clip_strength_value_changed(value) -> void:
	selected_loras_list[viewed_lora_index]["clip"] = value
	emit_signal("loras_modified", selected_loras_list)

func _on_fetch_from_civitai_pressed() -> void:
	fetch_from_civitai.disabled = true
	civitai_search_initiated = true
	lora_reference_node.seek_online(lora_auto_complete.text)

func on_model_selection_changed(models_list) -> void:
	current_models = models_list
	update_selected_loras_label()

func check_baseline_compatibility(version_id: String) -> int:
	var baselines = []
	for model in current_models:
		if not model["baseline"] in baselines:
			baselines.append(model["baseline"])
	if baselines.size() == 0:
		return LoraCompatible.MAYBE
	var lora_to_model_baseline_map = {
		"SDXL 1.0": "stable_diffusion_xl",
		"SD 1.5": "stable diffusion 1",
		"SD 2.1 768": "stable diffusion 2",
		"SD 2.1 512": "stable diffusion 2",
		"Other": null,
	}
	var lora_details := lora_reference_node.get_lora_info(version_id, true)
	var curr_baseline = lora_details["versions"][version_id]["base_model"]
	if not lora_to_model_baseline_map.has(curr_baseline):
		return LoraCompatible.NO
	var lora_baseline = lora_to_model_baseline_map[curr_baseline]
	if lora_baseline == null:
		return LoraCompatible.NO
	if lora_baseline in baselines:
		if baselines.size() > 1:
			return LoraCompatible.MAYBE
		else:
			return LoraCompatible.YES
	return LoraCompatible.NO

func _on_cache_wiped() -> void:
	replace_loras([])

func on_cache_wipe_requested() -> void:
	lora_reference_node.wipe_cache()

func _on_lora_version_selected(id: int) -> void:
	var version_id := str(id)
	var lora_details = lora_reference_node.get_lora_info(version_id, true)
	var lora_name: String = lora_details["name"]
	for slora in selected_loras_list:
		if slora["id"] == version_id:
			return
		if slora["name"] == lora_name:
			slora["id"] = version_id
			civitai_showcase0.get_model_showcase(lora_details, version_id)
			civitai_showcase1.get_model_showcase(lora_details, version_id)
			update_lora_details_texts(lora_details, version_id)
			update_selected_loras_label()
			EventBus.emit_signal("lora_selected", lora_details)
			emit_signal("loras_modified", selected_loras_list)
			lora_version_selection.text = lora_details['versions'][version_id]['name']
			return
	# We expect the lora whose version is changing to always exist in the list
	# We should never be adding to the list by changing versions

func has_lcm_loras() -> bool:
	for lora in selected_loras_list:
		if LCM_LORAS.has(lora["lora_id"]):
			return true
	return false
