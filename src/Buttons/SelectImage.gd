extends Button

signal image_selected(filename)

onready var select_image_native_dialog_open_file = $"%SelectImageNativeDialogOpenFile"

func _ready():
	select_image_native_dialog_open_file.initial_path = globals.config.get_value("Options", "source_image_initial_path", "user://")

func _on_SelectImageNativeDialogOpenFile_files_selected(files: Array):
	if files.size() == 0:
		return
	var filename: String = files[0]
	globals.set_setting("source_image_initial_path", filename.get_base_dir() + '/', "Options")
	select_image_native_dialog_open_file.initial_path = filename.get_base_dir() + '/'
	emit_signal("image_selected", filename)

func _on_SelectImage_pressed():
	select_image_native_dialog_open_file.show()
