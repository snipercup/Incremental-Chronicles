class_name StoryArea
extends RefCounted

# Example data:
#{
#  "description": "You arrive in a quaint village nestled at the edge of the wilds. Cobblestone paths, wooden homes, and distant laughter fill the air. Something about this place feels safe... but not without mystery.",
#  "name": "Village",
#  "tier": 1.0,
#  "requirements": {
#	"Story points": {"consume":50.0},
#	"h_village_access": { "appear": { "min": 1.0 } }
#  },
#  "story_actions": [
#	{
#	  "action_type": "free",
#	  "rewards": { "Story points": 4.0, "h_npc_intro_1": 1.0 },
#	  "story_text": "A hooded villager steps forward. You... don't look like you're from here."
#	}
#  ]
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

# The requirements to unlock this area.
var requirements: Dictionary[String, ResourceRequirement] = {} : set = set_requirements, get = get_requirements
# Format: { "Resource Name": ResourceRequirement }

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
	
	var has_any_appear := false
	for req in requirements.values():
		if req.has_appear_requirements():
			has_any_appear = true
			break

	if not has_any_appear:
		set_visibility_state(VisibilityState.VISIBLE)
		return

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
	requirements.clear()
	var any_consume := false
	for key in value.keys():
		var raw_req: Dictionary = value[key]
		var req := ResourceRequirement.new()
		req.from_dict(raw_req)
		requirements[key] = req
		if req.has_resource_requirements():
			any_consume = true # At least one resource key is present

	if not any_consume:
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
		# Emit area_removed if no more actions remain
		if story_actions.is_empty():
			SignalBroker.area_removed.emit(self)


#Example data:
#	{
#	  "action_type": "free",
#	  "story_text": "Deliver the lantern oil to the chapel keeper for the dusk lighting.",
#	  "requirements": { "Lantern Oil": { "appear": { "min": 1.0 } } },
#	  "rewards": { "Resolve": 10.0 }
#	},
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
func _on_resources_updated(resource_store: Label) -> void:
	if get_visibility_state() == VisibilityState.VISIBLE:
		return # Already visible, no point in continuing

	var all_met := true

	for key in requirements.keys():
		var req: ResourceRequirement = requirements[key]
		var resource: ResourceData = resource_store.get_resource(key)

		# If the resource does not exist, treat it as failing the requirement
		if resource == null or not req.does_appear_requirements_pass(resource):
			all_met = false
			break

	set_visibility_state(VisibilityState.VISIBLE if all_met else VisibilityState.HIDDEN)

# Returns true if the action is in this area
func has_action(myaction: StoryAction) -> bool:
	return myaction in story_actions
