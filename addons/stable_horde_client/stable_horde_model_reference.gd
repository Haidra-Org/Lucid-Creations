class_name StableHordeModelReference
extends StableHordeHTTPRequest

signal reference_retrieved(models_list)

export(String) var compvis_refence_url := "https://raw.githubusercontent.com/db0/AI-Horde-image-model-reference/main/stable_diffusion.json"
export(String) var diffusers_refence_url := "https://raw.githubusercontent.com/db0/AI-Horde-image-model-reference/main/diffusers.json"

var model_reference := {}
var models_retrieved = false

func _ready() -> void:
	# We pick the first reference immediately as we enter the scene
	timeout = 2
	get_model_reference()

func get_model_reference() -> void:
	_load_from_file()
	if state != States.READY:
		push_warning("Model Reference currently working. Cannot do more than 1 request at a time with the same Stable Horde Model Reference.")
		return
	state = States.WORKING
	var error = request(compvis_refence_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)


# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) != TYPE_DICTIONARY:
		var error_msg : String = "Unexpected model reference received"
		push_error("Unexpected model reference received" + ': ' +  json_ret)
		emit_signal("request_failed",error_msg)
		state = States.READY
		return
	model_reference = json_ret
	_store_to_file()
	emit_signal("reference_retrieved", model_reference)
	state = States.READY

func get_model_info(model_name: String) -> Dictionary:
	return(model_reference.get(model_name, {}))

func _store_to_file() -> void:
	var file = File.new()
	file.open("user://model_reference", File.WRITE)
	file.store_var(model_reference)
	file.close()

func _load_from_file() -> void:
	var file = File.new()
	file.open("user://model_reference", File.READ)
	var filevar = file.get_var()
	if filevar:
		model_reference = filevar
	file.close()
