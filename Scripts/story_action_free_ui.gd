extends Button


# This script is used with the StoryActionFreeUI scene
# This script will signal when the user presses the button

var story_action: StoryAction
# Signal to emit when the action button is pressed
signal action_pressed(control: Control)

func set_action_button_text(value: String) -> void:
	text = value

# Update the UI for this action
func set_story_action(value: StoryAction) -> void:
	story_action = value
	if story_action:
		set_action_button_text(story_action.get_story_text())

# Handle action button press
func _ready():
	pressed.connect(_on_action_button_pressed)

func _on_action_button_pressed() -> void:
	# Emit the signal, passing this control as a parameter
	action_pressed.emit(self)
