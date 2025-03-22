class_name LoopAction
extends StoryAction

var ui_scene: PackedScene = preload("res://Scenes/action/story_action_loop_ui.tscn")
var cooldown: float = 1.0

func _init(data: Dictionary) -> void:
	cooldown = data.get("cooldown", 1.0)

func perform_action() -> void:
	print("Performed loop action: %s" % [story_text])

func get_cooldown() -> float:
	return cooldown

func get_icon() -> String:
	return "🔁"
