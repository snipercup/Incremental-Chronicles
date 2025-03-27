extends VBoxContainer


# This script is used with the StoryActionLoopUI scene
# This script will signal when the user presses the button

var story_action: LoopAction
var parent: Control
# New timer node to control cooldown timing
@export var button: Button = null
@export var progress_bar: ProgressBar = null
# Track cooldown progress
var elapsed_time: float = 0.0
var is_looping: bool = false
# Track how many times the loop has run
var current_loops: int = 0


# Handle action button press
func _ready():
	button.pressed.connect(_on_action_button_pressed)
	SignalBroker.active_action_updated.connect(_on_active_action_updated)

func set_action_button_text(value: String) -> void:
	button.text = value

# Update the UI for this action
func set_story_action(value: StoryAction) -> void:
	story_action = value
	current_loops = 0  # Reset loop count when a new action is assigned
	if story_action:
		set_action_button_text(story_action.get_story_text())


# Save the parent control, which will be story_action_ui.tscn
func set_parent(newparent: Control) -> void:
	parent = newparent

# Start the cooldown process and fill progress bar
func _on_action_button_pressed() -> void:
	# If already looping or at capacity, do nothing
	if is_looping or is_at_capacity():
		progress_bar.value = 0
		return
	
	elapsed_time = 0.0
	is_looping = true


# Apply the action's rewards to the player's resources
func apply_rewards(rewards: Dictionary) -> bool:
	return parent.apply_rewards(rewards)

func get_helper() -> Node:
	return get_tree().get_first_node_in_group("helper")

func get_resource_manager() -> Label:
	return get_helper().get_resource_manager()

func is_at_capacity() -> bool:
	if story_action.rewards.is_empty():
		return false
	return get_resource_manager().are_all_at_capacity(story_action.rewards)

# Interrupt the loop if the active action changes
func _on_active_action_updated(new_action: StoryAction) -> void:
	if new_action != story_action:
		is_looping = false
		elapsed_time = 0.0
		progress_bar.value = 0

# Frame-based cooldown handling
func _process(delta: float) -> void:
	if not is_looping:
		return
	
	var cooldown = story_action.get_cooldown()
	elapsed_time += delta
	
	# Update the progress bar based on elapsed time
	progress_bar.value = min((elapsed_time / cooldown) * 100, 100)
	
	# If cooldown finishes, trigger the next loop
	if elapsed_time >= cooldown:
		elapsed_time = 0.0

		# Stop the loop if the action is at capacity
		if is_at_capacity():
			is_looping = false
			return

		# Emit the signal for the next loop
		SignalBroker.action_activated.emit(story_action)
		SignalBroker.action_rewarded.emit(story_action)

		# Increment loop count and check against max
		current_loops += 1
		var max_loops = story_action.get_max_loops()
		if max_loops > -1 and current_loops >= max_loops:
			is_looping = false
			SignalBroker.action_removed.emit(story_action)
			return  # Stop further looping

		# Continue looping if still the active action
		if parent.get_active_action() != story_action:
			is_looping = false
		else:
			is_looping = true
