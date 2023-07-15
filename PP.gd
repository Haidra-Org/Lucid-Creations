class_name PostProcessingSelection
extends VBoxContainer

# warning-ignore:unused_signal
signal meta_hovered(description)
# warning-ignore:unused_signal
signal meta_unhovered
signal pp_modified(pp_list)

const POST_PROCESSORS = [
	"GFPGAN",
	"RealESRGAN_x4plus",
	"CodeFormers",
	"strip_background",
	"RealESRGAN_x2plus", 
	"RealESRGAN_x4plus_anime_6B", 
	"NMKD_Siax",
	"4x_AnimeSharp"
]

var selected_pp := []

onready var pp_select := $"%PPSelect"
onready var pp_selected := $"%PPSelected"
onready var pp_popup : PopupMenu = pp_select.get_popup()

func _ready():
	pp_popup.clear()
	for p in POST_PROCESSORS:
		pp_popup.add_item(p)
	selected_pp = globals.config.get_value("Parameters", "post_processing", [])
	_update_pp_label()
	# warning-ignore:return_value_discarded
	pp_popup.connect("index_pressed",self,"on_index_pressed")
	# warning-ignore:return_value_discarded
	pp_selected.connect("meta_clicked",self,"_on_pp_meta_clicked")
	# warning-ignore:return_value_discarded
	pp_selected.connect("meta_hover_started", self, "_on_meta_hover_started")
	# warning-ignore:return_value_discarded
	pp_selected.connect("meta_hover_ended", self, "_on_meta_hover_ended")

func on_index_pressed(index: int) -> void:
	if POST_PROCESSORS[index] in selected_pp:
		return
	selected_pp.append(POST_PROCESSORS[index])
	globals.set_setting("post_processing",selected_pp)
	_update_pp_label()

func replace_pp(pp_list: Array) -> void:
	selected_pp = pp_list
	globals.set_setting("post_processing",selected_pp)
	_update_pp_label()

func _update_pp_label() -> void:
	var bbtext := []
	for index in range(selected_pp.size()):
		var pp_text = "[url={pp_hover}]{post_processor}[/url] ([url={pp_x}]X[/url])"
		var pp_fmt = {
			"post_processor": selected_pp[index],
			"pp_x": index,
			"pp_hover": 'hover:' + selected_pp[index],
		}
		bbtext.append(pp_text.format(pp_fmt))
	pp_selected.bbcode_text = ", ".join(bbtext)
	emit_signal("pp_modified", selected_pp)

func _on_pp_meta_clicked(index: String) -> void:
	if "hover" in index:
		return
	selected_pp.remove(int(index))
	globals.set_setting("post_processing",selected_pp)
	_update_pp_label()

func _on_meta_hover_started(meta: String) -> void:
	if not "hover" in meta:
		return
	var pp = meta.split(":")[1]
	EventBus.emit_signal("rtl_meta_hovered",pp_selected,pp)


func _on_meta_hover_ended(meta: String) -> void:
	if not "hover" in meta:
		return
	EventBus.emit_signal("rtl_meta_unhovered",pp_selected)


