class_name WorkerSelection
extends Control

signal worker_modified(workers_list)

var selected_workers_list : Array = []
var worker_refresh: float

onready var worker_auto_complete = $"%WorkerAutoComplete"
onready var selected_workers = $"%SelectedWorkers"
onready var show_all_workers = $"%ShowAllWorkers"

onready var worker_select = $"%WorkerSelect"
onready var stable_horde_workers := $"%StableHordeWorkers"
onready var worker_info_card := $"%WorkerInfoCard"
onready var worker_info_label := $"%WorkerInfoLabel"
onready var popup_info := $"%WorkerPopupInfo"
onready var popup_info_label := $"%WorkerPopupInfoLabel"
onready var stable_horde_worker_showcase = $"%StableHordeWorkerShowcase"
onready var worker_showcase = $"%WorkerShowcase"


func _ready():
	# warning-ignore:return_value_discarded
	stable_horde_workers.connect("workers_retrieved",self, "_on_workers_retrieved")
	# warning-ignore:return_value_discarded
	worker_auto_complete.connect("item_selected", self,"_on_worker_selected")

	stable_horde_worker_showcase.connect("showcase_retrieved",self, "_on_showcase_retrieved")
	
	selected_workers.connect("meta_clicked",self,"_on_selected_workers_meta_clicked")
	selected_workers.connect("meta_hover_started",self,"_on_selected_workers_meta_hover_started")
	selected_workers.connect("meta_hover_ended",self,"_on_selected_workers_meta_hover_ended")
	worker_info_label.connect("meta_clicked",self,"_on_worker_info_workers_meta_clicked")
	show_all_workers.connect("pressed",self,"_on_show_all_workers_pressed")
# warning-ignore:return_value_discarded
	worker_info_card.connect("hide",self,"_on_workers_info_card_hide")
	stable_horde_workers.emit_workers_retrieved()
	yield(get_tree().create_timer(0.2), "timeout")
	selected_workers_list = globals.config.get_value("Parameters", "workers", [])
	_update_selected_workers_label()
	_emit_selected_workers()
	

func _process(delta):
	worker_refresh += delta
	if worker_refresh > 30:
		worker_refresh = 0
		stable_horde_workers.get_workers()

func _on_workers_retrieved(worker_performances: Array, worker_reference: Dictionary):
	var merged_reference = worker_reference.duplicate(true)
	for worker_performance in worker_performances:
		var worker_name = worker_performance['name']
		if merged_reference.has(worker_name):
			merged_reference[worker_name]["worker_count"] = worker_performance['count']
		else:
			merged_reference[worker_name] = {}
			merged_reference[worker_name]["worker_count"] = 0
	worker_auto_complete.selections = merged_reference


func get_worker_reference(worker_name: String) -> Dictionary:
	return stable_horde_workers.get_worker_info(worker_name)


func get_worker_performance(worker_name: String) -> Dictionary:
	for m in stable_horde_workers.worker_performances:
		if m['name'] == worker_name:
			return(m)
	var default_perf_dict = {
		"count": 'N/A',
		"performance": 1000000,
		"queued": 1,
		"eta": 4,
	}
	return(default_perf_dict)

func _on_request_initiated():
	stable_horde_workers.get_workers()

func _show_worker_details(worker_name: String) -> void:
	if worker_name == "Any worker":
		worker_info_label.bbcode_text = """This option will cause each image in your request to be fulfilled by workers running any worker.
As such, the result tend to be quite random as the image can be sent to something specialized which requires more specific triggers."""
	else:
		var worker_reference := get_worker_reference(worker_name)
		stable_horde_worker_showcase.get_worker_showcase(worker_reference)
		if worker_reference.empty():
			worker_info_label.bbcode_text = "No worker info could not be retrieved at this time."
		else:
			var perf = _get_worker_performance(worker_name)
			var fmt = {
				"description": worker_reference['description'],
				"version": worker_reference['version'],
				"style": worker_reference['style'],
				"trigger": worker_reference.get('trigger'),
				"homepage": worker_reference.get('homepage'),
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
			worker_info_label.bbcode_text = label_text
	worker_info_card.rect_size = Vector2(0,0)
	worker_info_card.popup()
	worker_info_card.rect_global_position = get_global_mouse_position() + Vector2(30,-worker_info_card.rect_size.y/2)

func _on_worker_info_workers_meta_clicked(meta) -> void:
# warning-ignore:return_value_discarded
	OS.shell_open(meta)

func _get_worker_performance(worker_name: String) -> Dictionary:
	var worker_performance := get_worker_performance(worker_name)
	var healthy := Color(0,1,0)
	var unhealthy := Color(1,0,0)
	# We worker the horde overloaded when there's a 20 seconds ETA to clear its current queue
	var current_pct = worker_performance['eta'] / 40
	if current_pct > 1:
		current_pct = 1
	var health_color := healthy.linear_interpolate(unhealthy,current_pct)
	return {
		"health_color": health_color.to_html(false),
		"eta": worker_performance['eta'],
		"workers": worker_performance['count'],
	}

func _on_showcase_retrieved(img:ImageTexture, _worker_name) -> void:
	worker_showcase.texture = img
	worker_showcase.rect_min_size = Vector2(400,400)

func replace_workers(workers_list: Array) -> void:
	selected_workers_list = workers_list
	_update_selected_workers_label()
	_emit_selected_workers()

func _on_worker_selected(worker_name: String) -> void:
	if worker_name in selected_workers_list:
		return
	selected_workers_list.append(worker_name)
	_update_selected_workers_label()
	_emit_selected_workers()

func _get_selected_workers() -> Array:
	var worker_defs = []
	for worker_name in selected_workers_list:
		if worker_name == "SDXL_beta::stability.ai#6901":
			worker_defs.append({
				"name": "SDXL_beta::stability.ai#6901",
				"baseline": "SDXL",
				"type": "SDXL",
				"version": "beta",
			})
		else:
			worker_defs.append(get_worker_reference(worker_name))
	return worker_defs

func _emit_selected_workers() -> void:
	EventBus.emit_signal("worker_selected", _get_selected_workers())
	emit_signal("worker_modified", _get_selected_workers())

func _update_selected_workers_label() -> void:
	var bbtext := []
	var indexes_to_remove = []
	for index in range(selected_workers_list.size()):
		var worker_text = "[url={worker_hover}]{worker_name}[/url] ([url={worker_trigger}]T[/url])([url={worker_remove}]X[/url])"
		var worker_name = selected_workers_list[index]
		# This might happen for example when we added a NSFW lora
		# but then disabled NSFW which refreshed loras to only show SFW
		if not stable_horde_workers.worker_reference.is_worker(worker_name) and worker_name != "SDXL_beta::stability.ai#6901":
			indexes_to_remove.append(index)
			continue
		if stable_horde_workers.worker_reference.get_worker_info(worker_name).get("trigger",[]).size() == 0:
			worker_text = "[url={worker_hover}]{worker_name}[/url] ([url={worker_remove}]X[/url])"
		var lora_fmt = {
			"worker_name": worker_name,
			"worker_hover": 'hover:' + str(index),
			"worker_remove": 'delete:' + str(index),
			"worker_trigger": 'trigger:' + str(index),
		}
		bbtext.append(worker_text.format(lora_fmt))
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

class WorkerSorter:
	static func sort(m1, m2):
		if m1["fmt"]["name"] < m2["fmt"]["name"]:
			return true
		return false
