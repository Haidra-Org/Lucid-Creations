class_name StableHordeModelShowcase
extends HTTPRequest

signal showcase_retrieved(img, model_name)

var model_reference := {}
var texture: ImageTexture
var model_name: String

func _ready():
	# warning-ignore:return_value_discarded
	timeout = 2
	connect("request_completed",self,"_on_request_completed")

func get_model_showcase(_model_reference) -> void:
	model_reference = _model_reference
	model_name = model_reference.get("name","stable_diffusion")
	if not model_reference.has("showcases"):
		return
	var showcase_list = model_reference.showcases
	Utils.shuffle_array(showcase_list)
	var showcase_url = showcase_list[0]
	var error = request(showcase_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)


# warning-ignore:unused_argument
func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 0:
		var error_msg := "Model showcase address cannot be resolved!"
		push_error(error_msg)
		return
	if response_code == 404:
		var error_msg := "Bad showcase URL. Please contact the developer of this addon"
		push_error(error_msg)
		return
	var image = Image.new()
	var image_error = image.load_webp_from_buffer(body)
	if image_error != OK:
		image_error = image.load_jpg_from_buffer(body)
		if image_error != OK:
			var error_msg := "Download showcase image could not be loaded. Please contact the developer of this addon"
			push_error(error_msg)
			return
	texture = ImageTexture.new()
	texture.create_from_image(image)
	emit_signal("showcase_retrieved",texture,model_name)
	
