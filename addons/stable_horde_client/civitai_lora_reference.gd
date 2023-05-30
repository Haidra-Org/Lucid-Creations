class_name CivitAILoraReference
extends StableHordeHTTPRequest

signal reference_retrieved(models_list)

export(String) var loras_refence_url := "https://civitai.com/api/v1/models?types=LORA&sort=Highest%20Rated&primaryFileOnly=true&limit=100"


var lora_reference := {}
var models_retrieved = false
var nsfw = true setget set_nsfw
var initialized := false

func _ready() -> void:
	service_name = "CivitAI"
	# We pick the first reference immediately as we enter the scene
	timeout = 60
	_load_from_file()
	# We do not call it from here, as set_nsfw() will also call it
	#get_lora_reference()


func get_lora_reference() -> void:
	if state != States.READY:
		push_warning("CivitAI Lora Reference currently working. Cannot do more than 1 request at a time with the same Stable Horde Model Reference.")
		return
	state = States.WORKING
	var final_url = loras_refence_url + '&nsfw=' + str(nsfw).to_lower()
#	print_debug(final_url)
	var error = request(final_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		state = States.READY
		emit_signal("request_failed",error_msg)


func seek_online(query: String) -> void:
	if state != States.READY:
		push_warning("CivitAI Lora Reference currently working. Cannot do more than 1 request at a time with the same Stable Horde Model Reference.")
		return
	var final_url : String = ''
	state = States.WORKING
	if query.is_valid_integer():
		final_url = "https://civitai.com/api/v1/models/" + query
	# This refreshes the information of the top models
	elif query == '':
		final_url = loras_refence_url + '&nsfw=' + str(nsfw).to_lower()
		initialized = false
	else:
		final_url = loras_refence_url + '&nsfw=' + str(nsfw).to_lower() + '&query=' + query
#	print_debug(final_url)
	var error = request(final_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		state = States.READY
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
	if not json_ret.has("items"):
		# Quick hack to treat individual items the same way
		json_ret["items"] = [json_ret]
	for entry in json_ret["items"]:
		if initialized or calculate_downloaded_loras() < 10000:
			var lora = _parse_civitai_lora_data(entry)
			if lora.has("size_mb"):
				lora_reference[entry["name"]] = _parse_civitai_lora_data(entry)
	_store_to_file()
	emit_signal("reference_retrieved", lora_reference)
	if calculate_downloaded_loras() < 10000:
		fetch_next_page(json_ret)
	else:
		state = States.READY
	initialized = true

func is_lora(lora_name: String) -> bool:
	return(lora_reference.has(lora_name))

func get_lora_info(lora_name: String) -> Dictionary:
	return(lora_reference.get(lora_name, {}))

func _store_to_file() -> void:
	var file = File.new()
	file.open("user://civitai_lora_reference", File.WRITE)
	file.store_var(lora_reference)
	file.close()

func _load_from_file() -> void:
	var file = File.new()
	file.open("user://civitai_lora_reference", File.READ)
	var filevar = file.get_var()
	if filevar:
		lora_reference = filevar
	for lora in lora_reference.values():
		lora["cached"] = true
	file.close()
	emit_signal("reference_retrieved", lora_reference)

func calculate_downloaded_loras() -> int:
	var total_size = 0
	for lora in self.lora_reference:
		if self.lora_reference[lora].get("cached", false):
			continue
		total_size += self.lora_reference[lora]["size_mb"]
	return total_size

func _parse_civitai_lora_data(civitai_entry) -> Dictionary:
	var lora_details = {
		"name": civitai_entry["name"],
		"id": int(civitai_entry["id"]),
		"description": civitai_entry["description"],
		"unusable": false,
	}
	if not lora_details["description"]:
		lora_details["description"] = ''
	var html_to_bbcode = {
		"<p>": '',
		"</p>": '\n',
		"</b>": '[/b]',
		"<b>": '[b]',
		"</strong>": '[/b]',
		"<strong>": '[b]',
		"</em>": '[/i]',
		"<em>": '[i]',
		"</i>": '[/i]',
		"<i>": '[i]',
		"<br />": '\n',
		"<br/>": '\n',
		"<br>": '\n',
		"<h1>": '[b][color=yellow]',
		"</h1>": '[/color][/b]\n',
		"<h2>": '[b]',
		"</h2>": '[/b]\n',
		"<h3>": '',
		"</h3>": '',
		"<u>": '[u]',
		"</u>": '[/u]',
		"<code>": '[code]',
		"</code>": '[/code]',
		"<ul>": '[ul]',
		"</ul>": '[/ul]',
		"<ol>": '[ol]',
		"</ol>": '[/ol]',
		"<li>": '',
		"</li>": '\n',
		"&lt;": '<',
		"&gt;": '>',
	}
	for repl in html_to_bbcode:
		lora_details["description"] = lora_details["description"].replace(repl,html_to_bbcode[repl])
	if lora_details["description"].length() > 500:
		lora_details["description"] = lora_details["description"].left(700) + ' [...]'
	var versions = civitai_entry.get("modelVersions", {})
	if versions.size() == 0:
		return lora_details
	lora_details["triggers"] = versions[0]["trainedWords"]
	lora_details["version"] = versions[0]["name"]
	lora_details["base_model"] = versions[0]["baseModel"]
	for file in versions[0]["files"]:
		if not file.get("name", "").ends_with(".safetensors"):
			continue
		lora_details["size_mb"] = round(file["sizeKB"] / 1024)
		# We only store these two to check if they would be present in the workers
		lora_details["sha256"] = file.get("hashes", {}).get("SHA256")
		lora_details["url"] = file.get("downloadUrl", "")
	# If these two fields are not defined, the workers are not going to download it
	# so we ignore it as well
	if not lora_details["sha256"] or not lora_details["url"]:
		lora_details["unusable"] = true
	lora_details["images"] = []
	for img in versions[0]["images"]:
		if img["nsfw"] in ["Mature", "X"]:
			continue
		lora_details["images"].append(img["url"])
	return lora_details

func set_nsfw(value) -> void:
	nsfw = value
	get_lora_reference()
