tool
extends EditorPlugin


const SH_CLIENT_NAME = "StableHordeClient"
const SH_MODELS_NAME = "StableHordeModels"
const INHERITANCE = "HTTPRequest"
const SH_CLIENT = preload("stable_horde_client.gd")
const SH_MODELS = preload("stable_horde_client.gd")
const ICON = preload("icon.png")


func _enter_tree():
	add_custom_type(SH_CLIENT_NAME, INHERITANCE, SH_CLIENT, ICON)
	add_custom_type(SH_MODELS_NAME, 'StableHordeHTTPRequest', SH_MODELS, ICON)


func _exit_tree():
	remove_custom_type(SH_CLIENT_NAME)
	remove_custom_type(SH_MODELS_NAME)
