class_name SalvageAction
extends StoryAction

var success_chance: float = 0.7
var reward: int = 5

func perform_action() -> void:
	if randf() <= success_chance:
		print("Salvage successful! Gained %d resources." % reward)
		story_points += reward
	else:
		print("Salvage failed. Found nothing.")

func get_icon() -> String:
	return "🛠️"
