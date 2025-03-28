class_name FreeAction
extends StoryAction

# This script represents the FreeAction class. 
# A free action is mostly flavor and can provide a small reward
# It's possible to tell a story by being clever about chaining free actions

# Example free action data
#	{
#	  "action_type": "free",
#	  "appear_requirements": {
#		"hidden_rat_reward": 1.0
#	  },
#	  "rewards": {
#		"Story points": 5.0
#	  },
#	  "story_text": "Examine the defeated rat."
#	}


var ui_scene: PackedScene = preload("res://Scenes/action/story_action_free_ui.tscn")

func _init(data: Dictionary, myarea: StoryArea = null) -> void:
	super(data, myarea)
	
# No additional logic needed — just perform the action
func perform_action() -> void:
	print("Performed free action: %s" % story_text)

func get_icon() -> String:
	return "✨"
