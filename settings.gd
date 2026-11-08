extends Control




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ScrollContainer/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/WeirdFiles.set_pressed_no_signal(Globals.weirdassfiletypes)
	$ScrollContainer/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/AutoCompressGifs.set_pressed_no_signal(Globals.CompressGifs)
	$ScrollContainer/HBoxContainer/VBoxContainer/PanelContainer3/VBoxContainer/Bitcrush.set_pressed_no_signal(Globals.Bitcrush)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _exit_tree() -> void:
	Globals.save_settings()


func _on_weird_files_toggled(toggled_on: bool) -> void:
	Globals.weirdassfiletypes = toggled_on


func _on_convert_pressed() -> void:
	get_tree().change_scene_to_file("res://Convert.tscn")


func _on_auto_compress_gifs_toggled(toggled_on: bool) -> void:
	Globals.CompressGifs = toggled_on


func _on_compress_pressed() -> void:
	get_tree().change_scene_to_file("res://Compress.tscn")


func _on_line_edit_text_changed(new_text: String) -> void:
	Globals.DefaultOutputPath = new_text


func _on_bitcrush_toggled(toggled_on: bool) -> void:
	Globals.Bitcrush = toggled_on
