class_name StoryAction
extends RefCounted

#Example json:
#{
	# "requirements": {
		#"Story Point": 1,
		#"Persistence": 1
	#},
	#"rewards": {
		#"Story Point": 1
	#},
	#"story_text": "Pick wildflowers."
#}

# Properties with default values
var rewards: Dictionary = {} : set = set_rewards, get = get_rewards
var story_text: String = "" : set = set_story_text, get = get_story_text
var requirements: Dictionary = {} : set = set_requirements, get = get_requirements
var area: StoryArea

# Initialize from a dictionary
func _init(data: Dictionary = {}) -> void:
	set_story_text(data.get("story_text", ""))
	set_requirements(data.get("requirements", {}))
	set_rewards(data.get("rewards", {}))


# Setter for requirements (ensure valid data)
func set_requirements(value: Dictionary) -> void:
	requirements = value.duplicate(true)

# Getter for requirements
func get_requirements() -> Dictionary:
	return requirements


# Setter for rewards (ensure valid data)
func set_rewards(value: Dictionary) -> void:
	rewards = value.duplicate(true)

# Getter for rewards
func get_rewards() -> Dictionary:
	return rewards

func set_story_text(value: String) -> void:
	story_text = value

func get_story_text() -> String:
	return story_text

# Function to return all properties as a dictionary
func get_properties() -> Dictionary:
	return {
		"story_text": story_text,
		"requirements": requirements,
		"rewards": rewards
	}

# Check if the player meets all the action's requirements
func can_perform_action(resources: Dictionary) -> bool:
	for key in requirements.keys():
		if resources.get(key, 0) < requirements[key]:
			return false
	return true
