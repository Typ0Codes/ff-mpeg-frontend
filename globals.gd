extends Node

const SETTINGS_PATH := "user://settings.cfg"

var weirdassfiletypes := false


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		# first run (no file yet) or unreadable file: keep defaults
		return
	weirdassfiletypes = config.get_value("general", "weirdassfiletypes", false)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("general", "weirdassfiletypes", weirdassfiletypes)
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings, error code: %d" % err)
