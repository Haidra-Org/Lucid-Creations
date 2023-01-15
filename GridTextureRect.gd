class_name GridTextureRect
extends PanelContainer

signal left_mouse_mouse_clicked
signal right_mouse_mouse_clicked

onready var grid_texture_rect = $"%GridTextureRect"
onready var highlight := $"%Highlight"

var texture: AIImageTexture
var aesthetic_rating: int = 0
var artifacts_rating = null # We actually use 0 and null
var bestof:= false

func _ready():
	rect_min_size = Vector2(128,128)
	grid_texture_rect.rect_min_size = Vector2(120,120)
	grid_texture_rect.expand = true
	grid_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	grid_texture_rect.texture = texture
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
	return(highlight.visible)

func set_texture(_texture) -> void:
	texture = _texture
