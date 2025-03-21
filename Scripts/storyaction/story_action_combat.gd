class_name CombatAction
extends StoryAction

var attack_power: int = 5
var defense_power: int = 3

func perform_action() -> void:
	var success = attack_power > defense_power
	if success:
		print("Combat success! %s" % story_text)
	else:
		print("Combat failed... %s" % story_text)
