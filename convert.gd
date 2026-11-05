extends Control

@onready var inputfiledialog = $InputFile/InputFileDialog
@onready var extenstionselector = $OutputFile/HBoxContainer/extensionselector
@onready var filetypeselector = $OutputFile/HBoxContainer/filetypeselector
@onready var progressbar = $ProgressBar
@onready var convertbutton = $InputFile/Button

var inputfile := ""
var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
var progress_path = OS.get_user_data_dir() + "/Progress/"
@onready var outputpath = documents_path + "/GDConvert/"
var extension := ".wav"
var ffmpeg_pid := -1
var total_duration_us := 0
var out_path := ""

#extension types
@export var audio_extensions: PackedStringArray
@export var video_extensions: PackedStringArray
@export var image_extensions: PackedStringArray
@export var audio_extensions_weird: PackedStringArray
@export var video_extensions_weird: PackedStringArray
@export var image_extensions_weird: PackedStringArray

#extension images
@export var Audio_Image: Texture2D
@export var Video_Image: Texture2D
@export var Image_Image: Texture2D


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(outputpath)
	DirAccess.make_dir_recursive_absolute(progress_path)


func _exit_tree() -> void:
	if ffmpeg_pid != -1 and OS.is_process_running(ffmpeg_pid):
		OS.kill(ffmpeg_pid)


func _on_input_file_selector_button_pressed() -> void:
	inputfiledialog.visible = true
	$InputFile/TextureRect.visible = false


func _on_input_file_dialog_file_selected(path: String) -> void:
	inputfile = path
	print(inputfile)
	
	_extensionselector_dynamic_options()


func _on_extensionselector_item_selected(index: int) -> void:
	extension = str(extenstionselector.get_item_text(index))
	print(extension)


func _on_convert_pressed() -> void:
	if inputfile.is_empty():
		push_error("No input file selected")
		return

	var prog_file_path = progress_path + "progress.txt"
	if FileAccess.file_exists(prog_file_path):
		DirAccess.remove_absolute(prog_file_path)

	var probe_output := []
	OS.execute("ffprobe", [
		"-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		inputfile
	], probe_output, false)
	if probe_output.is_empty():
		push_error("ffprobe failed on: " + inputfile)
		return
	total_duration_us = int(probe_output[0].strip_edges().to_float() * 1000000.0)

	var real_ext := extension
	var compressed_gif := false
	if extension == ".gif" and Globals.CompressGifs:
		compressed_gif = true
	elif extension == ".gif (uncompressed)":
		real_ext = ".gif"

	out_path = outputpath + inputfile.get_file().get_basename() + real_ext

	var args := [
		"-y",
		"-nostdin",
		"-progress", prog_file_path,
		"-stats_period", "0.1",
		"-nostats",
		"-loglevel", "error",
		"-i", inputfile,
	]

	if compressed_gif:
		args.append_array([
			"-vf", "fps=10,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse",
			"-loop", "0",
		])

	args.append(out_path)

	ffmpeg_pid = OS.create_process("ffmpeg", args)
	if ffmpeg_pid == -1:
		push_error("ffmpeg failed to launch")
		return

	progressbar.min_value = 0
	progressbar.max_value = 1
	progressbar.value = 0
	convertbutton.disabled = true
	$Timer.start()


#long ass name
func _extensionselector_dynamic_options() -> void:
	extenstionselector.clear()
	if (inputfile.get_extension() in audio_extensions) or (inputfile.get_extension() in audio_extensions_weird):
		for item in audio_extensions:
			extenstionselector.add_item("." + item)
		$InputFile/TextureRect.texture = Audio_Image
	elif (inputfile.get_extension() in video_extensions) or (inputfile.get_extension() in video_extensions_weird):
		for item in video_extensions:
			extenstionselector.add_item("." + item)
		$InputFile/TextureRect.texture = Video_Image
	elif (inputfile.get_extension() in image_extensions) or (inputfile.get_extension() in image_extensions_weird):
		for item in image_extensions:
			extenstionselector.add_item("." + item)
		$InputFile/TextureRect.texture = Image_Image
	$InputFile/TextureRect.visible = true
	$InputFile/Label.text = inputfile.get_file()


func _on_timer_timeout() -> void:
	# finished (or died)
	if not OS.is_process_running(ffmpeg_pid):
		$Timer.stop()
		convertbutton.disabled = false

		var ok := false
		if FileAccess.file_exists(out_path):
			var f = FileAccess.open(out_path, FileAccess.READ)
			if f != null:
				ok = f.get_length() > 0
				f.close()

		if ok:
			progressbar.value = 1
			print("Converted: ", out_path)
		else:
			progressbar.value = 0
			push_error("Conversion failed, no valid output at: " + out_path)
			if FileAccess.file_exists(out_path):
				DirAccess.remove_absolute(out_path)
		return

	# still running: read progress
	var prog_file_path = progress_path + "progress.txt"
	if not FileAccess.file_exists(prog_file_path):
		return
	var progfile = FileAccess.open(prog_file_path, FileAccess.READ)
	if progfile == null:
		return
	var progtextuncut = progfile.get_as_text()
	progfile.close()
	var progtextsliced = progtextuncut.split("\n")

	var currentprog := -1
	for i in range(progtextsliced.size() - 1, -1, -1):
		if progtextsliced[i].begins_with("out_time_us="):
			var value_text = progtextsliced[i].trim_prefix("out_time_us=").strip_edges()
			if not value_text.is_valid_int():
				return
			currentprog = value_text.to_int()
			break

	if currentprog < 0:
		return
	if total_duration_us <= 0:
		return

	var fraction = clampf(float(currentprog) / float(total_duration_us), 0.0, 1.0)
	progressbar.value = fraction


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Settings.tscn")
