extends Control

var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
var progress_path = OS.get_user_data_dir() + "/Progress/"
@onready var outputpath = documents_path + "/GDConvert/"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


#base command: ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -movflags +faststart output.mp4   
func compressvideo():
	pass

#base command: ffmpeg -i input.png -q:v 3 output.png   
func compressaudio():
	pass

#base command: ffmpeg -i input.wav -c:a aac -b:a 128k output.m4a   
func compressimage():
	pass

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Settings.tscn")


func _on_convert_pressed() -> void:
	get_tree().change_scene_to_file("res://Convert.tscn")


func _on_file_selector_pressed() -> void:
	$InputFile/InputFileDialog.visible = true
