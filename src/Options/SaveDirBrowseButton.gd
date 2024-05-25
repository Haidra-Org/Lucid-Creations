extends Button

signal savedir_path_set(path)

onready var save_dir_browse_native_dialog_select_folder = $"%SaveDirBrowseNativeDialogSelectFolder"
onready var file_dialog = $"%FileDialog"


func _ready():
	save_dir_browse_native_dialog_select_folder.initial_path = globals.config.get_value("Options", "savedir_path", "user://")
	file_dialog.current_path = globals.config.get_value("Options", "savedir_path", "user://")


func _on_SaveDirBrowseButton_pressed():
	if globals.config.get_value("Options", "use_godot_browse", false):
		file_dialog.show()
	else:
		save_dir_browse_native_dialog_select_folder.show()

func _on_SaveDirBrowseNativeDialogSelectFolder_folder_selected(dir: String):
	_on_dir_selected(dir)

func _on_FileDialog_dir_selected(dir: String):
	_on_dir_selected(dir)

func _on_dir_selected(dir: String):
	globals.set_setting("savedir_path", dir, "Options")
	save_dir_browse_native_dialog_select_folder.initial_path = dir + '/'
	emit_signal("savedir_path_set", dir)
