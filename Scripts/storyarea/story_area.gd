class_name StoryArea
extends RefCounted

# Example data:
#{
#	"description": "A weathered tunnel opens onto the side of a rugged mountain, its jagged stone mouth framed by dark, mossy rock. The tunnel’s interior is cold and quiet, with no sign of an entrance behind it — only smooth stone where a path should be.\n\nBeyond the tunnel, a vast wilderness unfolds beneath the mountain’s shadow. Rolling plains stretch endlessly toward the horizon, their golden grasses swaying beneath a steady breeze. The scent of wildflowers and fresh earth drifts through the air. Clusters of weathered stone rise from the earth, remnants of ancient ruins half-swallowed by time and nature.\n\nThe ground beneath the grass is uneven, strewn with pebbles and patches of bare earth. A faint trail winds eastward through the plains, disappearing into the distant haze. The air is crisp and cool, inviting exploration. The plains seem quiet — but the signs of life are everywhere, waiting to be uncovered.",
#	"name": "Tunnel",,
#	"story_point_requirement": 0.0,
#	"tier": 1.0
#	"story_actions": [
#		{
#			"action_type": "free",
#			"rewards": {
#				"Story Point": 1.0,
#				"Strength": 1.0
#			},
#			"story_text": "Lift a stone."
#		},
#	]
#}


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
@warning_ignore("unused_signal")
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
		var actions_data: Array = data["story_actions"]
		for action_data: Dictionary in actions_data:
			var new_action: StoryAction = create_action(action_data)
			new_action.area = self
			story_actions.append(new_action)
	SignalBroker.action_removed.connect(remove_story_action)

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


#Example data:
#{
  #"rewards": {
	#"Story Point": 1.0
  #},
  #"story_text": "Search for hidden objects or tracks.",
  #"action_type": "free"
#}
func create_action(data: Dictionary) -> StoryAction:
	var action_type = data.get("action_type", "free").to_lower()
	var story_text = data.get("story_text", "").to_lower()
	if not story_text:
		print_debug("no story text set for this action: " + str(data))
		return null

	match action_type:
		"free":
			return FreeAction.new(data, self)
		"repeat":
			return RepeatAction.new(data, self)
		"chain":
			return ChainAction.new(data, self)
		"combat":
			return CombatAction.new(data, self)
		"exploration":
			return ExplorationAction.new(data, self)
		"loop":
			return LoopAction.new(data, self)
		"salvage":
			return SalvageAction.new(data, self)
		"find":
			return FindAction.new(data, self)
		"timed":
			return TimedAction.new(data, self)
		"multi_step":
			return MultiStepAction.new(data, self)
		"puzzle":
			return PuzzleAction.new(data, self)
		_:
			print_debug("Unknown action type: %s" % action_type)
			return FreeAction.new(data, self)
