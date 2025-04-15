class_name StoryAction
extends RefCounted

# === ENUM ===
enum State { VISIBLE, HIDDEN }

# === PROPERTIES ===

# Requirements per resource:
# {
#   "Story points": ResourceRequirement.new()
# }
var requirements: Dictionary[String,ResourceRequirement] = {} : set = set_requirements, get = get_requirements
# Exaple rewards:
#	  "rewards": {
#		"Story points": 15.0, //Adds temporary points
#		"Focus": { "regeneration": 0.1 }, //Adds to regeneration amount
#		"Perception": { "permanent": 1 }, //Adds to permanent amount
#		"Perception": { "temporary": 1 }, //Adds to temporary amount
#		"Story Points": { "capacity": 10 }, //adds to max capacity
#		"h_hidden_rat_reward": 1.0 //Adds to temporary amount
#	  }
var rewards: Dictionary[String,ResourceReward] = {}  # Hold visible/hidden/permanent rewards


var story_text: String = "" : set = set_story_text, get = get_story_text
var state: State = State.HIDDEN : set = set_state, get = get_state
var area: StoryArea


# === INIT ===

func _init(data: Dictionary = {}, myarea: StoryArea = null) -> void:
	set_story_text(data.get("story_text", ""))
	set_requirements(data.get("requirements", {}))
	set_rewards(data.get("rewards", {}))
	area = myarea

	state = State.VISIBLE if _has_no_appear_requirements() else State.HIDDEN
	SignalBroker.area_pressed.connect(_on_area_pressed)


# === REQUIREMENTS ===

# Expects the format:
# {
#   "Resolve": {
#		"consume": 1.0, //Consume temporary
#		"consume": 1.0, "permanent": true //Consume permanent
#		"appear": { "min": 1.0, "max": 2.0 }, // Appear requirement, no consumption
#		"appear": { "regeneration": { "max": 0.0 } } // appear requirement for max generation
#		"appear": { "permanent_capacity": { "max": 0.0 } } // appear requirement for permanent max capacity
#		20.0, // Just a number. Player needs at least 20 total, but nothing is consumed
#   }
# }
func set_requirements(value: Dictionary) -> void:
	requirements.clear()
	for res_name in value:
		var req := ResourceRequirement.new()
		req.from_dict(value[res_name])
		requirements[res_name] = req


func get_requirements() -> Dictionary:
	return requirements


# === REWARDS ===

func set_rewards(value: Dictionary) -> void:
	rewards.clear()

	for key in value:
		var reward_data = value[key]
		var reward := ResourceReward.new()
		# Test if it is just a number. In that case, we add it as temporary
		if typeof(reward_data) == TYPE_FLOAT or typeof(reward_data) == TYPE_INT:
			reward.from_dict({"temporary": float(reward_data)})
		else:
			reward.from_dict(reward_data)
		rewards[key] = reward


func get_rewards() -> Dictionary:
	return rewards


# === STORY TEXT ===

func set_story_text(value: String) -> void:
	story_text = value

func get_story_text() -> String:
	return story_text


# === STATE ===

func set_state(value: State) -> void:
	if state != value:
		state = value
		SignalBroker.action_state_changed.emit(self)

func get_state() -> State:
	return state


# === RESOURCE MONITORING ===

# Called on resource change; evaluates if action should be revealed
func _on_resources_updated(resource_store: Label) -> void:
	if _can_fulfill_appear_requirements(resource_store):
		set_state(State.VISIBLE)
	else:
		set_state(State.HIDDEN)

# Force resource update in case SignalBroker.resources_updated is disconnected
func force_resources_update(resource_store: Label) -> void:
	_on_resources_updated(resource_store)

# Force area update in order to enforce the correct connection to resource updates
func force_area_update(myarea: StoryArea) -> void:
	_on_area_pressed(myarea)


# === APPEAR REQUIREMENTS ===

# Checks if any appear requirements exist
func _has_no_appear_requirements() -> bool:
	for key in requirements:
		var req: ResourceRequirement = requirements[key]
		if req.has_appear_requirements():
			return false
	return true

# Checks if all appear requirements are fulfilled in the given store
func _can_fulfill_appear_requirements(store: Label) -> bool:
	for key in requirements: # Example: "Resolve" or "Story points"
		var req: ResourceRequirement = requirements[key]
		# If it has a requirement before the action will appear, we test it here
		if req.has_appear_requirements():
			var resource: ResourceData = store.get_resource(key)
			if not req.does_appear_requirements_pass(resource):
				return false
	return true


# === META ===

func get_type() -> String:
	return "action"

func get_properties() -> Dictionary:
	return {
		"story_text": story_text,
		"requirements": requirements,
		"rewards": rewards,
		"state": state
	}

# Called when any area is pressed; check if it's this action's area and is unlocked
# We only listen for resource updates if this action's area is unlocked and pressed
func _on_area_pressed(myarea: StoryArea) -> void:
	var is_match: bool = myarea == area
	var is_unlocked: bool = myarea.get_state() != StoryArea.State.LOCKED
	var should_listen: bool = is_match and is_unlocked

	if should_listen:
		if not SignalBroker.resources_updated.is_connected(_on_resources_updated):
			SignalBroker.resources_updated.connect(_on_resources_updated)
	else:
		if SignalBroker.resources_updated.is_connected(_on_resources_updated):
			SignalBroker.resources_updated.disconnect(_on_resources_updated)


# Gets a dictionary of every resource and their requirement/rewards
func get_resource_summary(summary: Dictionary) -> void:
	for res_name: String in get_requirements().keys():
		var req: ResourceRequirement = get_requirements()[res_name]

		# Ensure the nested structure exists
		if not summary.has(res_name):
			summary[res_name] = {
				"temporary_consume": 0.0,
				"appear_min_total": 0.0,
				"temporary_reward": 0.0
			}

		# Apply temporary consumption
		if req.consume_temporary > 0.0:
			summary[res_name]["temporary_consume"] += req.consume_temporary

		# Apply appear_min_total (if present)
		if req.appear_min_total > 0.0:
			summary[res_name]["appear_min_total"] += req.appear_min_total

	for res_name in get_rewards().keys():
		var reward: ResourceReward = get_rewards()[res_name]

		# Ensure the nested structure exists
		if not summary.has(res_name):
			summary[res_name] = {
				"temporary_consume": 0.0,
				"appear_min_total": 0.0,
				"temporary_reward": 0.0
			}

		# Apply temporary reward
		if reward.temporary > 0.0:
			summary[res_name]["temporary_reward"] += reward.temporary
