class_name ExplorationAction
extends StoryAction

var discovery_chance: float = 0.5

func perform_action() -> void:
	if randf() < discovery_chance:
		print("Exploration successful: %s" % story_text)
	else:
		print("Nothing discovered... %s" % story_text)
