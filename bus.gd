extends Node

# warning-ignore:unused_signal
signal node_hovered(node, hovertext)
# warning-ignore:unused_signal
signal node_unhovered(node)
# warning-ignore:unused_signal
signal rtl_meta_hovered(rtlabel, string_id)
# warning-ignore:unused_signal
signal rtl_meta_unhovered(rtlabel)

# These are used for other purposes
# warning-ignore:unused_signal
signal height_changed(hslider)
# warning-ignore:unused_signal
signal width_changed(hslider)
# warning-ignore:unused_signal
signal shared_toggled()
# warning-ignore:unused_signal
signal lora_selected(lora_details)
# warning-ignore:unused_signal
signal model_selected(model_details)
# warning-ignore:unused_signal
signal worker_selected(worker_details)
signal kudos_calculated(kudos)
signal generation_completed
# warning-ignore:unused_signal
signal cache_wipe_requested
# warning-ignore:unused_signal
signal generation_started
# warning-ignore:unused_signal
signal generation_cancelled

func _on_node_hovered(node: Control, hovertext):
	emit_signal("node_hovered", node, hovertext)

func _on_node_unhovered(node: Control):
	emit_signal("node_unhovered", node)
