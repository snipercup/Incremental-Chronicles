extends Label

@export var action_list: VBoxContainer = null
const DEFAULT_LABEL_TEXT: String = "Story points: 0/100"
var resources: Dictionary = {} 

# Signal to emit when resources are updated
signal resources_updated(new_resources: Dictionary)

# Called when the node enters the scene tree.
func _ready():
	if action_list:
		action_list.action_completed.connect(_on_action_completed)

# Called when an action is completed
func _on_action_completed(control: Control):
	var story_action: StoryAction = control.story_action
	var rewards = story_action.get_rewards()
	for key in rewards.keys():
		add_resource(key, rewards[key])

# Add to a resource
func add_resource(resource_name: String, amount: int) -> void:
	resources[resource_name] = resources.get(resource_name, 0) + amount
	_update_resources()

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
