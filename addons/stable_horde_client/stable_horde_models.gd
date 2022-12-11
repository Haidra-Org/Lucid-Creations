class_name StableHordeModels
extends StableHordeHTTPRequest

signal models_retrieved(models_list, model_reference)

var model_performances := []
var model_names := []
var models_retrieved = false
var model_reference: StableHordeModelReference

func _ready() -> void:
	model_reference = StableHordeModelReference.new()
	timeout = 2
	add_child(model_reference)
	

func get_models() -> void:
	if state != States.READY:
		print_debug("Models currently working. Cannot do more than 1 request at a time with the same Stable Horde Models.")
		return
	state = States.WORKING
	var error = request("https://stablehorde.net/api/v2/status/models", [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the stable horde request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)


# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) != TYPE_ARRAY:
		var error_msg : String = "Unexpected model format received"
		push_error("Unexpected model format received" + ': ' +  json_ret)
		emit_signal("request_failed",error_msg)
		state = States.READY
		return
	model_performances = json_ret
	model_names.clear()
	for entry in model_performances:
		model_names.append(entry.name)
	emit_signal("models_retrieved", model_performances, model_reference.model_reference)
	state = States.READY
