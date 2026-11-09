extends Node

const SETTINGS_PATH := "user://settings.cfg"

var weirdassfiletypes := false
var CompressGifs := true
var Bitcrush := false
var Mp3InsteadOfWav := false
var DefaultOutputPath := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/GDConvert/"
@export var GradientColor1 =Color(0.0, 0.38, 0.15, 1.0)
@export var GradientColor2 = Color(0,0.14,0,1.0)


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return
	weirdassfiletypes = config.get_value("general", "weirdassfiletypes", false)
	CompressGifs = config.get_value("general", "CompressGifs", true)
	Bitcrush = config.get_value("general", "Bitcrush", false)
	Mp3InsteadOfWav = config.get_value("general", "Mp3InsteadOfWav", false)
	DefaultOutputPath = config.get_value("general", "DefaultOutputPath", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/GDConvert/")


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("general", "weirdassfiletypes", weirdassfiletypes)
	config.set_value("general", "CompressGifs", CompressGifs)
	config.set_value("general", "DefaultOutputPath", DefaultOutputPath)
	config.set_value("general", "Bitcrush", Bitcrush)
	config.set_value("general", "Mp3InsteadOfWav", Mp3InsteadOfWav)
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings, error code: %d" % err)
