extends Control




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ScrollContainer/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/WeirdFiles.set_pressed_no_signal(Globals.weirdassfiletypes)
	$ScrollContainer/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/AutoCompressGifs.set_pressed_no_signal(Globals.CompressGifs)
	$ScrollContainer/HBoxContainer/VBoxContainer/PanelContainer3/VBoxContainer/Bitcrush.set_pressed_no_signal(Globals.Bitcrush)
	$ScrollContainer/HBoxContainer/VBoxContainer/PanelContainer2/VBoxContainer/ColorPickerButton.color = Globals.GradientColor1
	$ScrollContainer/HBoxContainer/VBoxContainer/PanelContainer2/VBoxContainer/ColorPickerButton2.color = Globals.GradientColor2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$"BG Color".material.set_shader_parameter("color1", Globals.GradientColor1)
	$"BG Color".material.set_shader_parameter("color2", Globals.GradientColor2)
	
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


func _on_download_pressed() -> void:
	get_tree().change_scene_to_file("res://Download.tscn")


func _on_color_picker_button_color_changed(color: Color) -> void:
	Globals.GradientColor1 = color


func _on_color_picker_button_2_color_changed(color: Color) -> void:
	Globals.GradientColor2 = color


func _on_mp_3_instead_of_wav_toggled(toggled_on: bool) -> void:
	Globals.Mp3InsteadOfWav = toggled_on 
