extends Button

signal image_selected(filename)

onready var select_image_native_dialog_open_file = $"%SelectImageNativeDialogOpenFile"
onready var file_dialog = $"%FileDialog"

func _ready():
	select_image_native_dialog_open_file.initial_path = globals.config.get_value("Options", "source_image_initial_path", "user://")
	file_dialog.current_path = globals.config.get_value("Options", "source_image_initial_path", "user://")
	
func _on_SelectImageNativeDialogOpenFile_files_selected(files: Array):
	if files.size() == 0:
		return
	var filename: String = files[0]
	_on_file_selected(files[0])

func _on_SelectImage_pressed():
	if globals.config.get_value("Options", "use_godot_browse", false):
		file_dialog.show()
	else:
		select_image_native_dialog_open_file.show()

func _on_FileDialog_file_selected(filepath: String):
	_on_file_selected(filepath)

func _on_file_selected(filepath: String):
	globals.set_setting("source_image_initial_path", filepath.get_base_dir() + '/', "Options")
	select_image_native_dialog_open_file.initial_path = filepath.get_base_dir() + '/'
	emit_signal("image_selected", filepath)
	
