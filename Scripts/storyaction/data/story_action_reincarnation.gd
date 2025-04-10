class_name ReincarnationAction
extends StoryAction

# This script represents the ReincarnationAction class. 
# A reincarnation action is the final action in a run and will reset the game

# Example reincarnation action data
#	{
#	  "action_type": "reincarnation",
#	  "requirements": {
#		"h_reincarnation_ready": { "appear": { "min": 1.0 } },
#		"h_has_soul_vessel": { "appear": { "min": 1.0 } }
#	  },
#	  "rewards": {
#		"Story points": 10.0,
#		"Reincarnation": 1.0,
#		"h_reincarnation_started": 0.0
#	  },
#	  "story_text": "The soul vessel glows. Light floods your vision as your form dissolves. You are reborn \u2014 stronger, wiser, and bound to a greater cycle."
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
