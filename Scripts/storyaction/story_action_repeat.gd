class_name RepeatAction
extends StoryAction

var repeat_count: int = 0

func perform_action() -> void:
	repeat_count += 1
	print("Performed repeat action (%d times): %s" % [repeat_count, story_text])

# Optionally increase reward or difficulty
#func get_story_points() -> int:
	#return story_points * repeat_count

func get_icon() -> String:
	return "🔄"
