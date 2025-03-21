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
var description: String = "" : set = set_description, get = get_description
# Signal to emit when a new action is added
signal action_added(myarea: StoryArea)
signal unlocked(myarea: StoryArea)

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
	if story_point_requirement == 0:
		state = State.UNLOCKED # If no requirements, the state becomes unlocked

func get_story_point_requirement() -> int:
	return story_point_requirement

# Setter and Getter for name
func set_name(value: String) -> void:
	name = value

func get_name() -> String:
	return name

func set_description(value: String) -> void:
	description = value

func get_description() -> String:
	return description


# Function to return all properties as a dictionary
func get_properties() -> Dictionary:
	return {
		"name": name,
		"story_actions": story_actions.map(func(action): return action.get_properties()),
		"tier": tier,
		"state": state,
		"story_point_requirement": story_point_requirement
	}


# Function to remove a StoryAction from the list
func remove_story_action(action: StoryAction) -> void:
	if action in story_actions:
		story_actions.erase(action)
		print_debug("Removed story action:", action.get_story_text())
	else:
		print_debug("Action not found in list:", action.get_story_text())


# Function to unlock the area if enough story points are provided
func unlock_with_story_points(points: int) -> int:
	# Check if the area is already unlocked
	if state == State.UNLOCKED:
		return -1
	
	# If enough points are available, unlock the area
	if points >= story_point_requirement:
		state = State.UNLOCKED
		var leftover_points = points - story_point_requirement
		story_point_requirement = 0
		unlocked.emit(self)
		return leftover_points
	
	# Not enough points to unlock the area
	return -1
