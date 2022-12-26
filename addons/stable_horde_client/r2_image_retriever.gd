class_name R2ImageRetriever
extends HTTPRequest

signal request_initiated
signal retrieval_failed(error_msg)
signal retrieval_success(image_bytes)

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed",self,"_on_request_completed")


func download_image(r2_url: String) -> void:
	var retries := 0
	var http_error = ERR_BUSY
	while http_error != OK:
		http_error = request(r2_url)
		if http_error == OK:
			break
		retries += 1
		yield(get_tree().create_timer(1), "timeout")
		if retries > 3:
			var error_msg := "Error occured during image retrieval request"
			push_error(error_msg)
			emit_signal("retrieval_failed",error_msg)
			break

# warning-ignore:unused_argument
func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 0:
			var error_msg := "Download address cannot be resolved!"
			push_error(error_msg)
			emit_signal("retrieval_failed",error_msg)
	elif response_code == 404:
			var error_msg := "Bad Image Download URL"
			push_error(error_msg)
			emit_signal("retrieval_failed",error_msg)
			return
	else:
		emit_signal("retrieval_success", body)
	queue_free()
