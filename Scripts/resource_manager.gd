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
	SignalBroker.resources_updated.connect(_on_resources_updated)
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

	SignalBroker.resources_updated.emit(self)


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

# Updates the story point display label
func _on_resources_updated(_data = null) -> void:
	_update_display()

func _update_display() -> void:
	var story_points := get_value("Story points", "visible")
	text = "Story points: %d/100" % int(story_points)
	_update_tooltip()

# Rebuilds the tooltip with visible + permanent resources
func _update_tooltip() -> void:
	var lines := []
	var added: int = 0
	var max_items: int = 20
	for key in resources.keys():
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
#   "Story points": { "visible": 5, "capacity": 100 },
#   "Focus": { "regeneration": 0.5 }
# }
func apply_rewards(rewards: Dictionary) -> bool:
	var success := false
	for key in rewards:
		var reward := ResourceReward.new()
		reward.from_dict(rewards[key])
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

	_prune_zeros()
	SignalBroker.resources_updated.emit(self)
	return true


# === VALUE ACCESS ===

# Gets the value of a specific resource group
# Example: get_value("Resolve", "visible")
func get_value(key: String, group: String) -> float:
	if not resources.has(key):
		return 0.0

	match group:
		"visible": return resources[key].get_visible()
		"hidden": return resources[key].get_hidden()
		"permanent": return resources[key].get_permanent()
		_: return 0.0

# Gets the resource of a specific key, for example "Resolve" or "Story points"
func get_resource(key: String) -> ResourceData:
	return resources.get(key, null)

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
		var new_resource = ResourceData.new(key, resource_caps_data.get("visible", {}).get(key, 0.0))
		# Connect the resource_updated signal to our callback
		new_resource.resource_updated.connect(_on_resource_data_updated)
		resources[key] = new_resource
	return resources[key]

# Removes unused resources with 0 total
func _prune_zeros() -> void:
	var to_remove := []
	for key in resources:
		var res: ResourceData = resources[key]
		if res.get_total() == 0.0:
			# Disconnect the resource_updated signal before removing the resource
			if res.resource_updated.is_connected(_on_resource_data_updated):
				res.resource_updated.disconnect(_on_resource_data_updated)
			to_remove.append(key)
	for key in to_remove:
		resources.erase(key)

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
	var to_remove: Array[String] = []

	for key in resources.keys():
		var res: ResourceData = resources[key]
		if res.reset(include_permanent):
			to_remove.append(key) # reset returned true, so all values are empty, remove it

	for key in to_remove:
		resources.erase(key)
	SignalBroker.resources_updated.emit(self)
