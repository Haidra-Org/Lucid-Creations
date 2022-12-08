class_name StableHordeHTTPRequest
extends HTTPRequest

signal request_initiated
signal request_failed(error_msg)
signal request_warning(warning_msg)

enum States {
	READY
	WORKING
	CANCELLING
}
# When set to true, we will abort the current generation and try to retrieve whatever images we can
var state : int = States.READY

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed",self,"_on_request_completed")

# warning-ignore:unused_argument
func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 0:
			var error_msg := "Stable Horde timed out"
			push_error(error_msg)
			emit_signal("request_failed",error_msg)
			state = States.READY
			return
	if response_code == 404:
			var error_msg := "Bad URL. Please contact the developer of this addon"
			push_error(error_msg)
			emit_signal("request_failed",error_msg)
			state = States.READY
			return
	var json_ret = parse_json(body.get_string_from_utf8())
	var json_error = json_ret
	if typeof(json_ret) == TYPE_DICTIONARY and json_ret.has('message'):
		json_error = str(json_ret['message'])
		if json_ret.has('errors'):
			json_error += ': ' + str(json_ret['errors'])
	if typeof(json_ret) == TYPE_NIL:
		print_debug(body)
		print_debug(body.get_string_from_utf8())
		json_error = 'Connection Lost'
	if not response_code in [200, 202] or typeof(json_ret) == TYPE_STRING:
			var error_msg : String = "Error received from the Stable Horde: " +  json_error
			push_error(error_msg)
			emit_signal("request_failed",error_msg)
			state = States.READY
			return
	if json_ret.has('message'):
		emit_signal("request_warning", json_ret['message'])
	process_request(json_ret)

# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	state = States.READY


func is_ready() -> bool:
	return(get_http_client_status() == HTTPClient.STATUS_DISCONNECTED)

