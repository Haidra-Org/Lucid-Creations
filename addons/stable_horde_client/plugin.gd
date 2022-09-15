tool
extends EditorPlugin


const NODE_NAME = "StableHordeClient"
const INHERITANCE = "HTTPRequest"
const THE_SCRIPT = preload("stable_horde_client.gd")
const THE_ICON = preload("icon.png")


func _enter_tree():
	add_custom_type(NODE_NAME, INHERITANCE, THE_SCRIPT, THE_ICON)


func _exit_tree():
	remove_custom_type(NODE_NAME)
