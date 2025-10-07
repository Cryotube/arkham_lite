extends SceneTree

func _init():
	var candidate_paths := [
		"user://telemetry.log",
		"user://logs/telemetry.log"
	]
	for path in candidate_paths:
		if FileAccess.file_exists(path):
			_print_log(path)
			quit()
	print("No telemetry log found. Play the game to generate events.")
	quit()

func _print_log(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Failed to open telemetry log at", path)
		return
	print("--- Telemetry log (" + path + ") ---")
	while not file.eof_reached():
		print(file.get_line())
	file.close()
