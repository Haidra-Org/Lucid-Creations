class_name StableHordeWorkers
extends StableHordeHTTPRequest

signal workers_retrieved(workers_list)

var worker_results := []
var workers_by_id := {}
var workers_by_name := {}
var workers_retrieved = false

func _ready() -> void:
	get_workers()


func get_workers() -> void:
	if state != States.READY:
		print_debug("Workers currently working. Cannot do more than 1 request at a time with the same Stable Horde Models.")
		return
	state = States.WORKING
	var error = request(aihorde_url + "/api/v2/workers?type=image", [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the stable horde request"
		push_error(error_msg)
		state = States.READY
		emit_signal("request_failed",error_msg)


# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) != TYPE_ARRAY:
		var error_msg : String = "Unexpected worker format received"
		push_error("Unexpected worker format received" + ': ' +  json_ret)
		emit_signal("request_failed",error_msg)
		state = States.READY
		return
	worker_results = json_ret
	for worker in worker_results:
		workers_by_id[worker.id] = worker
		workers_by_name[worker.name] = worker
	emit_signal("workers_retrieved", workers_by_name)
	state = States.READY

func emit_models_retrieved() -> void:
	emit_signal("workers_retrieved", worker_results)

func get_worker_info(worker_string: String) -> Dictionary:
	if workers_by_id.has(worker_string):
		return workers_by_id[worker_string]
	if workers_by_name.has(worker_string):
		return workers_by_name[worker_string]
	return {}

func is_worker(worker_string: String) -> bool:
	return not get_worker_info(worker_string).empty()

func get_workers_with_models(models: Array) -> Dictionary:
#	for w in workers_by_name:
#		print([w])
	if models.size() == 0:
		return workers_by_name
	var ret: Dictionary = {}
	for worker_name in workers_by_name:
		for model in models:
			if workers_by_name[worker_name]["models"].has(model.name) and not ret.has(worker_name):
				ret[worker_name] = workers_by_name[worker_name]
	return ret
