extends VBoxContainer


# This script is used with the StoryActionLoopUI scene
# This script will signal when the user presses the button

var story_action: LoopAction
var parent: Control
# New timer node to control cooldown timing
@export var cooldown_timer: Timer = null
@export var button: Button = null
@export var progress_bar: ProgressBar = null

# Signal to emit when the action button is pressed
signal action_pressed(control: Control)

func set_action_button_text(value: String) -> void:
	button.text = value

# Update the UI for this action
func set_story_action(value: StoryAction) -> void:
	story_action = value
	parent.needs_remove = false
	if story_action:
		set_action_button_text(story_action.get_story_text())
		var cooldown: float = story_action.get_cooldown()
		cooldown_timer.wait_time = cooldown
		cooldown_timer.timeout.connect(_on_cooldown_complete)

# Save the parent control, which will be story_action_ui.tscn
func set_parent(newparent: Control) -> void:
	parent = newparent

# Handle action button press
func _ready():
	button.pressed.connect(_on_action_button_pressed)

# Start the cooldown process and fill progress bar
func _on_action_button_pressed() -> void:
	if cooldown_timer and not cooldown_timer.is_stopped():
		return
	_start_cooldown()

# Apply the action's rewards to the player's resources
func apply_rewards(rewards: Dictionary) -> Dictionary:
	return parent.apply_rewards(rewards)

# Function to handle progress bar fill based on cooldown
func _start_cooldown() -> void:
	progress_bar.value = 0
	progress_bar.max_value = 100
	
	var duration = story_action.get_cooldown()
	
	# Create a tween to smoothly fill the progress bar
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100, duration).set_trans(Tween.TRANS_LINEAR)
	cooldown_timer.start()

# Called when cooldown completes
func _on_cooldown_complete() -> void:
	progress_bar.value = 0
	
	# Emit the signal when the loop repeats
	action_pressed.emit(self)
	
	# Check if the current action is still the active action
	if parent.get_active_action() == story_action:
		# Restart the cooldown and loop if active
		_start_cooldown()
