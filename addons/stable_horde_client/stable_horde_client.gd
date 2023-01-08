class_name StableHordeClient
extends StableHordeHTTPRequest

signal images_generated(completed_payload)
signal image_processing(stats)

enum SamplerMethods {
	k_lms = 0
	k_heun
	k_euler
	k_euler_a
	k_dpm_2
	k_dpm_2_a
	k_dpm_fast
	k_dpm_adaptive
	k_dpmpp_2s_a
	k_dpmpp_2m
	dpmsolver
}

enum OngoingRequestOperations {
	CHECK
	GET
	CANCEL
}

export(String) var prompt = "A horde of cute blue robots with gears on their head"
# The API key you've generated from https://stablehorde.net/register
# You can pass either your own key (make sure you encrypt your app)
# Or ask each player to register on their own
# You can also pass the 0000000000 Anonymous key, but it has the lowest priority
export(String) var api_key := '0000000000'
# How many images following the same prompt to do
export(int) var amount := 1
# The exact size of the image to generate. If you put too high, you might have to wait longer
# For a worker which can generate it
# Try not to go lower than 512 on both sizes, as 512 is what the model has been trained on.
export(int,64,1024,64) var width := 512
export(int,64,1024,64) var height := 512
# The steps correspond directly to the time it takes to get back your image.
# Generally there's usually no reason to go above 50 unless you know what you're doing.
export(int,1,100) var steps := 30
# Advanced: The sampler used to generate. Provides slight variations on the same prompt.
export(String, "k_lms", "k_heun", "k_euler", "k_euler_a", "k_dpm_2", "k_dpm_2_a", "k_dpm_fast", "k_dpm_adaptive", "k_dpmpp_2s_a", "k_dpmpp_2m", "dpmsolver") var sampler_name := "k_euler_a"
# How closely to follow the prompt given
export(float,-40,30,0.5) var cfg_scale := 7.5
# How closely to follow the source image in img2img
export(float,0,1,0.01) var denoising_strength := 0.7
# The unique seed for the prompt. If you pass a value in the seed and keep all the values the same
# The same image will always be generated.
export(String) var gen_seed := ''
# Advanced: The sampler used to generate. Provides slight variations on the same prompt.
export(Array) var post_processing := []
# If set to True, will enable the karras noise scheduler
export(bool) var karras := true
# If set to True, will mark this generation as NSFW and only workers which accept NSFW requests
# Will fulfill it
export(bool) var nsfw := false
# Only active is nsfw == false
# Will request workers to censor accidentally generated NSFW images. 
# If set to false, and a sfw request accidently generates nsfw content, the worker
# will automatically set it to a black image.
export(bool) var censor_nsfw := true
# When true, will allow untrusted workers to also generate for this request.
export(bool) var trusted_workers := true
# The model to be used to generate this request. If you change this, use the StableHordeModels class 
# To ensure there is a worker serving that model first.
# An empty array here picks the first available models from the workers
export(Array) var models := ["stable_diffusion"]
export(Image) var source_image
# If true, the image will be sent as a URL to download instead of a base64 string
export(bool) var r2 := true
# If true, the image will be stored permanently in a dataset that will be provided to LAION
# top help train future models
export(bool) var shared := true

var all_image_textures := []
var latest_image_textures := []
# The open request UUID to track its status
var async_request_id : String
# We store the params sent to the current generation, then pass them to the AIImageTexture to remember them
# They are replaced every time a new generation begins
var imgen_params : Dictionary
# When set to true, we will abort the current generation and try to retrieve whatever images we can
var request_start_time : float # We use that to get the accurate amount of time the request took
var async_retrievals_completed = 0

func generate(replacement_prompt := '', replacement_params := {}) -> void:
	if state != States.READY:
		push_error("Client currently working. Cannot do more than 1 request at a time with the same Stable Horde Client.")
		return
	request_start_time = OS.get_ticks_msec()
	state = States.WORKING
	latest_image_textures.clear()
	async_request_id = ''
	imgen_params = {
		"n": amount,
		"width": width,
		"height": height,
		"steps": steps,
		"sampler_name": sampler_name,
		"karras": karras,
		"cfg_scale": cfg_scale,
		"seed": gen_seed,
		"post_processing": post_processing,
	}
	for param in replacement_params:
		imgen_params[param] = replacement_params[param]
	var submit_dict = {
		"prompt": prompt,
		"params": imgen_params,
		"nsfw": nsfw,
		"censor_nsfw": censor_nsfw,
		"trusted_workers": trusted_workers,
		"models": models,
		"r2": r2,
		"shared": shared,
	}
	#print_debug(submit_dict)
	if source_image:
		submit_dict["source_image"] = get_img2img_b64(source_image)
		submit_dict["params"]["denoising_strength"] = denoising_strength
	if replacement_prompt != '':
		submit_dict['prompt'] = replacement_prompt
	var body = to_json(submit_dict)
	var headers = ["Content-Type: application/json", "apikey: " + api_key]
	var error = request("https://stablehorde.net/api/v2/generate/async", headers, false, HTTPClient.METHOD_POST, body)
	if error != OK:
		var error_msg := "Something went wrong when initiating the stable horde request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)
	emit_signal("request_initiated")

# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) == TYPE_ARRAY:
		_extract_images(json_ret)
		return
	if 'generations' in json_ret:
		_extract_images(json_ret['generations'])
		return
	if state ==States.CANCELLING:
		check_request_process(OngoingRequestOperations.CANCEL)
	if 'id' in json_ret:
		async_request_id = json_ret['id']
		check_request_process(OngoingRequestOperations.CHECK)
	if 'done' in json_ret:
		var operation = OngoingRequestOperations.CHECK
		if json_ret['done']:
			operation = OngoingRequestOperations.GET
		elif state == States.WORKING:
			json_ret["elapsed_time"] = OS.get_ticks_msec() - request_start_time
			emit_signal("image_processing", json_ret)
		check_request_process(operation)


func check_request_process(operation := OngoingRequestOperations.CHECK) -> void:
	# We do one check request per second
	yield(get_tree().create_timer(1), "timeout")
	var url = "https://stablehorde.net/api/v2/generate/check/" + async_request_id
	var method = HTTPClient.METHOD_GET
	if operation == OngoingRequestOperations.GET:
		url = "https://stablehorde.net/api/v2/generate/status/" + async_request_id
	elif operation == OngoingRequestOperations.CANCEL:
		url = "https://stablehorde.net/api/v2/generate/status/" + async_request_id
		method = HTTPClient.METHOD_DELETE
	var error = request(url, [], false, method)
	if state == States.WORKING and error != OK:
		var error_msg := "Something went wrong when checking the status of Stable Horde Request: " + async_request_id
		push_error(error_msg)
		emit_signal("request_failed",error_msg)
	elif state == States.CANCELLING and not error in [ERR_BUSY, OK] :
		var error_msg := "Something went wrong when cancelling the Stable Horde Request: " + async_request_id
		push_error(error_msg)
		emit_signal("request_failed",error_msg)


func _extract_images(generations_array: Array) -> void:
	var timestamp := OS.get_unix_time()
	for img_dict in generations_array:
		var error
		var image: Image
		async_retrievals_completed = 0
		if 'https' in img_dict["img"]:
			var image_retriever := R2ImageRetriever.new()
			add_child(image_retriever)
			image_retriever.connect(
					"retrieval_failed", 
					self, 
					"_on_r2_retrieval_failed", 
					[generations_array.size()])
			image_retriever.connect(
					"retrieval_success", 
					self, 
					"_on_r2_retrieval_success", 
					[img_dict,  timestamp, generations_array.size()])
			image_retriever.download_image(img_dict["img"])
		else:
			var b64img = img_dict["img"]
			var base64_bytes = Marshalls.base64_to_raw(b64img)
			# Just in case a worker sends us randomly a b64
			async_retrievals_completed += 1
			prepare_aitexture(base64_bytes, img_dict, timestamp)
	if not r2:
		complete_image_request()

func prepare_aitexture(imgbuffer: PoolByteArray, img_dict: Dictionary, timestamp: int) -> AIImageTexture:
	var image = Image.new()
	var error = image.load_webp_from_buffer(imgbuffer)
	if error != OK:
		var error_msg := "Couldn't load the image."
		push_error(error_msg)
		emit_signal("request_failed",error_msg)
		return null
	var texture = AIImageTexture.new(
		prompt,
		imgen_params,
		img_dict["seed"],
		img_dict["model"],
		img_dict["worker_id"],
		img_dict["worker_name"],
		timestamp,
		image,
		img_dict["id"])
	texture.create_from_image(image)
	latest_image_textures.append(texture)
	# Avoid keeping all images in RAM. Until I find a reason for it.
#	all_image_textures.append(texture)
	return texture

func complete_image_request() -> void:
	var completed_payload = {
		"image_textures": latest_image_textures,
		"elapsed_time": OS.get_ticks_msec() - request_start_time
	}
	request_start_time = 0
	emit_signal("images_generated",completed_payload)
	state = States.READY

func _on_r2_retrieval_success(image_bytes: PoolByteArray, img_dict: Dictionary, timestamp: int, expected_amount: int) -> void:
	prepare_aitexture(image_bytes, img_dict, timestamp)
	async_retrievals_completed += 1
	if async_retrievals_completed >= expected_amount:
		complete_image_request()

func _on_r2_retrieval_failed(error_msg: String, expected_amount: int) -> void:
	async_retrievals_completed += 1
	if async_retrievals_completed >= expected_amount:
		complete_image_request()

func get_sampler_method_id() -> String:
	return(SamplerMethods[sampler_name])

func cancel_request() -> void:
	print_debug("Cancelling...")
	state = States.CANCELLING

func get_img2img_b64(image: Image) -> String:
	var imgbuffer = image.save_png_to_buffer()
	return(Marshalls.raw_to_base64(imgbuffer))
	
