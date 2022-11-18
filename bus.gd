extends Node

# warning-ignore:unused_signal
signal width_changed(hslider)
# warning-ignore:unused_signal
signal height_changed(hslider)
# warning-ignore:unused_signal
signal node_hovered(node)
# warning-ignore:unused_signal
signal node_unhovered(node)
# warning-ignore:unused_signal
signal rtl_meta_hovered(rtlabel, string_id)
# warning-ignore:unused_signal
signal rtl_meta_unhovered(rtlabel)

func _on_node_hovered(node: Control):
	emit_signal("node_hovered", node)

func _on_node_unhovered(node: Control):
	emit_signal("node_unhovered", node)
