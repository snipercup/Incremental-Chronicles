extends VBoxContainer


# This script is used with the StoryActionLoopUI scene
# This script will signal when the user presses the button

var story_action: LoopAction
var parent: Control
# New timer node to control cooldown timing
@export var button: Button = null
@export var progress_bar: ProgressBar = null


# Handle action button press
func _ready():
	button.pressed.connect(_on_action_button_pressed)
	SignalBroker.active_action_updated.connect(_on_active_action_updated)

func set_action_button_text(value: String) -> void:
	button.text = value

# Update the UI for this action
func set_story_action(value: StoryAction) -> void:
	story_action = value
	if story_action:
		set_action_button_text(story_action.get_story_text())

# Save the parent control, which will be story_action_ui.tscn
func set_parent(newparent: Control) -> void:
	parent = newparent

# Start the cooldown process and fill progress bar
func _on_action_button_pressed() -> void:
	SignalBroker.action_activated.emit(story_action)
	if story_action is LoopAction and not is_at_capacity():
		story_action.start_loop()
	else:
		progress_bar.value = 0

# Apply the action's rewards to the player's resources
func apply_rewards(rewards: Dictionary) -> bool:
	return parent.apply_rewards(rewards)

func get_helper() -> Node:
	return get_tree().get_first_node_in_group("helper")

func get_resource_manager() -> Label:
	return get_helper().get_resource_manager()

# Returns true of all rewards of this action are at capacity
# If a resource has no capacity limit, this function will always return false
func is_at_capacity() -> bool:
	if story_action.rewards.is_empty():
		return false
	return get_resource_manager().are_all_at_capacity(story_action.rewards)

# Interrupt the loop if the active action changes
func _on_active_action_updated(new_action: StoryAction) -> void:
	if story_action and new_action != story_action and story_action is LoopAction:
		story_action.cancel_loop()
		progress_bar.value = 0

# Frame-based cooldown handling
func _process(delta: float) -> void:
	if not story_action or not story_action is LoopAction:
		return

	# Update the progress bar using the loop action's own progress calculation
	progress_bar.value = story_action.get_progress_percent()

	# Run the loop logic — handles cooldown, loop limits, capacity, and reward signaling
	var still_looping := story_action.process_loop(
		delta,
		parent.get_active_action(),  # Ensure it only continues if it's the active action
		get_resource_manager()
	)

	# Stop showing progress if the loop is no longer running
	if not still_looping:
		progress_bar.value = 0
