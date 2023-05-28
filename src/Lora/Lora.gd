extends Control

signal prompt_inject_requested(tokens)
signal model_changed(model_name)

var lora_reference_node: CivitAILoraReference
var selected_loras_list := []

onready var lora_auto_complete = $"%LoraAutoComplete"
onready var stable_horde_models := $"%StableHordeModels"
onready var lora_trigger_selection := $"%LoraTriggerSelection"
onready var lora_info_card := $"%LoraInfoCard"
onready var lora_info_label := $"%LoraInfoLabel"
onready var stable_horde_lora_showcase = $"%StableHordeModelShowcase"
onready var lora_showcase = $"%LoraShowcase"
onready var selected_loras = $"%SelectedLoras"

var previous_selection: String

func _ready():
	lora_reference_node = CivitAILoraReference.new()
	add_child(lora_reference_node)
	# warning-ignore:return_value_discarded
	lora_reference_node.connect("reference_retrieved",self, "_on_reference_retrieved")
	# warning-ignore:return_value_discarded
	lora_auto_complete.connect("item_selected", self,"_on_lora_selected")
	# warning-ignore:return_value_discarded
	lora_trigger_selection.connect("id_pressed", self,"_on_trigger_selection_id_pressed")
	# warning-ignore:return_value_discarded
	lora_info_label.connect("meta_clicked", self, "_on_lora_info_meta_clicked")
	# warning-ignore:return_value_discarded
	stable_horde_lora_showcase.connect("showcase_retrieved",self, "_on_showcase_retrieved")
	# warning-ignore:return_value_discarded
	selected_loras.connect("meta_clicked",self,"_on_selected_loras_meta_clicked")
	lora_info_label.connect("meta_clicked",self,"_on_lora_info_label_meta_clicked")
	_on_reference_retrieved(lora_reference_node.lora_reference)

func _on_lora_selected(lora_name: String) -> void:
	selected_loras_list.append(lora_name)
	_update_selected_loras_label()

func _on_reference_retrieved(model_reference: Dictionary):
	lora_auto_complete.selections = model_reference

func _show_lora_details(lora_name: String) -> void:
	var lora_reference := lora_reference_node.get_lora_info(lora_name)
	if lora_reference.empty():
		lora_info_label.bbcode_text = "No lora info could not be retrieved at this time."
	else:
		var fmt = {
			"description": lora_reference['description'],
			"version": lora_reference['version'],
			"trigger": ", ".join(lora_reference['triggers']),
			"url": "https://civitai.com/models/" + str(lora_reference['id']),
		}
		var label_text = "Description: {description}\nVersion: {version}\n".format(fmt)
		label_text += "\nTriggers: {trigger}".format(fmt)
		label_text += "\nCivitAI page: [url={url}]{url}[/url]".format(fmt)
		lora_info_label.bbcode_text = label_text
	lora_info_card.rect_size = Vector2(0,0)
	lora_info_card.popup()
	lora_info_card.rect_global_position = get_global_mouse_position() + Vector2(30,-lora_info_card.rect_size.y/2)

func _on_selected_loras_meta_clicked(meta) -> void:
	var meta_split = meta.split(":")
	match meta_split[0]:
		"hover":
			_show_lora_details(selected_loras_list[int(meta_split[1])])
		"delete":
			selected_loras_list.remove(int(meta_split[1]))
			_update_selected_loras_label()
			globals.set_setting("loras",selected_loras_list)
		"trigger":
			_on_lora_trigger_pressed(int(meta_split[1]))

func _on_lora_info_label_meta_clicked(meta) -> void:
	OS.shell_open(meta)

func _update_selected_loras_label() -> void:
	var bbtext := []
	for index in range(selected_loras_list.size()):
		var lora_text = "[url={lora_hover}]{lora_name}[/url] ([url={lora_trigger}]T[/url])([url={lora_remove}]X[/url])"
		var lora_fmt = {
			"lora_name": selected_loras_list[index],
			"lora_hover": 'hover:' + str(index),
			"lora_remove": 'delete:' + str(index),
			"lora_trigger": 'trigger:' + str(index),
		}
		bbtext.append(lora_text.format(lora_fmt))
	selected_loras.bbcode_text = ", ".join(bbtext)
	if selected_loras_list.size() > 0:
		selected_loras.show()
	else:
		selected_loras.hide()

func _on_lora_trigger_pressed(index: int) -> void:
	var lora_reference := lora_reference_node.get_lora_info(selected_loras_list[index])
	var selected_triggers: Array = []
	if lora_reference['triggers'].size() == 1:
		selected_triggers = [lora_reference['triggers'][0]]
	else:
		lora_trigger_selection.clear()
		for t in lora_reference['triggers']:
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


func _on_showcase_retrieved(img:ImageTexture, model_name) -> void:
	lora_showcase.texture = img
	lora_showcase.rect_min_size = Vector2(400,400)
