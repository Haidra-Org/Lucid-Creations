class_name WorkerSelection
extends Control

signal worker_modified(workers_list)

var selected_workers_list : Array = []
var worker_refresh: float
var current_models := []
var blocklist := false

onready var worker_auto_complete = $"%WorkerAutoComplete"
onready var selected_workers = $"%SelectedWorkers"
onready var show_all_workers = $"%ShowAllWorkers"

onready var worker_select = $"%WorkerSelect"
onready var stable_horde_workers := $"%StableHordeWorkers"
onready var worker_info_card := $"%WorkerInfoCard"
onready var worker_info_label := $"%WorkerInfoLabel"
onready var popup_info := $"%WorkerPopupInfo"
onready var popup_info_label := $"%WorkerPopupInfoLabel"
onready var block_list = $"%BlockList"


func _ready():
# warning-ignore:return_value_discarded
	EventBus.connect("model_selected",self,"on_model_selection_changed")
	# warning-ignore:return_value_discarded
	stable_horde_workers.connect("workers_retrieved",self, "_on_workers_retrieved")
	# warning-ignore:return_value_discarded
	worker_auto_complete.connect("item_selected", self,"_on_worker_selected")
	
	selected_workers.connect("meta_clicked",self,"_on_selected_workers_meta_clicked")
	selected_workers.connect("meta_hover_started",self,"_on_selected_workers_meta_hover_started")
	selected_workers.connect("meta_hover_ended",self,"_on_selected_workers_meta_hover_ended")
	worker_info_label.connect("meta_clicked",self,"_on_worker_info_workers_meta_clicked")
	show_all_workers.connect("pressed",self,"_on_show_all_workers_pressed")
	block_list.connect("toggled",self,"_on_blocklist_enabled")
# warning-ignore:return_value_discarded
	worker_info_card.connect("hide",self,"_on_workers_info_card_hide")
	yield(get_tree().create_timer(0.2), "timeout")
	selected_workers_list = globals.config.get_value("Options", "workers", [])
	blocklist = globals.config.get_value("Options", "blocklist", false)
	block_list.pressed = blocklist
	_update_selected_workers_label()
	_emit_selected_workers()
	

func _process(delta):
	worker_refresh += delta
	if worker_refresh > 30:
		worker_refresh = 0
		stable_horde_workers.get_workers()

func _on_workers_retrieved(_worker_reference: Dictionary):
	worker_auto_complete.selections = stable_horde_workers.get_workers_with_models(current_models)


func get_worker_reference(worker_name: String) -> Dictionary:
	return stable_horde_workers.get_worker_info(worker_name)


func get_worker_performance(worker_name: String) -> Dictionary:
	var worker = get_worker_reference(worker_name)
	var default_perf_dict = {
		"performance": float(worker["performance"].split(' ')[0]),
		"uptime": worker["uptime"] / (60*60*24),
	}
	return(default_perf_dict)

func _on_request_initiated():
	stable_horde_workers.get_workers()

func _show_worker_details(worker_name: String) -> void:
	var worker_reference := get_worker_reference(worker_name)
	if worker_reference.empty():
		worker_info_label.bbcode_text = "No worker info could not be retrieved at this time."
	else:
		var perf = _get_worker_performance(worker_name)
		var fmt = {
			"id": worker_reference['id'],
			"description": worker_reference['name'],
			"version": worker_reference['bridge_agent'],
			"trusted": worker_reference['trusted'],
			"info": worker_reference.get('info'),
			"team": worker_reference['team']['name'],
			"models": ', '.join(worker_reference["models"]),
			"health_color": "#" + perf["health_color"],
			"trusted_color": "#" + perf["trusted_color"],
			"performance": worker_reference['performance'],
		}
		if worker_reference["models"].size() > 30:
			fmt["models"] = worker_reference["models"].size()
		if not worker_reference.get('info'):
			fmt["info"] = "N/A"
		var label_text = "Name: {description}\nID: {id}\nVersion: {version}\n".format(fmt)\
				+ "Trusted: [color={trusted_color}]{trusted}[/color].\n".format(fmt)\
				+ "Performance: [color={health_color}]{performance}[/color].\n".format(fmt)\
				+ "Models: {models}.\n\n".format(fmt)\
				+ "Info: {info}".format(fmt)
		worker_info_label.bbcode_text = label_text
	worker_info_card.rect_size = Vector2(0,0)
	worker_info_card.popup()
	worker_info_card.rect_global_position = get_global_mouse_position() + Vector2(30,-worker_info_card.rect_size.y/2)

func _get_worker_performance(worker_name: String) -> Dictionary:
	var worker_performance := get_worker_performance(worker_name)
	var worker_reference := get_worker_reference(worker_name)
	var healthy := Color(0,1,0)
	var unhealthy := Color(1,0,0)
	# Any speed above 1MPS is decent. However below 1MPS we consider it unhealthy
	var health_pct = worker_performance["performance"]
	if worker_performance["performance"] > 1.0:
		health_pct = 1
	var normalized = (health_pct - 0.5) / (1.0 - 0.5)
	if normalized < 0:
		normalized = 0
	var health_color := unhealthy.linear_interpolate(healthy,normalized)
	var trusted_color = Color(0,1,0)
	if not worker_reference['trusted']:
		trusted_color = Color(1,1,0)
	return {
		"health_color": health_color.to_html(false),
		"trusted_color": trusted_color.to_html(false),
	}

func replace_workers(workers_list: Array) -> void:
	selected_workers_list = workers_list
	_update_selected_workers_label()
	_emit_selected_workers()

func _on_worker_selected(worker_name: String) -> void:
	if selected_workers_list.size() >= 5:
		return
	if worker_name in selected_workers_list:
		return
	selected_workers_list.append(worker_name)
	_update_selected_workers_label()
	_emit_selected_workers()

func _get_selected_workers() -> Array:
	var worker_defs = []
	for worker_name in selected_workers_list:
		worker_defs.append(get_worker_reference(worker_name))
	return worker_defs

func _emit_selected_workers() -> void:
	EventBus.emit_signal("worker_selected", _get_selected_workers())
	emit_signal("worker_modified", _get_selected_workers())

func _update_selected_workers_label() -> void:
	var bbtext := []
	var indexes_to_remove = []
	for index in range(selected_workers_list.size()):
		var worker_text = "[url={worker_hover}]{worker_name}[/url] ([url={worker_remove}]X[/url])"
		var worker_name = selected_workers_list[index]
		# This might happen for example when we changed the current models
		# and some of the workers don't support them
		var matching_model_workers = stable_horde_workers.get_workers_with_models(current_models)
		if current_models.size() > 0 and not matching_model_workers.has(worker_name):
			indexes_to_remove.append(index)
			continue
		var worker_fmt = {
			"worker_name": worker_name,
			"worker_hover": 'hover:' + str(index),
			"worker_remove": 'delete:' + str(index),
		}
		bbtext.append(worker_text.format(worker_fmt))
	selected_workers.bbcode_text = ", ".join(bbtext)
	indexes_to_remove.invert()
	for index in indexes_to_remove:
		selected_workers_list.remove(index)
	if selected_workers_list.size() > 0:
		selected_workers.show()
	else:
		selected_workers.hide()

func _on_selected_workers_meta_clicked(meta) -> void:
	var meta_split = meta.split(":")
	match meta_split[0]:
		"hover":
			_show_worker_details(selected_workers_list[int(meta_split[1])])
		"delete":
			selected_workers_list.remove(int(meta_split[1]))
			_update_selected_workers_label()
			_emit_selected_workers()

func _on_selected_workers_meta_hover_started(meta: String) -> void:
	var meta_split = meta.split(":")
	var info = ''
	match meta_split[0]:
		"hover":
			info = "WorkerHover"
		"delete":
			info = "WorkerDelete"
	EventBus.emit_signal("rtl_meta_hovered",selected_workers,info)

func _on_selected_workers_meta_hover_ended(_meta: String) -> void:
	EventBus.emit_signal("rtl_meta_unhovered",selected_workers)

func _on_lora_info_workers_meta_clicked(meta) -> void:
# warning-ignore:return_value_discarded
	OS.shell_open(meta)

func _on_show_all_workers_pressed() -> void:
	worker_auto_complete.select_from_all()

func on_model_selection_changed(models_list) -> void:
	current_models = models_list
	worker_auto_complete.selections = stable_horde_workers.get_workers_with_models(current_models)
	_update_selected_workers_label()

func _on_blocklist_enabled(value) -> void:
	blocklist = value

func get_worker_ids() -> Array:
	var idlist = []
	for worker_name in selected_workers_list:
		var worker_reference := get_worker_reference(worker_name)
		idlist.append(worker_reference["id"])
	return idlist

class WorkerSorter:
	static func sort(m1, m2):
		if m1["fmt"]["name"] < m2["fmt"]["name"]:
			return true
		return false
