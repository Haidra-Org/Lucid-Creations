class_name CivitAILoraReference
extends StableHordeHTTPRequest

signal reference_retrieved(models_list)

export(String) var loras_refence_url := "https://civitai.com/api/v1/models?types=LORA&sort=Highest%20Rated&primaryFileOnly=true&limit=100"


var model_reference := {}
var models_retrieved = false
var nsfw = true

func _ready() -> void:
	service_name = "CivitAI"
	# We pick the first reference immediately as we enter the scene
	timeout = 60
	get_model_reference()


func get_model_reference() -> void:
	_load_from_file()
	if state != States.READY:
		push_warning("CivitAI Lora Reference currently working. Cannot do more than 1 request at a time with the same Stable Horde Model Reference.")
		return
	state = States.WORKING
	var final_url = loras_refence_url + '&' + str(nsfw).to_lower()
	var error = request(final_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)

func fetch_next_page(json_ret: Dictionary) -> void:
	var next_page_url = json_ret["metadata"]["nextPage"]
	var error = request(next_page_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)

# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) != TYPE_DICTIONARY:
		var error_msg : String = "Unexpected model reference received"
		push_error("Unexpected model reference received" + ': ' +  str(json_ret))
		emit_signal("request_failed",error_msg)
		state = States.READY
		return
	model_reference = {}
	for entry in json_ret["items"]:
		if calculate_downloaded_loras() < 10000:
			var lora = _parse_civitai_lora_data(entry)
			if lora.has("size_mb"):
				model_reference[entry["name"]] = _parse_civitai_lora_data(entry)
	_store_to_file()
	emit_signal("reference_retrieved", model_reference)
	if calculate_downloaded_loras() < 10000:
		fetch_next_page(json_ret)
	else:
		state = States.READY

func get_model_info(model_name: String) -> Dictionary:
	return(model_reference.get(model_name, {}))

func _store_to_file() -> void:
	var file = File.new()
	file.open("user://civitai_lora_reference", File.WRITE)
	file.store_var(model_reference)
	file.close()

func _load_from_file() -> void:
	var file = File.new()
	file.open("user://civitai_lora_reference", File.READ)
	var filevar = file.get_var()
	if filevar:
		model_reference = filevar
	file.close()

func calculate_downloaded_loras() -> int:
	var total_size = 0
	for lora in self.model_reference:
		total_size += self.model_reference[lora]["size_mb"]
	return total_size

func _parse_civitai_lora_data(civitai_entry) -> Dictionary:
	var lora_details = {
		"name": civitai_entry["name"],
		"id": civitai_entry["id"],
		"description": civitai_entry["description"],
	}
	var versions = civitai_entry.get("modelVersions", {})
	if versions.size() == 0:
		return lora_details
	for file in versions[0]["files"]:
		lora_details["size_mb"] = round(file["sizeKB"] / 1024)
	return lora_details
	
