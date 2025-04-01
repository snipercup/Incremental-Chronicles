class_name LoopAction
extends StoryAction

var ui_scene: PackedScene = preload("res://Scenes/action/story_action_loop_ui.tscn")
var cooldown: float = 1.0
# Add this line to declare the new property with a default value
var max_loops: int = -1

func _init(data: Dictionary, myarea: StoryArea = null) -> void:
	super(data, myarea)
	cooldown = data.get("cooldown", 1.0)
	max_loops = data.get("max_loops", -1)  # Retrieve from data or use default

func perform_action() -> void:
	print("Performed loop action: %s" % [story_text])

func get_cooldown() -> float:
	return cooldown

func get_max_loops() -> float:
	return max_loops

func get_icon() -> String:
	return "🔁"

# Returns the type as specified in the json
func get_type() -> String:
	return "loop"
