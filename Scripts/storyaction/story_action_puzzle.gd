class_name PuzzleAction
extends StoryAction

var solution: String = ""
var attempts: int = 3

func perform_action(player_input: String) -> void:
	if player_input == solution:
		print("Puzzle solved! %s" % story_text)
	else:
		attempts -= 1
		print("Incorrect! Attempts left: %d" % attempts)
		if attempts <= 0:
			print("Puzzle failed...")

func get_icon() -> String:
	return "🧩"
