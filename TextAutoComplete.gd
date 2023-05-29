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
export(PopupPosition) var popup_position := PopupPosition.BELOW
onready var auto_complete_select := $"%AutoCompleteSelect"

func _ready():
	for item in selections:
		auto_complete_select.add_item(item)
	
func _on_TextAutoComplete_text_changed(new_text: String, show_all=false):
	if new_text == '' and not show_all:
		auto_complete_select.get_popup().hide()
		return
	auto_complete_select.clear()
	auto_complete_select.add_item('None')
	var iter = 0
	for item in selections:
		if show_all:
			auto_complete_select.add_item(item)
		elif new_text.to_lower() in item.to_lower():
			auto_complete_select.add_item(item)
			iter += 1
		else:
			for skey in seek_keys:
				if not selections[item][skey]:
					continue
				if new_text.to_lower() in selections[item][skey].to_lower():
					auto_complete_select.add_item(item)
					iter += 1
					break
		if iter >= 6 and not show_all:
			break
	auto_complete_select.get_popup().rect_size = Vector2(0,0)
	auto_complete_select.get_popup().show()
	if popup_position == PopupPosition.BELOW:
		auto_complete_select.get_popup().rect_global_position.y = self.rect_global_position.y + self.rect_size.y
	elif popup_position == PopupPosition.RIGHT:
		auto_complete_select.get_popup().rect_global_position.x = self.rect_global_position.x + self.rect_size.x
		auto_complete_select.get_popup().rect_global_position.y = self.rect_global_position.y - (auto_complete_select.get_popup().rect_size.y / 2)
	elif popup_position == PopupPosition.BOTH:
		auto_complete_select.get_popup().rect_global_position = self.rect_global_position + self.rect_size

	
func _on_AutoCompleteSelect_item_selected(index):
	emit_signal("item_selected", auto_complete_select.get_item_text(index))
	self.text = ''

func select_from_all() -> void:
	_on_TextAutoComplete_text_changed('', true)
