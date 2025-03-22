extends Label

@export var action_list: VBoxContainer = null
const DEFAULT_LABEL_TEXT: String = "Story points: 0/100"
var resources: Dictionary = {} 
# Dictionary to store parsed resource caps data
var resource_caps_data: Dictionary = {}
# Dictionary to store current caps for each resource
var current_resource_caps: Dictionary = {}


# Signal to emit when resources are updated
signal resources_updated(new_resources: Dictionary)

# Called when the node enters the scene tree.
func _ready():
	_load_resource_caps()
	if action_list:
		action_list.action_completed.connect(_on_action_completed)

# Called when an action is completed
func _on_action_completed(control: Control):
	var story_action: StoryAction = control.story_action
	var rewards = story_action.get_rewards()
	for key in rewards.keys():
		add_resource(key, rewards[key])

# Add to a resource (respect max capacity)
func add_resource(resource_name: String, amount: int) -> bool:
	if amount <= 0:
		return false
	
	var current_value = resources.get(resource_name, 0)
	var max_value = get_resource_max(resource_name)

	# Respect max capacity if there's a limit
	if max_value > 0:
		if current_value >= max_value:
			return false # No change since it's already at max
		resources[resource_name] = min(current_value + amount, max_value)
	else:
		resources[resource_name] = current_value + amount
	_update_resources()
	return true

# Remove from a resource
func remove_resource(resource_name: String, amount: int) -> void:
	if resource_name in resources:
		resources[resource_name] = max(resources[resource_name] - amount, 0)
		_update_resources()

# Set a resource to a specific value
func set_resource(resource_name: String, amount: int) -> void:
	resources[resource_name] = max(amount, 0)
	_update_resources()

# Update resource values and emit signal
func _update_resources() -> void:
	resources_updated.emit(resources)
	var story_points = resources.get("Story Point", 0)
	text = "Story points: %d/100" % story_points
	_update_tooltip()

# Get the value of a specific resource
func get_resource(resource_name: String) -> int:
	return resources.get(resource_name, 0)

# Get the max value of a specific resource
func get_resource_max(resource_name: String) -> int:
	return get_base_cap(resource_name)

# Function to get the base cap for a resource from RESOURCE_CAPS
func get_base_cap(resource_name: String) -> int:
	return resource_caps_data.get(resource_name, 0)

# Apply the action's rewards to the player's resources
func apply_rewards(rewards: Dictionary) -> bool:
	var added = false
	for key in rewards.keys():
		# If any resource is successfully added, return true
		if add_resource(key, rewards[key]):
			added = true
	return added


# Update the tooltip with the first 10 resources
func _update_tooltip() -> void:
	var resource_list = []
	var count = 0
	
	for key in resources.keys():
		var value = resources[key]
		var max_value = get_resource_max(key)
		
		# Include max value if available
		if max_value > 0:
			resource_list.append("%s: %d/%d" % [key, value, max_value])
		else:
			resource_list.append("%s: %d" % [key, value])
		
		count += 1
		if count >= 10:
			break
	
	# Format the tooltip text
	tooltip_text = "\n".join(resource_list) if not resource_list.is_empty() else ""

# Check if a resource is at capacity
func is_at_capacity(resource_name: String) -> bool:
	var current_value = resources.get(resource_name, 0)
	var max_value = get_resource_max(resource_name)
	
	if max_value > 0 and current_value >= max_value:
		return true
	return false

# Check if all resources in the provided dictionary are at capacity
func are_all_at_capacity(resources_to_check: Dictionary) -> bool:
	for key in resources_to_check.keys():
		if not is_at_capacity(key):
			return false
	return true


# Load and parse the resource caps file
func _load_resource_caps() -> void:
	var file = FileAccess.open("res://JSON/resource_caps.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.parse_string(content)
		if json is Dictionary:
			resource_caps_data = json
		else:
			print_debug("Failed to parse resource_caps.json")
	else:
		print_debug("Failed to load resource_caps.json")
