class_name StableHordeRateGeneration
extends StableHordeHTTPRequest

signal generation_rated(awarded_kudos)


func submit_rating(request_id: String, ratings_payload: Dictionary) -> void:
	if state != States.READY:
		print_debug("Rating is already being processed")
		return
	state = States.WORKING
	var body = to_json(ratings_payload)
	var url = "https://stablehorde.net/api/v2/generate/rate/" + request_id
	var headers = ["Content-Type: application/json"]
	print_debug(url)
	print_debug(body)
	var error = request(url, headers, false, HTTPClient.METHOD_POST, body)
	if error != OK:
		var error_msg := "Something went wrong when initiating the stable horde request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)

# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) != TYPE_DICTIONARY:
		var error_msg : String = "Unexpected model format received"
		push_error("Unexpected model format received" + ': ' +  json_ret)
		emit_signal("request_failed",error_msg)
		state = States.READY
		return
	var awarded_kudos = json_ret["reward"]
	emit_signal("generation_rated", awarded_kudos)
	state = States.READY
