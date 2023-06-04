extends LineEdit

enum PopupPosition {
	BELOW = 0
	RIGHT
	BOTH
}
# Emitted whenever an item is selected
signal item_selected(item)

# The dictionary with the options from which to select
export(Dictionary) var selections = {}
# The extra keys in the dictionary which to use to match items
export(Array) var seek_keys := ["name", "description"]
export(Array) var description_keys := []
export(String) var description_format := '{item}'
export(PopupPosition) var popup_position := PopupPosition.BELOW
onready var auto_complete_select := $"%AutoCompleteSelect"

func _ready():
	for item in selections:
		auto_complete_select.add_item(item)
	
func _on_TextAutoComplete_text_changed(new_text: String, show_all=false):
	if new_text == '' and not show_all:
		auto_complete_select.hide()
		return
	auto_complete_select.clear()
	auto_complete_select.add_item('Cancel')
	var iter = 1
	for item in selections:
		if show_all:
			_add_item(item,iter)
			iter += 1
		elif new_text.to_lower() in item.to_lower():
			_add_item(item,iter)
			iter += 1
		else:
			for skey in seek_keys:
				if not selections.has(item):
					continue
				if not selections[item].get(skey):
					continue
				if new_text.to_lower() in str(selections[item][skey]).to_lower():
					_add_item(item,iter)
					iter += 1
					break
		if iter >= 6 and not show_all:
			break
	auto_complete_select.rect_size = Vector2(0,0)
	auto_complete_select.show()
	if popup_position == PopupPosition.BELOW:
		auto_complete_select.rect_global_position.y = get_parent().rect_global_position.y + get_parent().rect_size.y
	elif popup_position == PopupPosition.RIGHT:
		auto_complete_select.rect_global_position.x = get_parent().rect_global_position.x + get_parent().rect_size.x
		auto_complete_select.rect_global_position.y = get_parent().rect_global_position.y - (auto_complete_select.rect_size.y / 2)
	elif popup_position == PopupPosition.BOTH:
		auto_complete_select.rect_global_position = get_parent().rect_global_position + get_parent().rect_size

func _add_item(item_key, id: int) -> void:
	var fmt = {
		"item": item_key
	}
	for key in description_keys:
		if selections[item_key].has(key):
			fmt[key] = selections[item_key][key]
	var item_desc = description_format.format(fmt)
	auto_complete_select.add_item(item_desc,id)
	var idx = auto_complete_select.get_item_index(id)
	auto_complete_select.set_item_metadata(idx,item_key)
	
	
func _on_AutoCompleteSelect_index_pressed(index):
	if index == 0:
		return
	emit_signal("item_selected", auto_complete_select.get_item_metadata(index))
	self.text = ''

func select_from_all() -> void:
	_on_TextAutoComplete_text_changed('', true)

func initiate_search() -> void:
	_on_TextAutoComplete_text_changed(text)
