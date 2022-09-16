class_name StableHordeClient
extends HTTPRequest

signal images_generated(texture_list)

enum SamplerMethods {
	k_lms = 0
	k_heun
	k_euler
	k_euler_a
	k_dpm_2
	k_dpm_2_a
	DDIM
	PLMS
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
# For a server which can generate it
# Try not to go lower than 512 on both sizes, as 512 is what the model has been trained on.
export(int,64,1024,64) var width := 512
export(int,64,1024,64) var height := 512
# The steps correspond directly to the time it takes to get back your image.
# Generally there's usually no reason to go above 50 unless you know what you're doing.
export(int,1,200) var steps := 50
# Advanced: The sampler used to generate. Provides slight variations on the same prompt.
export(String, "k_lms", "k_heun", "k_euler", "k_euler_a", "k_dpm_2", "k_dpm_2_a", "DDIM", "PLMS") var sampler_name := "k_lms"
# How closely to follow the prompt given
export(float,-40,30,0.5) var cfg_scale := 7.5
# The unique seed for the prompt. If you pass a value in the seed and keep all the values the same
# The same image will always be generated.
export(String) var gen_seed := ''


var all_image_textures := []
var latest_image_textures := []

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed",self,"_on_request_completed")

func generate(replacement_prompt := '', replacement_params := {}) -> void:
	latest_image_textures.clear()
	var imgen_params = {
		"n": amount,
		"width": width,
		"height": height,
		"steps": steps,
		"sampler_name": sampler_name,
		"cfg_scale": cfg_scale,
		"seed": gen_seed,
		# You can put extra SD webui params here if you wish
	}
	for param in replacement_params:
		imgen_params[param] = replacement_params[param]
	var submit_dict = {
		"prompt": prompt,
		"api_key": api_key,
		"params": imgen_params
	}
	if replacement_prompt != '':
		submit_dict['prompt'] = replacement_prompt
	var body = to_json(submit_dict)
	var headers = ["Content-Type: application/json"]
	var error = request("https://stablehorde.net/api/v1/generate/sync", headers, false, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("Something went wrong when submitting the stable horde request")

# warning-ignore:unused_argument
func _on_request_completed(_result, response_code, _headers, body):
	var json_ret = parse_json(body.get_string_from_utf8())
	if response_code != 200 or typeof(json_ret) == TYPE_STRING:
			push_error("Error received from the Stable Horde: " + json_ret)
			return
	for img_dict in json_ret:
		var b64img = img_dict["img"]
		var base64_bytes = Marshalls.base64_to_raw(b64img)
		var image = Image.new()
		var error = image.load_webp_from_buffer(base64_bytes)
		if error != OK:
			push_error("Couldn't load the image.")
			return
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		latest_image_textures.append(texture)
		all_image_textures.append(texture)
	emit_signal("images_generated",latest_image_textures)

func get_sampler_method_id() -> String:
	return(SamplerMethods[sampler_name])
