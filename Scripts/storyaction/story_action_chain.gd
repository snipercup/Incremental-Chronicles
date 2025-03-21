class_name ChainAction
extends StoryAction

var next_action: StoryAction = null

func perform_action() -> void:
	print("Performed chain action: %s" % story_text)
	if next_action:
		print("Next action: %s" % next_action.get_story_text())

func get_icon() -> String:
	return "🔗"
