extends Control

var URL = ''
var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
@onready var outputpath = documents_path + "/GDConvert/"

var progress_path = OS.get_user_data_dir() + "/Progress/"
var yt_pid := -1
var yt_log := ""
var log_pos := 0
var had_error := false
var wav_only := false

var percent_regex := RegEx.new()
var item_regex := RegEx.new()
var frag_regex := RegEx.new()

var cur_item := 1
var total_items := 1
var stream_idx := 0
var stream_pct := 0.0


func _ready() -> void:
	percent_regex.compile("(\\d+(?:\\.\\d+)?)% of")
	item_regex.compile("Downloading item (\\d+) of (\\d+)")
	frag_regex.compile("\\(frag (\\d+)/(\\d+)\\)")
	$ProgressBar.min_value = 0
	$ProgressBar.max_value = 1
	$ProgressBar.value = 0


func _sq(s: String) -> String:
	return "'" + s.replace("'", "'\\''") + "'"


func _on_download_pressed() -> void:
	if URL.strip_edges() == "" or (yt_pid != -1 and OS.is_process_running(yt_pid)):
		return

	DirAccess.make_dir_recursive_absolute(progress_path)
	DirAccess.make_dir_recursive_absolute(outputpath)
	yt_log = progress_path + "ytdlp.txt"
	if FileAccess.file_exists(yt_log):
		DirAccess.remove_absolute(yt_log)

	log_pos = 0
	had_error = false
	cur_item = 1
	total_items = 1
	stream_idx = 0
	stream_pct = 0.0

	var fmt := "-x --audio-format wav" if wav_only else "-S vcodec:h264,res,acodec:m4a --merge-output-format mp4"

	var url := URL.strip_edges()
	var is_playlist := "/playlist" in url or "--yes-playlist" in url
	var out_tmpl := "%(playlist_title)s/%(title)s.%(ext)s" if is_playlist else "%(title)s.%(ext)s"

	if OS.get_name() == "Windows":
		var cmd := 'yt-dlp --newline --progress --progress-delta 0.5 %s -P "%s" -o "%s" "%s" > "%s" 2>&1' % [fmt, outputpath, out_tmpl.replace("%", "%%"), url, yt_log]
		yt_pid = OS.create_process("cmd.exe", ["/c", cmd])
	else:
		var cmd := "unset LD_PRELOAD; yt-dlp --newline --progress --progress-delta 0.5 %s -P %s -o %s %s > %s 2>&1" % [fmt, _sq(outputpath), _sq(out_tmpl), _sq(url), _sq(yt_log)]
		yt_pid = OS.create_process("/bin/sh", ["-c", cmd])

	if yt_pid == -1:
		push_error("Failed to launch yt-dlp")
		return

	$ProgressBar.value = 0
	$InputFile/HBoxContainer/Download.disabled = true
	$Timer.start()


func _read_new_log() -> void:
	if not FileAccess.file_exists(yt_log):
		return
	var f := FileAccess.open(yt_log, FileAccess.READ)
	if f == null:
		return
	f.seek(log_pos)
	var bytes := f.get_buffer(f.get_length() - log_pos)
	f.close()

	var last_nl := bytes.rfind(10) 
	if last_nl == -1:
		return
	log_pos += last_nl + 1
	var text := bytes.slice(0, last_nl + 1).get_string_from_utf8()
	for line in text.split("\n"):
		_parse_line(line)

	var item_frac := 0.0
	if stream_idx == 1:
		item_frac = stream_pct * 0.95
	elif stream_idx >= 2:
		item_frac = 0.95 + stream_pct * 0.05
	$ProgressBar.value = (cur_item - 1 + item_frac) / total_items


func _parse_line(line: String) -> void:
	if line.begins_with("ERROR:") and not "ld.so" in line:
		had_error = true
		push_error(line)
		return

	var im := item_regex.search(line)
	if im:
		cur_item = im.get_string(1).to_int()
		total_items = im.get_string(2).to_int()
		stream_idx = 0
		stream_pct = 0.0
		return

	if line.begins_with("[download] Destination:"):
		stream_idx += 1
		stream_pct = 0.0
		return

	if line.begins_with("[download]"):
		var fm := frag_regex.search(line)
		if fm:
			stream_pct = clampf(fm.get_string(1).to_float() / maxf(fm.get_string(2).to_float(), 1.0), 0.0, 1.0)
		else:
			var m := percent_regex.search(line)
			if m:
				stream_pct = m.get_string(1).to_float() / 100.0


func _on_timer_timeout() -> void:
	_read_new_log()
	if OS.is_process_running(yt_pid):
		return

	_read_new_log() 
	$Timer.stop()
	$InputFile/HBoxContainer/Download.disabled = false
	$ProgressBar.value = 0.0 if had_error else 1.0





func _process(delta: float) -> void:
	pass





func _on_compress_pressed() -> void:
	get_tree().change_scene_to_file("res://Compress.tscn")


func _on_convert_pressed() -> void:
	get_tree().change_scene_to_file("res://Convert.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Settings.tscn")


func _on_line_edit_text_changed(new_text: String) -> void:
	URL = new_text


func _on_check_button_toggled(toggled_on: bool) -> void:
	wav_only = toggled_on
