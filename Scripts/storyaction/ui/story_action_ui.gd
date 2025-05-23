extends PanelContainer

# This script is used with the StoryActionUI scene
# This script is used to update the ui for a StoryAction
# This script will signal when the user presses the action_button

#Example json:
#	{
#	  "action_type": "free",
#	  "story_text": "Examine the defeated rat.",
#	  "requirements": { "h_hidden_rat_reward": { "appear": { "min": 1.0 } } },
#	  "rewards": { "Story points": 5.0 }
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
	return get_resource_manager().apply_requirements(requirements)

# check if the requirements can be fulfilled
func can_fulfill_requirements(requirements: Dictionary) -> bool:
	return get_resource_manager().can_fulfill_requirements(requirements)

# Handle action_removed from the instantiated action scene
func _on_action_instance_removed(myaction: StoryAction) -> void:
	if not story_action == myaction:
		return
	# Free the control after emitting the signal
	queue_free()
