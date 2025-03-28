extends Label

@export var action_list: VBoxContainer = null
const DEFAULT_LABEL_TEXT: String = "Story points: 0/100"
var resources: Dictionary = {} 
# Dictionary to store parsed resource caps data
var resource_caps_data: Dictionary = {}
# Dictionary to store current caps for each resource
var current_resource_caps: Dictionary = {}
# Dictionary to store hidden resources
var hidden_resources: Dictionary = {}


# Called when the node enters the scene tree.
func _ready():
	_load_resource_caps()
	SignalBroker.action_rewarded.connect(_on_action_rewarded)

# Called when an action is completed
func _on_action_rewarded(myaction: StoryAction):
	var rewards = myaction.get_rewards()
	for key in rewards.keys():
		add_resource(key, rewards[key])

	# Apply hidden rewards to hidden resources
	var hidden_rewards = myaction.get_hidden_rewards()
	for key in hidden_rewards.keys():
		add_hidden_resource(key, hidden_rewards[key])


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
	_prune_zero_resources()
	SignalBroker.resources_updated.emit(self)
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
# Example rewards:
#"rewards": {
	#"Story Point": 1
#},
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

# Checks whether all required resources are available
func has_required_resources(requirements: Dictionary, use_hidden_resources: bool = false) -> bool:
	var target_resources = hidden_resources if use_hidden_resources else resources

	for key in requirements.keys():
		var required = requirements[key]
		var current = target_resources.get(key, 0)
		if current < required:
			print_debug("Requirement not met for key '%s'" % key)
			return false

	return true

# Subtracts required resources if available, returns true if successful
func consume_resources(requirements: Dictionary, use_hidden_resources: bool = false) -> bool:
	if not has_required_resources(requirements, use_hidden_resources):
		return false

	var target_resources = hidden_resources if use_hidden_resources else resources

	for key in requirements.keys():
		var before = target_resources[key]
		target_resources[key] = max(before - requirements[key], 0)
		
	if use_hidden_resources:
		_update_hidden_resources()
	else:
		_update_resources()
	return true

# Add to a hidden resource (no capacity limit)
func add_hidden_resource(resource_name: String, amount: int) -> void:
	if amount <= 0:
		return
	
	hidden_resources[resource_name] = hidden_resources.get(resource_name, 0) + amount
	_update_hidden_resources()

# Remove from a hidden resource
func remove_hidden_resource(resource_name: String, amount: int) -> void:
	if hidden_resources.has(resource_name):
		hidden_resources[resource_name] = max(hidden_resources[resource_name] - amount, 0)
		_update_hidden_resources()

# Set a hidden resource to a specific value
func set_hidden_resource(resource_name: String, amount: int) -> void:
	hidden_resources[resource_name] = max(amount, 0)
	_update_hidden_resources()

# Get the value of a specific hidden resource
func get_hidden_resource(resource_name: String) -> int:
	return hidden_resources.get(resource_name, 0)

# Emit signal when hidden resources are updated
func _update_hidden_resources() -> void:
	SignalBroker.hidden_resources_updated.emit(self)

# Removes any resource entries with a value of 0.0
func _prune_zero_resources() -> void:
	var keys_to_remove: Array = []
	for key in resources.keys():
		if resources[key] == 0.0:
			keys_to_remove.append(key)

	for key in keys_to_remove:
		resources.erase(key)
