class_name FindAction
extends StoryAction

var discovery_chance: float = 0.5
var discovered_item: String = ""

func perform_action() -> void:
	if randf() <= discovery_chance:
		print("You found: %s" % discovered_item)
	else:
		print("You searched, but found nothing.")

func get_icon() -> String:
	return "🕵️"
