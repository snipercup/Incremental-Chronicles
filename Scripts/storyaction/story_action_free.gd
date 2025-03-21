class_name FreeAction
extends StoryAction

var ui_scene: PackedScene = preload("res://Scenes/story_action_ui.tscn")
# No additional logic needed — just perform the action
func perform_action() -> void:
	print("Performed free action: %s" % story_text)

func get_icon() -> String:
	return "🖱️"
