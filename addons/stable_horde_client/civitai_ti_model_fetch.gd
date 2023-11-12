class_name CivitAITextualInversionModelFetch
extends StableHordeHTTPRequest

signal ti_info_retrieved(ti_details)
signal ti_info_gathering_finished
var url: String
var default_ids : Array

func _ready() -> void:
	service_name = "CivitAI"
	# We pick the first reference immediately as we enter the scene
	timeout = 60

func fetch_metadata(final_url: String) -> void:
	if state != States.READY:
		push_warning("CivitAI Textual Inversion Reference currently working. Cannot do more than 1 request at a time with the same Stable Horde Model Reference.")
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
		var ti = _parse_civitai_ti_data(entry)
		emit_signal("ti_info_retrieved", ti)
	emit_signal("ti_info_gathering_finished")

func _parse_civitai_ti_data(civitai_entry) -> Dictionary:
	var ti_details = {
		"name": civitai_entry["name"],
		"id": int(civitai_entry["id"]),
		"description": civitai_entry["description"],
		"unusable": '',
		"nsfw": civitai_entry["nsfw"],
		"sha256": null,
	}
	if not ti_details["description"]:
		ti_details["description"] = ''
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
		ti_details["description"] = ti_details["description"].replace(repl,html_to_bbcode[repl])
	if ti_details["description"].length() > 500:
		ti_details["description"] = ti_details["description"].left(700) + ' [...]'
	var versions = civitai_entry.get("modelVersions", {})
	if versions.size() == 0:
		return ti_details
	ti_details["triggers"] = versions[0]["trainedWords"]
	ti_details["version"] = versions[0]["name"]
	ti_details["base_model"] = versions[0]["baseModel"]
	for file in versions[0]["files"]:
		ti_details["size_mb"] = round(file["sizeKB"] / 1024)
		# We only store these two to check if they would be present in the workers
		ti_details["sha256"] = file.get("hashes", {}).get("SHA256")
		ti_details["url"] = file.get("downloadUrl", "")
	# If these two fields are not defined, the workers are not going to download it
	# so we ignore it as well
	var is_default = int(ti_details["id"]) in default_ids
	if not is_default and not ti_details["sha256"]:
		ti_details["unusable"] = 'Attention! This Textual Inversion is unusable because it does not provide file validation.'
	elif not ti_details["url"]:
		ti_details["unusable"] = 'Attention! This Textual Inversion is unusable because it appears to have no valid safetensors upload.'
	elif not is_default and ti_details["size_mb"] > 230:
		ti_details["unusable"] = 'Attention! This Textual Inversion is unusable because is exceeds the max 230Mb filesize we allow on the AI Horde.'
	ti_details["images"] = []
	for img in versions[0]["images"]:
		if img["nsfw"] in ["Mature", "X"]:
			continue
		ti_details["images"].append(img["url"])
	return ti_details
