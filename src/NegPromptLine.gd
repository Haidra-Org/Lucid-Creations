extends Control


var expand_idx: int
var prompt_context_menu: PopupMenu
onready var negprompt_line = $"%NegativePromptLine"


func _ready():
	prompt_context_menu = negprompt_line.get_menu()
	prompt_context_menu.add_item("Expand", 100)
	# warning-ignore:return_value_discarded
	prompt_context_menu.connect("id_pressed", self, "_on_menu_id_pressed")
	expand_idx = prompt_context_menu.get_item_index(100)

func _on_menu_id_pressed(id: int):
	if id == 100:
		toggle_expand_collapse()

func toggle_expand_collapse() -> void:
	print_debug(prompt_context_menu.get_item_text(expand_idx))
	if prompt_context_menu.get_item_text(expand_idx) == "Expand":
		expand()
	else:
		collapse()

func expand() -> void:
	prompt_context_menu.set_item_text(expand_idx, "Collapse")
	#negprompt_line.wrap_enabled = true
	rect_min_size.y = 300

func collapse() -> void:
	prompt_context_menu.set_item_text(expand_idx, "Expand")
	#negprompt_line.wrap_enabled = false
	rect_min_size.y = 0
	
