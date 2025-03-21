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
var say: String = "generate an area in the area" : set = set_say, get = get_say
# Constant for the maximum number of story actions
const MAX_STORY_ACTIONS: int = 10
# Signal to emit when a new action is added
signal action_added(myarea: StoryArea)
signal unlocked(myarea: StoryArea)

# Initialize from a dictionary
func _init(data: Dictionary = {}) -> void:
	set_name(data.get("name", ""))
	set_description(data.get("description", ""))
	set_tier(data.get("tier", 1))
	set_story_point_requirement(data.get("story_point_requirement", 100))
	
	# Initialize story actions if present
	if data.has("story_actions"):
		var actions_data = data["story_actions"]
		for action_data in actions_data:
			var new_action = create_action(action_data)
			new_action.area = self
			story_actions.append(new_action)


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

func set_system_prompt(value: String) -> void:
	system_prompt = value

func get_system_prompt() -> String:
	# Get the area description from the associated area
	var area_description: String = get_description()
	#print_debug("returning area description: " + area_description)
	# Replace the placeholder with the actual area description
	return "You are a story writing assistant. Your job is to create short messages (up to 20 words). " +\
		   "Each message should describe a creative and engaging action or dialogue that reflects the atmosphere " +\
		   "and activity of the following setting: %s. " % area_description +\
		   "The action or dialogue should feel natural, varied, and influenced by the location, its landmarks, and its inhabitants."
#
	#print_debug("returning system prompt for area" + name + ": " + system_prompt)
	#return system_prompt

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
	#print_debug("adding a story action from json")

	# Ensure we don't exceed the maximum number of actions
	if story_actions.size() >= MAX_STORY_ACTIONS:
		print_debug("Cannot add story action — maximum limit reached (%d)" % MAX_STORY_ACTIONS)
		return
	
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
	new_action.set_story_points(10)  # Default to 1 story point or customize based on data
	new_action.area = self
	
	# Add the new action to the list
	story_actions.append(new_action)

	# Emit the signal after adding the action
	#print_debug("emitting action_added")
	action_added.emit(self)

# Function to remove a StoryAction from the list
func remove_story_action(action: StoryAction) -> void:
	if action in story_actions:
		story_actions.erase(action)
		print_debug("Removed story action:", action.get_story_text())
	else:
		print_debug("Action not found in list:", action.get_story_text())

# Function to check if the story actions list is at capacity
func is_at_capacity() -> bool:
	return story_actions.size() >= MAX_STORY_ACTIONS

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


func create_action(data: Dictionary) -> StoryAction:
	var action_type = data.get("action_type", "free").to_lower()

	match action_type:
		"free":
			return FreeAction.new(data)
		"repeat":
			return RepeatAction.new(data)
		"chain":
			return ChainAction.new(data)
		"combat":
			return CombatAction.new(data)
		"exploration":
			return ExplorationAction.new(data)
		"loop":
			return LoopAction.new(data)
		"salvage":
			return SalvageAction.new(data)
		"find":
			return FindAction.new(data)
		"timed":
			return TimedAction.new(data)
		"multi_step":
			return MultiStepAction.new(data)
		"puzzle":
			return PuzzleAction.new(data)
		_:
			print_debug("Unknown action type: %s" % action_type)
			return FreeAction.new(data)
