class_name LoopAction
extends StoryAction

var loop_count: int = 0

func perform_action() -> void:
	loop_count += 1
	print("Performed loop action %d times: %s" % [loop_count, story_text])

# Optionally increase or decrease reward per loop
func get_story_points() -> int:
	return story_points + loop_count

func get_icon() -> String:
	return "🔁"
