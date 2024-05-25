extends VBoxContainer

const QR_MODULE_DRAWERS = [
	"square",
	"gapped square",
	"circle",
	"rounded",
	"vertical bars",
	"horizontal bars"]

# The boolean in each extra text reference is whether that is optional
# for that workflow
const WORKFLOWS = {
	'auto-detect': [],
	'qr_code': [
		['qr_code',false, "The text which will be shown when scanning the generated QR code."],
		['x_offset',true, "The QR code will be placed this many pixels from the left of the image."],
		['y_offset',true, "The QR code will be placed this many pixels from the top of the image."],
		['protocol',true, "If your URL QR code fails to generate the right text, You can specify 'http' or 'https' here and remove it from the 'qr_code' field."],
		['module_drawer',true, "The QR Code type. Options are: " + str(QR_MODULE_DRAWERS)],
		['function_layer_prompt',true, "An extra prompt which will guide the generation of the QR code anchors."],
		['border',true, "The pixels of border the generated QR code should have. This will make it move obvious in the final image."],
	]
}

const ETSCENE = preload("res://src/ExtraTextContainer.tscn")

onready var extra_texts = $"%ExtraTexts"
onready var workflow = $"%Workflow"
onready var extra_texts_label = $"%ExtraTextsLabel"

func _ready():
	workflow.connect("mouse_entered", EventBus, "_on_node_hovered", 
		[
			workflow,
			"Select a custom workflow to use for this generation. Custom workflows typically require specifying extra parameters."
		]
	)
	workflow.connect("mouse_exited", EventBus, "_on_node_unhovered", [workflow])
	

func prepare_for_workflow():
	var workflow_name = workflow.get_item_text(workflow.get_selected_id())
	if not WORKFLOWS.has(workflow_name):
		push_error("workflow requested that doesn't exist: " + workflow_name)
		return
	if workflow_name == 'auto-detect':
		extra_texts_label.hide()
	else:
		extra_texts_label.show()
	for etnode in extra_texts.get_children():
		etnode.queue_free()
	for et in WORKFLOWS[workflow_name]:
		var new_et_scene = ETSCENE.instance()
		extra_texts.add_child(new_et_scene)
		new_et_scene.intiate_extra_text(et[0],et[1],et[2])

func get_extra_texts():
	if workflow.get_item_text(workflow.get_selected_id()) == 'auto-detect':
		return null
	var extra_texts_array: = []
	for etnode in extra_texts.get_children():
		var et = etnode.get_and_store_extra_text()
		if et != null:
			extra_texts_array.append(et)
	return extra_texts_array

func get_workflow_name():
	return workflow.get_item_text(workflow.get_selected_id())

func _on_Workflow_item_selected(_index):
	prepare_for_workflow()

func set_workflow_to(workflow_name: String):
	for idx in range(workflow.get_item_count()):
		if workflow.get_item_text(idx) == workflow_name:
			workflow.select(idx)
			prepare_for_workflow()
			return

func set_special_texts(et_array: Array):
	for et in et_array:
		for etnode in extra_texts.get_children():
			if etnode.is_queued_for_deletion():
				continue
			if etnode.reference.text.rstrip('*') == et['reference']:
				etnode.text.text = str(et['text'])
				break
