extends VBoxContainer

const POST_PROCESSORS = [
	"GFPGAN",
	"RealESRGAN_x4plus",
]

var selected_pp := []

onready var pp_select := $"%PPSelect"
onready var pp_selected := $"%PPSelected"
onready var pp_popup : PopupMenu = pp_select.get_popup()

func _ready():
	pp_popup.clear()
	for p in POST_PROCESSORS:
		pp_popup.add_item(p)
	pp_popup.connect("index_pressed",self,"on_index_pressed")
	pp_selected.connect("meta_clicked",self,"_on_pp_meta_clicked")

func on_index_pressed(index: int) -> void:
	if POST_PROCESSORS[index] in selected_pp:
		return
	selected_pp.append(POST_PROCESSORS[index])
	_update_pp_label()

func _update_pp_label() -> void:
	var bbtext := []
	for index in range(selected_pp.size()):
		var pp_text = "{post_processor}([url={pp_x}]X[/url])"
		var pp_fmt = {
			"post_processor": selected_pp[index],
			"pp_x": index,
		}
		bbtext.append(pp_text.format(pp_fmt))
	pp_selected.bbcode_text = ", ".join(bbtext)

func _on_pp_meta_clicked(index: String) -> void:
	selected_pp.remove(int(index))
	_update_pp_label()
