class_name FreeAction
extends StoryAction

# No additional logic needed — just perform the action
func perform_action() -> void:
	print("Performed free action: %s" % story_text)

func get_icon() -> String:
	return "🖱️"
