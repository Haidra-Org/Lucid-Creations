class_name GridTextureRect
extends TextureRect

signal left_mouse_mouse_clicked
signal right_mouse_mouse_clicked
onready var highlight := $"%Highlight"

func _init():
	rect_min_size = Vector2(128,128)
	expand = true
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
func _ready():
	# warning-ignore:return_value_discarded
	connect("gui_input",self, "_on_gui_input")

func clear_highlight() -> void:
	highlight.hide()

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == 1:
			emit_signal("left_mouse_mouse_clicked")
			if not highlight.visible:
				highlight.show()
			else:
				clear_highlight()
		if event.get_button_index() == 2:
			clear_highlight()
			emit_signal("right_mouse_mouse_clicked")

func is_highlighted() -> bool:
	print_debug(highlight.visible)
	return(highlight.visible)
