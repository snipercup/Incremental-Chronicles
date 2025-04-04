class_name StoryArea
extends RefCounted

# Example data:
#{
#	"description": "A weathered tunnel opens to rugged plains, golden grasses swaying beneath a breeze. Ruins and hidden paths await discovery.",
#  "name": "Village",
#  "tier": 1.0,
#	"requirements": {
#	  "visible": { "Resolve": {"consume": 20.0} },
#	  "hidden": { "path_obstructed": {"appear":{"min": 1.0}} },
#	  "permanent": { "Intelligence": {"amount": 1.0} },
#	  "sum": { "Strength": {"amount": 1.0} }
#	}
#  "story_actions": [
#	{
#	  "action_type": "free",
#	  "rewards": {
#		"visible": {
#		  "Story points": 5.0,
#		  "Strength": 1.0
#		}
#	  },
#	  "story_text": "Lift a stone."
#	}
#	]
#}


# Enums for state
enum State { LOCKED, UNLOCKED }

# Properties with default values
var story_actions: Array[StoryAction] = [] : set = set_story_actions, get = get_story_actions
var tier: int = 1 : set = set_tier, get = get_tier
var state: State = State.LOCKED : set = set_state, get = get_state
var name: String = "" : set = set_name, get = get_name
var description: String = "" : set = set_description, get = get_description
# Visibility enum and state
enum VisibilityState { VISIBLE, HIDDEN }
var visibility_state: VisibilityState = VisibilityState.HIDDEN : set = set_visibility_state, get = get_visibility_state

# Signal to emit when a new action is added
@warning_ignore("unused_signal")
signal action_added(myarea: StoryArea)

# The requirements to unlock this area. Example
#	  "requirements": {
#		"visible": { "Resolve": {"consume": 20.0} },
#		"hidden": { "path_obstructed": {"appear":{"min": 1.0}} },
#		"permanent": { "Intelligence": {"amount": 1.0} },
#		"sum": { "Strength": {"amount": 1.0} }
#	  }
var requirements: Dictionary = {} : set = set_requirements, get = get_requirements

# Initialize from a dictionary
func _init(data: Dictionary = {}) -> void:
	set_name(data.get("name", ""))
	set_description(data.get("description", ""))
	set_tier(data.get("tier", 1))
	set_requirements(data.get("requirements", {}))  # Initialize dictionary for requirements
	
	# Initialize story actions if present
	if data.has("story_actions"):
		var actions_data: Array = data["story_actions"]
		for action_data: Dictionary in actions_data:
			var new_action: StoryAction = create_action(action_data)
			story_actions.append(new_action)
	SignalBroker.action_removed.connect(remove_story_action)

	# If there are appear requirements, the action is hidden
	var appear_requirements := ResourceUtils.filter_requirements_by_type(requirements, "appear")
	if appear_requirements.is_empty():
		set_visibility_state(VisibilityState.VISIBLE)
	else:
		set_visibility_state(VisibilityState.HIDDEN)
	# Listen for hidden resource updates
	SignalBroker.resources_updated.connect(_on_resources_updated)

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

# Setter and Getter for name
func set_name(value: String) -> void:
	name = value

func get_name() -> String:
	return name

func set_description(value: String) -> void:
	description = value

func get_description() -> String:
	return description

# Setters and Getters
func set_requirements(value: Dictionary) -> void:
	requirements = value.duplicate(true)
	var consume_requirements := ResourceUtils.filter_requirements_by_type(requirements, "consume")
	if consume_requirements.is_empty():
		set_state(State.UNLOCKED)

func get_requirements() -> Dictionary:
	return requirements

# Function to unlock the area if enough resources are provided
func unlock() -> bool:
	if state == State.UNLOCKED:
		return false

	# If all requirements are met, unlock the area
	state = State.UNLOCKED
	requirements.clear()
	SignalBroker.area_unlocked.emit(self)
	return true

# Update the get_properties function to include the new requirements dictionary
func get_properties() -> Dictionary:
	return {
		"name": name,
		"description": description,
		"tier": tier,
		"state": state,
		"requirements": requirements,
		"story_actions": story_actions.map(func(action): return action.get_properties()),
		"visibility_state": visibility_state
	}

# Function to remove a StoryAction from the list
func remove_story_action(action: StoryAction) -> void:
	if action in story_actions:
		story_actions.erase(action)
		print_debug("Removed story action:", action.get_story_text())
		
		# Emit area_removed if no more actions remain
		if story_actions.is_empty():
			SignalBroker.area_removed.emit(self)
	else:
		print_debug("Action not found in list:", action.get_story_text())


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
		"reincarnation":
			return ReincarnationAction.new(data, self)
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


func set_visibility_state(value: VisibilityState) -> void:
	if visibility_state != value:
		visibility_state = value
		SignalBroker.area_visibility_changed.emit(self)

func get_visibility_state() -> VisibilityState:
	return visibility_state

# When the Resource Manager updates the hidden resources, we update the visibility
func _on_resources_updated(resource_store: ResourceStore) -> void:
	if get_visibility_state() == VisibilityState.VISIBLE:
		return

	# Build a new appear_requirements dictionary based on new format
	var appear_requirements := ResourceUtils.filter_requirements_by_type(requirements, "appear")
	# No appear requirements = always visible
	if appear_requirements.is_empty():
		set_visibility_state(VisibilityState.VISIBLE)
		return

	# Check if appear requirements are met
	if resource_store.can_fulfill_requirements(appear_requirements):
		set_visibility_state(VisibilityState.VISIBLE)
	else:
		set_visibility_state(VisibilityState.HIDDEN)
