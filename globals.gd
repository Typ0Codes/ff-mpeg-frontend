extends Node

const SETTINGS_PATH := "user://settings.cfg"

var weirdassfiletypes := false
var CompressGifs := true
var Bitcrush := false
var DefaultOutputPath := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/GDConvert/"


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return
	weirdassfiletypes = config.get_value("general", "weirdassfiletypes", false)
	CompressGifs = config.get_value("general", "CompressGifs", true)
	Bitcrush = config.get_value("general", "Bitcrush", true)
	DefaultOutputPath = config.get_value("general", "DefaultOutputPath", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/GDConvert/")


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("general", "weirdassfiletypes", weirdassfiletypes)
	config.set_value("general", "CompressGifs", CompressGifs)
	config.set_value("general", "DefaultOutputPath", DefaultOutputPath)
	config.set_value("general", "Bitcrush", Bitcrush)
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings, error code: %d" % err)
