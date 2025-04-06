extends VBoxContainer

# This script is used to display a list of story actions
# Actions take place in the context of an area
# Each area has its own list of actions. When we are assigned a new area, update the list of actions

@export var header_label: Label = null
var area: StoryArea
const STORY_ACTION_UI = preload("res://Scenes/action/story_action_ui.tscn")

# Store the currently active action
var active_action: StoryAction = null

func _ready():
	# Connect to the action_activated signal
	SignalBroker.action_activated.connect(_on_action_activated)
	SignalBroker.action_removed.connect(_on_action_removed)
	SignalBroker.game_started.connect(_on_game_started)
	# Connect to reincarnation_started signal
	SignalBroker.reincarnation_started.connect(_on_reincarnation_started)
	
# Setter for area
func set_area(value: StoryArea) -> void:
	# Disconnect previous signal to avoid multiple connections
	if area and area.action_added.is_connected(_on_action_added):
		area.action_added.disconnect(_on_action_added)
	area = value

	# Set header label text based on description
	if header_label:
		var description = area.get_description() if area else ""
		header_label.text = description if description else "Actions:"

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
	
	# Create an instance for each StoryAction (only visible ones)
	for action in area.get_story_actions():
		# Only create UI for visible actions
		if action.get_state() == StoryAction.State.VISIBLE:
			var action_ui: Control = STORY_ACTION_UI.instantiate()
			# Set the story_action property if available
			if action_ui.has_method("set_story_action"):
				action_ui.set_story_action(action)
			# Add the instance as a child
			add_child(action_ui)

# Handle action state changes
func _on_action_state_changed(action: StoryAction) -> void:
	if not area.has_action(action):
		return # We do not need to refresh if it was an action outside of the current area
	# When the action state changes, refresh the action list
	_update_story_actions()

# Function to handle action_activated signal
func _on_action_activated(myaction: StoryAction) -> void:
	active_action = myaction # Set active action if it doesn't need removal
	SignalBroker.active_action_updated.emit(active_action)

# Function to handle action_removed signal
func _on_action_removed(_myaction: StoryAction) -> void:
	active_action = null # Clear active action if it needs removal

# Function to handle action_added signal
func _on_action_added(_myarea: StoryArea) -> void:
	_update_story_actions()

# Function to handle game_started signal
func _on_game_started() -> void:
	# Connect to the action_state_changed signal
	if not SignalBroker.action_state_changed.is_connected(_on_action_state_changed):
		SignalBroker.action_state_changed.connect(_on_action_state_changed)
	
func get_active_action() -> StoryAction:
	return active_action

# When reincarnation starts, clear active action
func _on_reincarnation_started(_action: StoryAction) -> void:
	active_action = null # Clear active action if it needs removal

# Returns the first child action_ui that matches the specified action type
func get_first_action_of_type(action_type: String) -> Control:
	for child in get_children():
		if child.has_method("get_story_action"):
			var action = child.get_story_action()
			if action and action.has_method("get_type") and action.get_type() == action_type:
				return child
	return null # No matching action found
