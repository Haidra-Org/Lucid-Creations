extends MarginContainer

onready var remember_prompt = $"%RememberPrompt"
onready var save_dir = $"%SaveDir"
onready var save_dir_browse_button = $"%SaveDirBrowseButton"
onready var save_dir_browse = $"%SaveDirBrowse"

func _ready():
	remember_prompt.pressed = globals.config.get_value("Options", "remember_prompt", false)
	remember_prompt.connect("toggled",self,"_on_remember_prompt_pressed")
	# warning-ignore:return_value_discarded
	save_dir_browse_button.connect("pressed",self,"_on_browse_pressed")
#	save_dir.connect("text_changed",self,"_on_savedir_changed")
	# warning-ignore:return_value_discarded
	save_dir_browse.connect("dir_selected",self,"_on_savedir_selected")
	var default_save_dir = globals.config.get_value("Options", "default_save_dir", "user://")
	if default_save_dir in ["user://", '']:
		_set_default_savedir_path()
	else:
		save_dir.text = default_save_dir
		_set_default_savedir_path(true)

func _on_remember_prompt_pressed(pressed: bool) -> void:
	globals.set_setting("remember_prompt", pressed, "Options")


func _on_savedir_changed(path: String) -> void:
	match path:
		'%APPDATA%\\Godot\\app_userdata\\Lucid Creations\\':
			globals.set_setting('default_save_dir', "user://", "Options")
		'${HOME}/.local/share/godot/app_userdata/Lucid Creations/':
			globals.set_setting('default_save_dir', "user://", "Options")
		'~/Library/Application Support/Godot/app_userdata/Lucid Creations/':
			globals.set_setting('default_save_dir', "user://", "Options")
		'':
			_set_default_savedir_path()
		_:
			globals.set_setting('default_save_dir', path, "Options")


func _set_default_savedir_path(only_placholder = false) -> void:
	match OS.get_name():
		"Windows":
			if not only_placholder:
				save_dir.text = '%APPDATA%\\Godot\\app_userdata\\Lucid Creations\\'
			save_dir.placeholder_text = '%APPDATA%\\Godot\\app_userdata\\Lucid Creations\\'
		"X11":
			if not only_placholder:
				save_dir.text = '${HOME}/.local/share/godot/app_userdata/Lucid Creations/'
			save_dir.placeholder_text = '${HOME}/.local/share/godot/app_userdata/Lucid Creations/'
			
		_:
			if not only_placholder:
				save_dir.text = '~/Library/Application Support/Godot/app_userdata/Lucid Creations/'
			save_dir.placeholder_text = '~/Library/Application Support/Godot/app_userdata/Lucid Creations/'


func _on_browse_pressed() -> void:
	var prev_path = globals.config.get_value("Options", "default_save_dir", "user://")
	print_debug([prev_path,save_dir_browse.current_path])
	if prev_path:
		save_dir_browse.current_dir = prev_path
	save_dir_browse.popup_centered(Vector2(500,500))


func _on_savedir_selected(path: String) -> void:
	globals.set_setting("default_save_dir", path, "Options")
	save_dir.text = path
	print_debug(save_dir.text)
