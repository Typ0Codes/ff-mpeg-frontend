extends Control

var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
var progress_path = OS.get_user_data_dir() + "/Progress/"
@onready var outputpath = Globals.DefaultOutputPath
var inputfile := ""
var total_duration_us := 0
var extension := ".wav"
var out_path := ""
var ffmpeg_pid := -1
@onready var progressbar = $ProgressBar
@onready var convertbutton = $InputFile/compress

@export var audio_extensions: PackedStringArray
@export var video_extensions: PackedStringArray
@export var image_extensions: PackedStringArray
@export var audio_extensions_weird: PackedStringArray
@export var video_extensions_weird: PackedStringArray
@export var image_extensions_weird: PackedStringArray

var quality = 50

var VideoOut = false
var AudioOut = false
var ImageOut = false

var pending_upscale := false
var temp_path := ""
var final_path := ""
var upscale_factor := 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$"BG Color".material.set_shader_parameter("color1", Globals.GradientColor1)
	$"BG Color".material.set_shader_parameter("color2", Globals.GradientColor2)


#base video command: ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -movflags +faststart output.mp4   


#base image command: ffmpeg -i input.png -q:v 3 output.png   


#base audio command: ffmpeg -i input.wav -c:a aac -b:a 128k output.m4a   


func compress() -> void:
	if inputfile.is_empty():
		error_handler("No input file selected")
		return

	var prog_file_path = progress_path + "progress.txt"
	DirAccess.make_dir_recursive_absolute(progress_path)
	DirAccess.make_dir_recursive_absolute(outputpath)
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
		error_handler("ffprobe failed on: " + inputfile)
		return
	total_duration_us = int(probe_output[0].strip_edges().to_float() * 1000000.0)

	var real_ext := "." + inputfile.get_extension()
	if Globals.Bitcrush and ImageOut:
		real_ext = ".jpg"
	out_path = outputpath + inputfile.get_file().get_basename() + "_COMPRESSED" + real_ext

	pending_upscale = false
	temp_path = ""

	var qualitypercentage: float = quality / 100.0
	var crf: int
	var audio_kbps: int
	var img_q: int
	var video_filters := ""
	var audio_filters := ""
	var preset := "ultrafast" if Globals.Bitcrush else "medium"

	if Globals.Bitcrush:
		crf = 51
		audio_kbps = int(round(lerpf(8.0, 32.0, qualitypercentage)))
		img_q = 31
		var shrink := lerpf(0.1, 0.35, qualitypercentage)
		video_filters = "scale=trunc(iw*%f/2)*2:trunc(ih*%f/2)*2:flags=bilinear" % [shrink, shrink]
		audio_filters = "aresample=8000,acrusher=bits=6:mix=1:mode=lin"
		if VideoOut or ImageOut:
			pending_upscale = true
			upscale_factor = 1.0 / shrink
			final_path = out_path
			temp_path = progress_path + "crush_temp" + real_ext
			out_path = temp_path
	else:
		crf = int(round(lerpf(45.0, 18.0, qualitypercentage)))
		audio_kbps = int(round(lerpf(32.0, 192.0, qualitypercentage)))
		img_q = int(round(lerpf(31.0, 1.0, qualitypercentage)))

	var args := [
		"-y",
		"-i", inputfile,
		"-progress", prog_file_path,
		"-nostats",
	]

	var videoargs := [
		"-c:v", "libx264",
		"-crf", str(crf),
		"-preset", preset,
		"-c:a", "aac",
		"-b:a", str(audio_kbps) + "k",
		"-movflags", "+faststart",
	]
	var imgargs := [
		"-q:v", str(img_q)
	]
	var audioargs := [
		"-c:a", "aac",
		"-b:a", str(audio_kbps) + "k"
	]

	if Globals.Bitcrush:
		videoargs.append_array([
			"-vf", video_filters + ",format=yuv420p",
			"-x264-params", "no-deblock=1:aq-mode=0",
			"-af", audio_filters,
		])
		imgargs.append_array(["-vf", video_filters])
		audioargs.append_array(["-af", audio_filters, "-ar", "8000"])

	if VideoOut:
		args.append_array(videoargs)
	elif AudioOut:
		args.append_array(audioargs)
	elif ImageOut:
		args.append_array(imgargs)
	args.append(out_path)

	ffmpeg_pid = OS.create_process("ffmpeg", args)
	if ffmpeg_pid == -1:
		error_handler("ffmpeg failed to launch")
		return

	progressbar.min_value = 0
	progressbar.max_value = 1
	progressbar.value = 0
	convertbutton.disabled = true
	$Timer.start()

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Settings.tscn")


func _on_convert_pressed() -> void:
	get_tree().change_scene_to_file("res://Convert.tscn")


func _on_file_selector_pressed() -> void:
	$InputFile/InputFileDialog.visible = true
	
func error_handler(text: String):
	$ErrorMsg.visible = true
	push_error(text)
	$ErrorMsg.text = text


func _on_input_file_dialog_file_selected(path: String) -> void:
	inputfile = path
	print(inputfile)
	
	$InputFile/Label.text = inputfile
	
	if (inputfile.get_extension() in audio_extensions) or (inputfile.get_extension() in audio_extensions_weird):
		VideoOut = false
		AudioOut = true
		ImageOut = false
		print("audio")
	elif (inputfile.get_extension() in video_extensions) or (inputfile.get_extension() in video_extensions_weird):
		VideoOut = true
		AudioOut = false
		ImageOut = false
		print("video")
	elif (inputfile.get_extension() in image_extensions) or (inputfile.get_extension() in image_extensions_weird):
		VideoOut = false
		AudioOut = false
		ImageOut = true
		print("image")

	
func _on_timer_timeout() -> void:
	# finished (or died)
	if not OS.is_process_running(ffmpeg_pid):
		# bitcrush: pass 1 done, start the upscale pass
		if pending_upscale and FileAccess.file_exists(temp_path):
			pending_upscale = false
			_start_upscale_pass()
			return

		$Timer.stop()
		convertbutton.disabled = false

		# clean up the temp file from pass 1
		if temp_path != "" and FileAccess.file_exists(temp_path):
			DirAccess.remove_absolute(temp_path)

		var ok := false
		if FileAccess.file_exists(out_path):
			var f = FileAccess.open(out_path, FileAccess.READ)
			if f != null:
				ok = f.get_length() > 0
				f.close()

		if ok:
			progressbar.value = 1
			print("Converted: ", out_path)
			$YouWin.text = inputfile.get_file() + " Converted Succesfully!"
			$YouWin.visible = true
			$ErrorMsg.visible = false
		else:
			progressbar.value = 0
			error_handler("Conversion failed, no valid output at: " + out_path)
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
	
func _start_upscale_pass() -> void:
	var prog_file_path = progress_path + "progress.txt"
	if FileAccess.file_exists(prog_file_path):
		DirAccess.remove_absolute(prog_file_path)

	var k := upscale_factor
	var up := "scale=trunc(iw*%f/2)*2:trunc(ih*%f/2)*2:flags=bicubic" % [k, k]
	var a := ["-y", "-i", temp_path, "-progress", prog_file_path, "-nostats", "-vf", up]

	if VideoOut:
		a.append_array([
			"-c:v", "libx264", "-crf", "18", "-preset", "veryfast",
			"-pix_fmt", "yuv420p", "-c:a", "copy", "-movflags", "+faststart",
		])
	else:
		a.append_array(["-q:v", "2"])

	out_path = final_path
	a.append(out_path)
	ffmpeg_pid = OS.create_process("ffmpeg", a)
	if ffmpeg_pid == -1:
		error_handler("ffmpeg failed to launch (upscale pass)")


func _on_download_pressed() -> void:
	get_tree().change_scene_to_file("res://Download.tscn")
