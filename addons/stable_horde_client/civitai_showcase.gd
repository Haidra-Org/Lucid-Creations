class_name CivitAIShowcase
extends HTTPRequest

signal showcase_retrieved(img, model_name)
signal showcase_failed

var model_reference := {}
var texture: ImageTexture
var model_name: String
var used_image_index: int
export(int) var showcase_index := 0

func _ready():
	# warning-ignore:return_value_discarded
	timeout = 2
	connect("request_completed",self,"_on_request_completed")

func get_model_showcase(
		_model_reference: Dictionary, 
		version_id: String = '', 
		force_index = null
	) -> void:
	if force_index:
		used_image_index = force_index
	else:
		used_image_index = showcase_index
	model_reference = _model_reference
	var showcase_url: String
	if version_id != '':
		if model_reference["versions"][version_id]["images"].size() <= used_image_index:
			emit_signal("showcase_failed")
			return
		showcase_url = model_reference["versions"][version_id]["images"][used_image_index]
	else: # TODO: Convert TIs to the same format as LoRas
		if model_reference["images"].size() <= used_image_index:
			emit_signal("showcase_failed")
			return
		showcase_url = model_reference["images"][used_image_index]
		print_debug(showcase_url)
	var error = request(showcase_url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)


# warning-ignore:unused_argument
func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 0:
		var error_msg := "Model showcase address cannot be resolved!"
		emit_signal("showcase_failed")
		push_error(error_msg)
		return
	if response_code == 404:
		var error_msg := "Bad showcase URL. Please contact the developer of this addon"
		emit_signal("showcase_failed")
		push_error(error_msg)
		return
	var image = Image.new()
	var image_error = image.load_webp_from_buffer(body)
	if image_error != OK:
		image_error = image.load_png_from_buffer(body)
		if image_error != OK:
			image_error = image.load_jpg_from_buffer(body)
			if image_error != OK:
				var error_msg := "Download showcase image could not be loaded. Please contact the developer of this addon."
				emit_signal("showcase_failed")
				push_error(error_msg)
				return
	texture = ImageTexture.new()
	texture.create_from_image(image)
	emit_signal("showcase_retrieved",texture,model_name)
	
