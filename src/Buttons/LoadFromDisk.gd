extends Button

signal gensettings_loaded(settings)

onready var load_from_disk_native_dialog_open_file = $"%LoadFromDiskNativeDialogOpenFile"

func _ready():
	load_from_disk_native_dialog_open_file.initial_path = globals.config.get_value("Options", "load_initial_path", "user://")

func _on_LoadFromDiskNativeDialogOpenFile_files_selected(files: Array):
	if files.size() == 0:
		return
	var filename: String = files[0]
	var file = File.new()
	if filename.ends_with(".png"):
		filename = filename.get_basename() + '.json'
		if not file.file_exists(filename):
			return
	globals.set_setting("load_initial_path", filename.get_base_dir() + '/', "Options")
	load_from_disk_native_dialog_open_file.initial_path = filename.get_base_dir() + '/'
	file.open(filename, File.READ)
	var data = JSON.parse(file.get_as_text())
	file.close()
	emit_signal("gensettings_loaded", data.result)

func _on_LoadFromDisk_pressed():
	load_from_disk_native_dialog_open_file.show()
