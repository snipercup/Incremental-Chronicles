class_name StoryAction
extends RefCounted

#Example json:
#{
  #"action_type": "combat",
  #"requirements": {
	#"Resolve": 1.0
  #},
  #"rewards": {
	#"Story Point": 10.0
  #},
  #"hidden_rewards": {
	#"hidden_rat_reward": 1.0
  #},
  #"story_text": "A rat scurries toward you, teeth bared and eyes gleaming in the dim light. You prepare to defend yourself.",
  #"enemy": {
	#"name": "Rat",
	#"strength": 1.0
  #}
#},
#{
  #"action_type": "free",
  #"appear_requirements": {
	#"hidden_rat_reward": 1.0
  #},
  #"rewards": {
	#"Story Point": 1.0
  #},
  #"story_text": "Examine the defeated rat."
#}

# Properties with default values
var rewards: Dictionary = {} : set = set_rewards, get = get_rewards
var story_text: String = "" : set = set_story_text, get = get_story_text
var requirements: Dictionary = {} : set = set_requirements, get = get_requirements
# New dictionaries for hidden rewards and appear requirements
var hidden_rewards: Dictionary = {} : set = set_hidden_rewards, get = get_hidden_rewards
var appear_requirements: Dictionary = {} : set = set_appear_requirements, get = get_appear_requirements

# New state enum for action visibility
enum State { VISIBLE, HIDDEN }

# State variable with default state
var state: State = State.HIDDEN : set = set_state, get = get_state
var area: StoryArea

# Initialize from a dictionary
func _init(data: Dictionary = {}, myarea: StoryArea = null) -> void:
	set_story_text(data.get("story_text", ""))
	set_requirements(data.get("requirements", {}))
	set_rewards(data.get("rewards", {}))
	set_hidden_rewards(data.get("hidden_rewards", {}))
	set_appear_requirements(data.get("appear_requirements", {}))
	area = myarea

	# If there are appear requirements, set state to hidden
	if not appear_requirements.is_empty():
		set_state(State.HIDDEN)
	else:
		set_state(State.VISIBLE)

	# Connect to the hidden_resources_updated signal
	SignalBroker.hidden_resources_updated.connect(_on_hidden_resources_updated)


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

# Setter for hidden rewards
func set_hidden_rewards(value: Dictionary) -> void:
	hidden_rewards = value.duplicate(true)

# Getter for hidden rewards
func get_hidden_rewards() -> Dictionary:
	return hidden_rewards

# Setter for appear requirements
func set_appear_requirements(value: Dictionary) -> void:
	appear_requirements = value.duplicate(true)

# Getter for appear requirements
func get_appear_requirements() -> Dictionary:
	return appear_requirements

# Setter for state
func set_state(value: State) -> void:
	if state != value:
		state = value
		# Emit signal when the state changes
		SignalBroker.action_state_changed.emit(self)

# Getter for state
func get_state() -> State:
	return state

# Update get_properties to include the new state
func get_properties() -> Dictionary:
	return {
		"story_text": story_text,
		"requirements": requirements,
		"rewards": rewards,
		"hidden_rewards": hidden_rewards,
		"appear_requirements": appear_requirements,
		"state": state
	}

# Check if the player meets all the action's requirements
func can_perform_action(resources: Dictionary) -> bool:
	for key in requirements.keys():
		if resources.get(key, 0) < requirements[key]:
			return false
	return true

# Called when hidden resources are updated
func _on_hidden_resources_updated(resource_manager: Label) -> void:
	if appear_requirements.is_empty() or get_state() == StoryAction.State.VISIBLE:
		return # No need to run any more code if there are no requirements or already visible

	# Check if requirements are met before consuming
	if resource_manager.has_required_resources(appear_requirements, true):
		set_state(State.VISIBLE)
		if not resource_manager.consume_resources(appear_requirements, true):
			set_state(State.HIDDEN)
	else:
		set_state(State.HIDDEN)
