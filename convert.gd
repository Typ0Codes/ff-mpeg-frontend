extends Control

var inputfile
@onready var inputfiledialog = $InputFile/InputFileDialog
var inputfilename
var output = []
var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
var progress_path = OS.get_user_data_dir() + "/Progress/"
@onready var outputpath = documents_path + "/GDConvert/"
var extension = ".wav"
@onready var extenstionselector = $OutputFile/extensionselector
var ffmpeg_pid := -1
var total_duration_us := 0
@onready var progressbar = $ProgressBar

#extension types
@export var audio_extensions: PackedStringArray

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	OS.execute("mkdir",["-p",outputpath],output,true)
	OS.execute("mkdir",["-p",progress_path],output,true)
	print(output)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_input_file_selector_button_pressed() -> void:
	inputfiledialog.visible = true
	extenstionselector.clear()


func _on_input_file_dialog_file_selected(path: String) -> void:
	inputfile = path
	print(inputfile)
	print(inputfile.get_extension())
	print(inputfile.get_file().get_basename())
	_extensionselector_dynamic_options()
	

func _on_extensionselector_item_selected(index: int) -> void:
	extension = str(extenstionselector.get_item_text(index))
	print(extension)


func _on_convert_pressed() -> void:
	var probe_output := []
	DirAccess.remove_absolute(progress_path + "progress.txt")
	OS.execute("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1",inputfile], probe_output, false)
	total_duration_us = int(probe_output[0].strip_edges().to_float() * 1000000.0)
	var out_path = outputpath + inputfile.get_file().get_basename() + extension
	ffmpeg_pid = OS.create_process("ffmpeg", ["-y","-progress",progress_path + "progress.txt","-nostats","-loglevel", "error", "-nostdin", "-i", inputfile, out_path])
	if ffmpeg_pid == -1:
		push_error("ffmpeg failed to launch")
	print(output)
	
#long ass name
func _extensionselector_dynamic_options() -> void:
	if inputfile.get_extension() in audio_extensions:
		for item in audio_extensions:
			extenstionselector.add_item("." + item)


func _on_timer_timeout() -> void:
	pass # Replace with function body.
