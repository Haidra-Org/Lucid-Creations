extends Button

signal savedir_path_set(path)

onready var save_dir_browse_native_dialog_select_folder = $"%SaveDirBrowseNativeDialogSelectFolder"


func _ready():
	save_dir_browse_native_dialog_select_folder.initial_path = globals.config.get_value("Options", "savedir_path", "user://")

func _on_SaveDirBrowseNativeDialogSelectFolder_folder_selected(folder: String):
	globals.set_setting("savedir_path", folder, "Options")
	save_dir_browse_native_dialog_select_folder.initial_path = folder + '/'
	emit_signal("savedir_path_set", folder)

func _on_SaveDirBrowseButton_pressed():
	save_dir_browse_native_dialog_select_folder.show()

