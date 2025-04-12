extends Label

@export var action_list: VBoxContainer = null

const DEFAULT_LABEL_TEXT: String = "Story points: 0/100"

# === RESOURCE DATA STRUCTURES ===

# Stores all active resources by name.
# Each value is a ResourceData instance that holds visible, hidden, permanent, etc.
var resources: Dictionary = {}

# Tracks per-second generation by resource
# Example: { "Focus": { "permanent": 1.0, "temporary": 0.5 } }
var generation_data: Dictionary = {}

# Optional: loaded from JSON, used only for tooltip max displays
var resource_caps_data: Dictionary = {}

# Reference to the label node this script is attached to
@onready var story_point_label := self
@onready var generation_timer: Timer = $OneSecondTimer


# === ENGINE HOOK ===

func _ready():
	_load_resource_caps()

	# Connect event signals
	connect_resource_updated("Story points", _on_story_points_updated)
	SignalBroker.action_rewarded.connect(_on_action_rewarded)
	SignalBroker.area_pressed.connect(_on_area_pressed)
	generation_timer.timeout.connect(_on_generation_timer_timeout)


# === EVENT HANDLERS ===

# Applies the rewards from an action using ResourceReward instances
func _on_action_rewarded(myaction: StoryAction):
	for key in myaction.get_rewards().keys():
		var reward: ResourceReward = myaction.get_rewards()[key]
		var resource := _get_or_create_resource(key)
		reward.apply_to(resource)
	_update_tooltip()


# Called when an area is pressed — checks and consumes unlock requirements
func _on_area_pressed(myarea: StoryArea) -> void:
	if not myarea.get_state() == StoryArea.State.LOCKED:
		return

	var requirements: Dictionary = myarea.get_requirements()

	if not can_fulfill_requirements(requirements):
		print_debug("Tried to unlock area, but not enough resources.")
		return

	if consume(requirements):
		myarea.unlock()

# Called when a ResourceData emits its resource_updated signal.
func _on_resource_data_updated(_resource: ResourceData) -> void:
	# Re-emit the global update signal.
	SignalBroker.resources_updated.emit(self)


# === UI DISPLAY ===

# Called only when the "Story points" resource is updated
func _on_story_points_updated(resource: ResourceData) -> void:
	text = "Story points: %d/%d" % [int(resource.get_temporary()), int(resource.get_capacity())]
	_update_tooltip()

# Rebuilds the tooltip with visible + permanent resources
func _update_tooltip() -> void:
	var lines := []
	var added: int = 0
	var max_items: int = 20
	for key in resources.keys():
		if key.begins_with("h_"):
			continue # Don't display hidden resources
		var res: ResourceData = resources[key]
		var restooltip: String = res.get_tooltip()
		if restooltip.length() < 4:
			continue
		lines.append(restooltip)
		added += 1
		if added >= max_items:
			break
	tooltip_text = "\n".join(lines)


# === REWARDS / GENERATION ===

# Applies a dictionary of raw reward data (e.g., from JSON or external input)
# Example:
# {
#   "Story points": { "amount": 5, "capacity": 100 },
#   "Focus": { "regeneration": 0.5 }
# }
func apply_rewards(rewards: Dictionary) -> bool:
	var success := false
	for key in rewards:
		var reward := ResourceReward.new()
		var reward_data = rewards[key]
		# Test if it is just a number. In that case, we add it as temporary
		if typeof(reward_data) == TYPE_FLOAT or typeof(reward_data) == TYPE_INT:
			reward.from_dict({"temporary": float(reward_data)})
		else:
			reward.from_dict(reward_data)
		var resource := _get_or_create_resource(key)
		reward.apply_to(resource)
		success = true

	SignalBroker.resources_updated.emit(self)
	return success

# Assigns regeneration values for a resource
# Example: add_generation("Focus", { "permanent": 1.0, "temporary": 0.5 })
func add_generation(key: String, data: Dictionary) -> void:
	var permanent = data.get("permanent", 0.0)
	var temporary = data.get("temporary", 0.0)
	generation_data[key] = { "permanent": permanent, "temporary": temporary }

# Applies regeneration to all resources and emits update signal only if something changed
func update_generation(delta: float) -> void:
	var changed := false
	for res in resources.values():
		if res.apply_regeneration(delta):
			changed = true
	if changed:
		SignalBroker.resources_updated.emit(self)


# === REQUIREMENTS ===

# Checks whether all requirements can be fulfilled
# Expects: Dictionary<String, ResourceRequirement>
func can_fulfill_requirements(reqs: Dictionary) -> bool:
	for key in reqs:
		if not resources.has(key):
			return false
		if not reqs[key].can_fulfill(resources[key]):
			return false
	return true

# Consumes the values from requirements if they can be fulfilled
func consume(reqs: Dictionary) -> bool:
	if not can_fulfill_requirements(reqs):
		return false

	for key in reqs:
		reqs[key].consume_from(resources[key])

	SignalBroker.resources_updated.emit(self)
	return true

# === VALUE ACCESS ===

# Gets the value of a specific resource group
# Example: get_value("Resolve", true)
func get_value(key: String, permanent: bool = false) -> float:
	if not resources.has(key):
		return 0.0
	return resources[key].get_permanent() if permanent else resources[key].get_temporary()


# Get the total value of the given key
func get_total_value(key: String) -> float:
	var temporary_value: float = get_value(key)
	var permanent_value: float = get_value(key, true)
	return temporary_value+permanent_value

# Gets the resource of a specific key, for example "Resolve" or "Story points"
func get_resource(key: String) -> ResourceData:
	return _get_or_create_resource(key)

# Returns true if the resource exists
func has_resource(key: String) -> bool:
	return resources.has(key)

# For UI purposes only: shows max from caps.json
func get_resource_max(group: String, resource_name: String) -> float:
	return resource_caps_data.get(group, {}).get(resource_name, 0)

# Returns whether the given resource is at visible capacity
func is_at_capacity(key: String) -> bool:
	if not resources.has(key):
		return false
	return resources[key].is_at_capacity()

# Returns true if all given resource keys are at capacity
func are_all_at_capacity(resource_keys: Array) -> bool:
	for key in resource_keys:
		if not is_at_capacity(key):
			return false
	return true


# === INTERNAL HELPERS ===

# Ensures a resource exists and returns it
func _get_or_create_resource(key: String) -> ResourceData:
	if not resources.has(key):
		# Create the ResourceData instance
		var new_resource = ResourceData.new(key, resource_caps_data.get(key, 0.0))
		# Connect the resource_updated signal to our callback
		new_resource.resource_updated.connect(_on_resource_data_updated)
		resources[key] = new_resource
	return resources[key]

# === LOADERS ===

# Loads display-only max values from JSON (UI only)
func _load_resource_caps() -> void:
	var file = FileAccess.open("res://JSON/resource_caps.json", FileAccess.READ)
	if file:
		var content := file.get_as_text()
		var json = JSON.parse_string(content)
		if json is Dictionary:
			resource_caps_data = json
		else:
			print_debug("Failed to parse resource_caps.json")
	else:
		print_debug("Failed to load resource_caps.json")

# Called once per second by the GenerationTimer
func _on_generation_timer_timeout() -> void:
	update_generation(1.0)

# Resets all resources and removes any that become empty (all values = 0.0)
func reset_all_resources(include_permanent: bool = false) -> void:
	for key in resources.keys():
		resources[key].reset(include_permanent)

# Connects to the resource_updated signal of a resource using a Callable.
# If the resource doesn't exist yet, it is created.
func connect_resource_updated(key: String, callback: Callable) -> void:
	var resource: ResourceData = _get_or_create_resource(key)
	if not resource.resource_updated.is_connected(callback):
		resource.resource_updated.connect(callback)
