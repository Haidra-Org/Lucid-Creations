class_name CivitAITIReference
extends StableHordeHTTPRequest

signal reference_retrieved(models_list)

export(String) var tis_refence_url := "https://civitai.com/api/v1/models?types=TextualInversion&sort=Highest%20Rated&primaryFileOnly=true&limit=100"


var ti_reference := {}
var ti_id_index := {}
var models_retrieved = false
var nsfw = true setget set_nsfw
var initialized := false
var default_ids : Array


func _ready() -> void:
	service_name = "CivitAI"
	# We pick the first reference immediately as we enter the scene
	timeout = 60
	_load_from_file()
	# We do not call it from here, as set_nsfw() will also call it
	#get_ti_reference()

func _get_url(query) -> String:
	var final_url : String = ''
	if typeof(query) == TYPE_ARRAY:
		var idsq = '&ids='.join(query)
		final_url = "https://civitai.com/api/v1/models?limit=100&" + idsq
	elif query.is_valid_integer():
		final_url = "https://civitai.com/api/v1/models/" + query
#	elif query == '':
#		initialized = false
	else:
		final_url = tis_refence_url + '&nsfw=' + str(nsfw).to_lower() + '&query=' + query
	return final_url

func seek_online(query: String) -> void:
	if query == '':
		return
	fetch_ti_metadata(query)

func fetch_next_page(json_ret: Dictionary) -> void:
	var next_page_url = json_ret["metadata"]["nextPage"]
	var error = request(next_page_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)

func fetch_ti_metadata(query) -> void:
	var new_fetch = CivitAITextualInversionModelFetch.new()
	new_fetch.connect("ti_info_retrieved",self,"_on_ti_info_retrieved")
	new_fetch.connect("ti_info_gathering_finished",self,"_on_ti_info_gathering_finished", [new_fetch])
	new_fetch.default_ids = default_ids
	add_child(new_fetch)
	new_fetch.fetch_metadata(_get_url(query))

# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) == TYPE_ARRAY:
		default_ids = json_ret
		fetch_ti_metadata(default_ids)
		state = States.READY
		return
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
		if initialized:
			var ti = _parse_civitai_ti_data(entry)
			if ti.has("size_mb"):
				_store_ti(ti)
	_store_to_file()
	emit_signal("reference_retrieved", ti_reference)
	initialized = true
	state = States.READY

func _on_ti_info_retrieved(ti_details: Dictionary) -> void:
	_store_ti(ti_details)
	_store_to_file()

func _on_ti_info_gathering_finished(fetch_node: CivitAITextualInversionModelFetch) -> void:
	fetch_node.queue_free()
	for child in get_children():
		if not child is CivitAITextualInversionModelFetch:
			continue
		if not child.is_queued_for_deletion():
			return
	_store_to_file()
	emit_signal("reference_retrieved", ti_reference)
		
func is_ti(ti_name: String) -> bool:
	if ti_id_index.has(int(ti_name)):
		return true
	return(ti_reference.has(ti_name))

func get_ti_info(ti_name: String) -> Dictionary:
	if ti_id_index.has(int(ti_name)):
		return ti_reference[ti_id_index[int(ti_name)]]
	return ti_reference.get(ti_name, {})

func get_ti_name(ti_name: String) -> String:
	if ti_id_index.has(int(ti_name)):
		return ti_reference[ti_id_index[int(ti_name)]]["name"]
	return ti_reference.get(ti_name, {}).get("name", 'N/A')

func _store_to_file() -> void:
	var file = File.new()
	file.open("user://civitai_ti_reference", File.WRITE)
	file.store_var(ti_reference)
	file.close()

func _load_from_file() -> void:
	var file = File.new()
	file.open("user://civitai_ti_reference", File.READ)
	var filevar = file.get_var()
	if filevar:
		ti_reference = filevar
	for ti in ti_reference.values():
		ti_id_index[int(ti["id"])] = ti["name"]
		ti["cached"] = true
		# Temporary while changing approach
		var unusable = ti.get("unusable", false)
		if typeof(unusable) == TYPE_BOOL and unusable == false:
			ti["unusable"] = 'Attention! This Textual Inversion is unusable because it does not provide file validation.'
		elif typeof(unusable) == TYPE_BOOL:
			ti["unusable"] = ''
	file.close()
	emit_signal("reference_retrieved", ti_reference)

func _parse_civitai_ti_data(civitai_entry) -> Dictionary:
	var ti_details = {
		"name": civitai_entry["name"],
		"id": int(civitai_entry["id"]),
		"description": civitai_entry["description"],
		"unusable": '',
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
	if not ti_details["sha256"]:
		ti_details["unusable"] = 'Attention! This Textual Inversion is unusable because it does not provide file validation.'
	elif not ti_details["url"]:
		ti_details["unusable"] = 'Attention! This Textual Inversion is unusable because it appears to have no valid safetensors upload.'
	elif ti_details["size_mb"] > 150:
		ti_details["unusable"] = 'Attention! This Textual Inversion is unusable because is exceeds the max 150Mb filesize we allow on the AI Horde.'
	ti_details["images"] = []
	for img in versions[0]["images"]:
		if img["nsfw"] in ["Mature", "X"]:
			continue
		ti_details["images"].append(img["url"])
	return ti_details

func set_nsfw(value) -> void:
	nsfw = value

func _store_ti(ti_data: Dictionary) -> void:
	var ti_name = ti_data["name"]
	ti_reference[ti_name] = ti_data
	ti_id_index[int(ti_data["id"])] = ti_name
