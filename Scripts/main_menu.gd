extends Control


func _on_start_game_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/incremental_chronicle.tscn")
