extends VBoxContainer

# This script is used to display a list of story actions
# Actions take place in the context of an area
# Each area has its own list of actions. When we are assigned a new area, update the list of actions

var area: StoryArea
const STORY_ACTION_UI = preload("res://Scenes/action/story_action_ui.tscn")
signal action_completed(myaction: Control)

# Store the currently active action
var active_action: StoryAction = null


# Setter for area
func set_area(value: StoryArea) -> void:
	# Disconnect previous signal to avoid multiple connections
	if area and area.action_added.is_connected(_on_action_added):
		area.action_added.disconnect(_on_action_added)
	area = value
	
	# Connect to the action_added signal
	if area and not area.action_added.is_connected(_on_action_added):
		area.action_added.connect(_on_action_added)
	_update_story_actions()


# Function to update story actions when area is set
func _update_story_actions() -> void:
	print_debug("refreshing action list")
	# Remove existing children
	for child in get_children():
		child.queue_free()

	if not area:
		return
	
	# Create an instance for each StoryAction
	for action in area.get_story_actions():
		var action_ui: Control = STORY_ACTION_UI.instantiate()
		# Set the story_action property if available
		if action_ui.has_method("set_story_action"):
			action_ui.set_story_action(action)
		
		# Connect to the action_pressed signal if it exists
		if action_ui.has_signal("action_pressed"):
			action_ui.action_pressed.connect(_on_action_pressed)
		
		# Add the instance as a child
		add_child(action_ui)


# Function to handle action_pressed signal
func _on_action_pressed(control: Control) -> void:
	if control.needs_remove:
		control.story_action.area.remove_story_action(control.story_action)
		active_action = null # Clear active action if it needs removal
	else:
		active_action = control.story_action # Set active action if it doesn't need removal
	get_tree().get_first_node_in_group("signalbroker").active_action_updated.emit(active_action)
	action_completed.emit(control)


# Function to handle action_added signal
func _on_action_added(_myarea: StoryArea) -> void:
	_update_story_actions()
	
func get_active_action() -> StoryAction:
	return active_action
