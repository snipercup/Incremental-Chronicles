extends PanelContainer

# This script is used with the StoryActionUI scene
# This script is used to update the ui for a StoryAction
# This script will signal when the user presses the action_button

#Example json:
#	{
#	  "action_type": "free",
#	  "story_text": "Examine the defeated rat.",
#	  "requirements": { "hidden_rat_reward": { "appear": { "hidden": { "min": 1.0 } } } },
#	  "rewards": { "Story points": { "visible": 5.0 } }
#	}

@export var rewards_requirements: VBoxContainer = null
@export var action_container: HBoxContainer = null
@export var icon_label: Label = null

var story_action: StoryAction
var action_instance: Control = null

func _ready():
	# Connect to the action_removed signal
	SignalBroker.action_removed.connect(_on_action_instance_removed)

# Update the UI for this action
func set_story_action(value: StoryAction) -> void:
	story_action = value
	if story_action:
		rewards_requirements.set_story_action(story_action)
		# Set the emoji icon as text
		icon_label.text = story_action.get_icon()
		
		# Instantiate the action scene if available
		var action_scene: PackedScene = story_action.ui_scene
		if action_scene:
			action_instance = action_scene.instantiate()
			action_instance.set_parent(self)
			action_instance.set_story_action(story_action)
			# Add to the action_container
			action_container.add_child(action_instance)

# The resource manager will handle rewards
func get_resource_manager() -> Node:
	return get_helper().resource_manager

# The resource manager will handle rewards
func get_active_action() -> StoryAction:
	return get_helper().get_active_action()

# The story_action will be returned
func get_story_action() -> StoryAction:
	return story_action
	
# Return the helper
func get_helper() -> Node:
	return get_tree().get_first_node_in_group("helper")

# Attempt to subtract resources based on the provided requirements
func apply_requirements(requirements: Dictionary) -> bool:
	for key in requirements: # Example: "Resolve" or "Story points"
		var req: ResourceRequirement = requirements[key]
		if not get_resource_manager().has_resource(key):
			return false
		var resource: ResourceData = get_resource_manager().get_resource(key)
		if not req.can_fulfill(resource):
			return false
	# If we reached this point, we are able to fulfill the requirements
	# Consume the requirements if applicable
	for key in requirements: # Example: "Resolve" or "Story points"
		var req: ResourceRequirement = requirements[key]
		var resource: ResourceData = get_resource_manager().get_resource(key)
		req.consume_from(resource)
	return true

# Handle action_removed from the instantiated action scene
func _on_action_instance_removed(myaction: StoryAction) -> void:
	if not story_action == myaction:
		return
	# Free the control after emitting the signal
	queue_free()
