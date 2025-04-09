class_name ReincarnationAction
extends StoryAction

# This script represents the ReincarnationAction class. 
# A reincarnation action is the final action in a run and will reset the game

# Example reincarnation action data
#	{
#	  "action_type": "reincarnation",
#	  "appear_requirements": {
#		"hidden": {
#		  "reincarnation_ready": 1.0,
#		  "has_soul_vessel": 1.0
#		}
#	  },
#	  "rewards": {
#		"visible": {
#		  "Story points": 10.0,
#		  "Reincarnation": 1.0
#		}
#		"hidden": {
#		  "reincarnation_finished": 0.0
#		}
#	  },
#	  "story_text": "You reincarnate."
#	}


var ui_scene: PackedScene = preload("res://Scenes/action/story_action_reincarnation_ui.tscn")

func _init(data: Dictionary, myarea: StoryArea = null) -> void:
	super(data, myarea)
	
# No additional logic needed — just perform the action
func perform_action() -> void:
	print("Performed reincarnation action: %s" % story_text)
	SignalBroker.action_activated.emit(self)
	SignalBroker.action_rewarded.emit(self)

	if rewards.has("reincarnation_started"):
		SignalBroker.reincarnation_started.emit(self)
	elif rewards.has("reincarnation_finished"):
		SignalBroker.reincarnation_finished.emit(self)

	SignalBroker.action_removed.emit(self)

func get_icon() -> String:
	return "🌀" # Symbolizes cycles, rebirth, and transformation

# Returns the type as specified in the json
func get_type() -> String:
	return "reincarnation"
