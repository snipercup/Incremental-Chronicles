class_name MultiStepAction
extends StoryAction

var steps: Array[String] = []
var current_step: int = 0

func perform_action() -> void:
	if current_step < steps.size():
		print("Step %d: %s" % [current_step + 1, steps[current_step]])
		current_step += 1
	else:
		print("Action complete: %s" % story_text)
		current_step = 0

func get_icon() -> String:
	return "🪜"
