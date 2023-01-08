tool
extends EditorPlugin


const SH_HTTP_CLIENT_NAME = "StableHordeHTTPRequest"
const SH_CLIENT_NAME = "StableHordeClient"
const SH_MODELS_NAME = "StableHordeModels"
const SH_LOGIN_NAME = "StableHordeLogin"
const SH_RATE_GEN_NAME = "StableHordeRateGeneration"
const INHERITANCE = "StableHordeHTTPRequest"
const SH_HTTP_CLIENT = preload("stable_horde_httpclient.gd")
const SH_CLIENT = preload("stable_horde_client.gd")
const SH_MODELS = preload("stable_horde_models.gd")
const SH_LOGIN = preload("stable_horde_login.gd")
const SH_RATE_GEN = preload("stable_horde_rate_generation.gd")
const ICON = preload("icon.png")


func _enter_tree():
	add_custom_type(SH_HTTP_CLIENT_NAME, "HTTPRequest", SH_HTTP_CLIENT, ICON)
	add_custom_type(SH_CLIENT_NAME, INHERITANCE, SH_CLIENT, ICON)
	add_custom_type(SH_MODELS_NAME, INHERITANCE, SH_MODELS, ICON)
	add_custom_type(SH_LOGIN_NAME, INHERITANCE, SH_LOGIN, ICON)
	add_custom_type(SH_RATE_GEN_NAME, INHERITANCE, SH_RATE_GEN, ICON)


func _exit_tree():
	remove_custom_type(SH_HTTP_CLIENT_NAME)
	remove_custom_type(SH_CLIENT_NAME)
	remove_custom_type(SH_MODELS_NAME)
	remove_custom_type(SH_LOGIN_NAME)
	remove_custom_type(SH_RATE_GEN_NAME)
