extends Control


func _ready() -> void:
	$Content/Buttons/StartButton.grab_focus()


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/game.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
