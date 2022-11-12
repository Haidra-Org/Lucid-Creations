extends Node

signal setting_changed(setting_name)

const CONFIG_FILENAME = "user://settings.cfg"
var config = ConfigFile.new()


func _ready() -> void:
	init_config_from_file()
	

# Whenever a setting is changed via this function, it also stores it
# permanently on-disk.
func set_setting(config_name: String, value, section := "Parameters") -> void:
	config.set_value(section, config_name, value)
	config.save(CONFIG_FILENAME)
	emit_signal("setting_changed",config_name)

# Initiates game_settings from the contents of CFConst.SETTINGS_FILENAME
func init_config_from_file() -> void:
	var err = config.load(CONFIG_FILENAME)
	if err != OK:
		push_warning("Config file not found.")
		return
	
