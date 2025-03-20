class_name StoryArea
extends RefCounted

# Enums for state
enum State { LOCKED, UNLOCKED }

# Properties with default values
var story_actions: Array[StoryAction] = [] : set = set_story_actions, get = get_story_actions
var tier: int = 1 : set = set_tier, get = get_tier
var state: State = State.LOCKED : set = set_state, get = get_state
var story_point_requirement: int = 100 : set = set_story_point_requirement, get = get_story_point_requirement
var name: String = "" : set = set_name, get = get_name

# Setters and Getters
func set_story_actions(value: Array[StoryAction]) -> void:
	story_actions = value

func get_story_actions() -> Array[StoryAction]:
	return story_actions

func set_tier(value: int) -> void:
	tier = clamp(value, 1, 10)  # Ensure tier is between 1 and 10

func get_tier() -> int:
	return tier

func set_state(value: State) -> void:
	state = value

func get_state() -> State:
	return state

func set_story_point_requirement(value: int) -> void:
	story_point_requirement = max(value, 0)  # Ensure non-negative

func get_story_point_requirement() -> int:
	return story_point_requirement

# Setter and Getter for name
func set_name(value: String) -> void:
	name = value

func get_name() -> String:
	return name

# Function to return all properties as a dictionary
func get_properties() -> Dictionary:
	return {
		"name": name,
		"story_actions": story_actions.map(func(action): return action.get_properties()),
		"tier": tier,
		"state": state,
		"story_point_requirement": story_point_requirement
	}
