class_name FreeAction
extends StoryAction

var ui_scene: PackedScene = preload("res://Scenes/action/story_action_free_ui.tscn")
# No additional logic needed — just perform the action
func perform_action() -> void:
	print("Performed free action: %s" % story_text)

func get_icon() -> String:
	return "🖱️"
