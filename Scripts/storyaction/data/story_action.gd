class_name StoryAction
extends RefCounted

#Example json:
#	{
#	  "action_type": "combat",
#	  "requirements": {
#		"visible": { "Resolve": {"consume": 20.0} },
#		"hidden": { "path_obstructed": {"appear":{"min": 1.0}} },
#		"permanent": { "Intelligence": {"amount": 1.0} },
#		"sum": { "Strength": {"amount": 1.0} }
#	  },
#	  "rewards": {
#		"visible": {
#		  "Story points": 15.0
#		},
#		"hidden": {
#		  "hidden_rat_reward": 1.0
#		}
#	  },
#	  "story_text": "A rat scurries toward you, teeth bared and eyes gleaming in the dim light. You prepare to defend yourself.",
#	  "enemy": {
#		"name": "Rat",
#		"strength": 1.0
#	  }
#	},
#	{
#	  "action_type": "free",
#	  "requirements": {
#		"hidden": {
#			"hidden_rat_reward": {"type": "appear", "min": 1.0}
#		}
#	  },
#	  "rewards": {
#		"visible": {
#		  "Story points": 5.0
#		}
#	  },
#	  "story_text": "Examine the defeated rat."
#	}

# Properties with default values
var rewards: Dictionary = {} : set = set_rewards, get = get_rewards
var story_text: String = "" : set = set_story_text, get = get_story_text
var requirements: Dictionary = {} : set = set_requirements, get = get_requirements

# New state enum for action visibility
enum State { VISIBLE, HIDDEN }

# State variable with default state
var state: State = State.HIDDEN : set = set_state, get = get_state
var area: StoryArea

# Initialize from a dictionary
func _init(data: Dictionary = {}, myarea: StoryArea = null) -> void:
	set_story_text(data.get("story_text", ""))
	set_requirements(data.get("requirements", {}))
	set_rewards(data.get("rewards", {}))  # Already includes hidden rewards inside
	area = myarea

	# If there are appear requirements, the action is hidden
	var appear_requirements := ResourceUtils.filter_requirements_by_type(requirements, "appear")
	state = State.VISIBLE if appear_requirements.is_empty() else State.HIDDEN
	SignalBroker.resources_updated.connect(_on_resources_updated)

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
		"state": state
	}

# Called when resources are updated
func _on_resources_updated(resource_store: ResourceStore) -> void:
	if get_state() == State.VISIBLE:
		return

	var appear_requirements := ResourceUtils.filter_requirements_by_type(requirements, "appear")
	if appear_requirements.is_empty():
		set_state(State.VISIBLE)
		return

	if resource_store.can_fulfill_requirements(appear_requirements):
		set_state(State.VISIBLE)
	else:
		set_state(State.HIDDEN)

func get_hidden_rewards() -> Dictionary:
	return rewards.get("hidden", {})

# Returns the type of action. For the base class, this will be "action"
# For other classes, it will be "combat", "free", "loop" etc. as they override this function
func get_type() -> String:
	return "action"
