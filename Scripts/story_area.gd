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
var system_prompt: String = "you are a story writing assistant" : set = set_system_prompt, get = get_system_prompt
var say: String = "generate an area in the kingdom" : set = set_say, get = get_say
# Signal to emit when a new action is added
signal action_added(myarea: StoryArea)

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

func set_description(value: String) -> void:
	description = value

func get_description() -> String:
	return description

func set_system_prompt(value: String) -> void:
	system_prompt = value

func get_system_prompt() -> String:
	return system_prompt

func set_say(value: String) -> void:
	say = value

func get_say() -> String:
	return say

# Function to return all properties as a dictionary
func get_properties() -> Dictionary:
	return {
		"name": name,
		"story_actions": story_actions.map(func(action): return action.get_properties()),
		"tier": tier,
		"state": state,
		"story_point_requirement": story_point_requirement,
		"system_prompt": system_prompt,
		"say": say
	}

# Function to parse a JSON string and add a StoryAction
func add_story_action_from_json(json_string: String) -> void:
	print_debug("adding a story action from json")
	# Attempt to parse the JSON string
	var data: Dictionary = JSON.parse_string(json_string) if json_string else {}
	if data.is_empty():
		print("Failed to parse story action from JSON:", json_string)
		return
	
	var action_description: String = data.get("message", "No description provided")

	# Create a new StoryAction and set properties
	var new_action: StoryAction = StoryAction.new()
	new_action.set_story_text(action_description)
	new_action.set_stars(1)  # Default to 1 star or customize based on data
	new_action.set_story_points(1)  # Default to 1 story point or customize based on data
	new_action.area = self
	
	# Add the new action to the list and update
	story_actions.append(new_action)
	# Emit the signal after adding the action
	
	print_debug("emitting action_added")
	action_added.emit(self)
