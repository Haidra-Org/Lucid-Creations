class_name CivitAIModelFetch
extends StableHordeHTTPRequest

signal lora_info_retrieved(lora_details)
signal lora_info_gathering_finished
var url: String
var default_ids : Array

func _ready() -> void:
	service_name = "CivitAI"
	# We pick the first reference immediately as we enter the scene
	timeout = 60

func fetch_metadata(final_url: String) -> void:
	if state != States.READY:
		push_warning("CivitAI Lora Reference currently working. Cannot do more than 1 request at a time with the same Stable Horde Model Reference.")
		return
	state = States.WORKING
	var error = request(final_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		state = States.READY
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
		var lora = _parse_civitai_lora_data(entry)
		emit_signal("lora_info_retrieved", lora)
	emit_signal("lora_info_gathering_finished")

func _parse_civitai_lora_data(civitai_entry) -> Dictionary:
	var lora_details = {
		"name": civitai_entry["name"],
		"id": str(civitai_entry["id"]),
		"description": civitai_entry["description"],
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
	var versions : Array = civitai_entry.get("modelVersions", {})
	if versions.size() == 0:
		return lora_details
	lora_details["versions"] = {}
	for version in versions:
		var version_id := str(version["id"])
		var new_version := {
			"unusable": '',
		}
		new_version["id"] = version_id
		new_version["triggers"] = version["trainedWords"]
		new_version["name"] = version["name"]
		new_version["base_model"] = version["baseModel"]
		for file in version["files"]:
			if not file.get("name", "").ends_with(".safetensors"):
				continue
			new_version["size_mb"] = round(file["sizeKB"] / 1024)
			# We only store these two to check if they would be present in the workers
			new_version["sha256"] = file.get("hashes", {}).get("SHA256")
			new_version["url"] = file.get("downloadUrl", "")
		# If these two fields are not defined, the workers are not going to download it
		# so we ignore it as well
		if not new_version.get("sha256"):
			new_version["unusable"] = 'Attention! This LoRa is unusable because it does not provide file validation.'
		elif not new_version.get("url"):
			new_version["unusable"] = 'Attention! This LoRa is unusable because it appears to have no valid safetensors upload.'
		elif new_version["size_mb"] > 230 and not default_ids.has(lora_details["id"]):
			new_version["unusable"] = 'Attention! This LoRa is unusable because is exceeds the max 230Mb filesize we allow on the AI Horde.'
		new_version["images"] = []
		for img in version["images"]:
			if img["nsfwLevel"] > 2:
				continue
			new_version["images"].append(img["url"])
		lora_details["versions"][version_id] = new_version
	return lora_details
