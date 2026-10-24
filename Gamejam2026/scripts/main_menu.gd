extends Control


func _ready() -> void:
	$Content/Buttons/StartButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_F11 or key_event.physical_keycode == KEY_F11 or (key_event.keycode == KEY_ENTER and key_event.alt_pressed):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1280, 720))
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/game.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
