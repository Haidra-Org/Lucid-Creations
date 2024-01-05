class_name CivitAILoraReference
extends StableHordeHTTPRequest

signal reference_retrieved(models_list)
signal cache_wiped

export(String) var loras_refence_url := "https://civitai.com/api/v1/models?types=LORA&sort=Highest%20Rated&primaryFileOnly=true&limit=100"
export(String) var horde_default_loras := "https://raw.githubusercontent.com/Haidra-Org/AI-Horde-image-model-reference/main/lora.json"


var lora_reference := {}
var lora_id_index := {}
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
	#get_lora_reference()
	get_lora_reference()


func get_lora_reference() -> void:
	if state != States.READY:
		push_warning("CivitAI Lora Reference currently working. Cannot do more than 1 request at a time with the same Stable Horde Model Reference.")
		return
	state = States.WORKING
	var error = request(horde_default_loras, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		state = States.READY
		emit_signal("request_failed",error_msg)

func _get_url(query) -> String:
	var final_url : String = ''
	if typeof(query) == TYPE_ARRAY:
		var idsq = '&ids='.join(query)
		final_url = "https://civitai.com/api/v1/models?limit=100&" + idsq
	elif query.is_valid_integer():
		final_url = "https://civitai.com/api/v1/models/" + query
	# This refreshes the information of the top models
	elif query == '':
		final_url = horde_default_loras
		initialized = false
	else:
		final_url = loras_refence_url + '&nsfw=' + str(nsfw).to_lower() + '&query=' + query
	return final_url

func seek_online(query: String) -> void:
	if query == '':
		get_lora_reference()
		return
	fetch_lora_metadata(query)

func fetch_next_page(json_ret: Dictionary) -> void:
	var next_page_url = json_ret["metadata"]["nextPage"]
	var error = request(next_page_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)

func fetch_lora_metadata(query) -> void:
	var new_fetch = CivitAIModelFetch.new()
	new_fetch.connect("lora_info_retrieved",self,"_on_lora_info_retrieved")
	new_fetch.connect("lora_info_gathering_finished",self,"_on_lora_info_gathering_finished", [new_fetch])
	new_fetch.default_ids = default_ids
	add_child(new_fetch)
	new_fetch.fetch_metadata(_get_url(query))

# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) == TYPE_ARRAY:
		for id in json_ret:
			default_ids.append(str(id))
		fetch_lora_metadata(default_ids)
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
#	for entry in json_ret["items"]:
#		if initialized:
#			var lora = _parse_civitai_lora_data(entry)
#			if lora.has("versions"):
#				_store_lora(lora)
	_store_to_file()
	emit_signal("reference_retrieved", lora_reference)
	initialized = true
	state = States.READY

func _on_lora_info_retrieved(lora_details: Dictionary) -> void:
	_store_lora(lora_details)
	_store_to_file()

func _on_lora_info_gathering_finished(fetch_node: CivitAIModelFetch) -> void:
	fetch_node.queue_free()
	for child in get_children():
		if not child is CivitAIModelFetch:
			continue
		if not child.is_queued_for_deletion():
			return
	_store_to_file()
	emit_signal("reference_retrieved", lora_reference)
		
func is_lora(lora_name: String) -> bool:
	if lora_id_index.has(lora_name):
		return true
	if _get_all_lora_ids().has(lora_name):
		return true
	return(lora_reference.has(lora_name))

func get_lora_info(lora_name: String, is_version := false) -> Dictionary:
	if is_version and lora_id_index.has(lora_name):
		return lora_reference[lora_id_index[lora_name]]
	var lora_ids := _get_all_lora_ids()
	if lora_ids.has(lora_name):
		return lora_reference[lora_ids[lora_name]]
	return lora_reference.get(lora_name, {})

func get_lora_name(lora_name: String, is_version := false) -> String:
	if is_version and lora_id_index.has(lora_name):
		return lora_reference[lora_id_index[lora_name]]["name"]
	return lora_reference.get(lora_name, {}).get("name", 'N/A')

func get_latest_version(lora_name: String) -> String:
	var versions : Dictionary = lora_reference.get(lora_name, {}).get("versions", {})
	if len(versions) == 0:
		return "N/A"
	var keys := [] 
	for k in versions.keys():
		keys.append(int(k))
	keys.sort()
	return str(keys.back())

func _get_all_lora_ids() -> Dictionary:
	var all_l_id = {}
	for l in lora_reference.values():
		all_l_id[l['id']] = l['name']
	return all_l_id

func _store_to_file() -> void:
	var file = File.new()
	file.open("user://civitai_lora_reference", File.WRITE)
	file.store_var(lora_reference)
	file.close()

func _load_from_file() -> void:
	var file = File.new()
	file.open("user://civitai_lora_reference", File.READ)
	var filevar = file.get_var()
	var old_reference: Dictionary
	if filevar:
		old_reference = filevar
	for lora in old_reference.values():
		if not lora.has("versions"): 
			continue
		for version_id in lora["versions"].keys():
			lora_id_index[version_id] = lora["name"]
		lora["cached"] = true
		# Temporary while changing approach
		var unusable = lora.get("unusable", false)
		if typeof(unusable) == TYPE_BOOL and unusable == false:
			lora["unusable"] = 'Attention! This LoRa is unusable because it does not provide file validation.'
		elif typeof(unusable) == TYPE_BOOL:
			lora["unusable"] = ''
		lora_reference[lora["name"]] = lora
	file.close()
	emit_signal("reference_retrieved", lora_reference)

func calculate_downloaded_loras() -> int:
	var total_size = 0
	for lora in self.lora_reference:
		if self.lora_reference[lora].get("cached", false):
			continue
		total_size += self.lora_reference[lora]["size_mb"]
	return total_size

func set_nsfw(value) -> void:
	nsfw = value

func _store_lora(lora_data: Dictionary) -> void:
	var lora_name = lora_data["name"]
	lora_reference[lora_name] = lora_data
	for version_id in lora_data.get("versions", {}).keys():
		lora_id_index[version_id] = lora_name

func wipe_cache() -> void:
	var dir = Directory.new()
	dir.remove("user://civitai_lora_reference")
	emit_signal("cache_wiped")
	lora_reference = {}
	get_lora_reference()
