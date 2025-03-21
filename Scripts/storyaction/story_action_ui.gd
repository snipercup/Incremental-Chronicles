extends PanelContainer

# This script is used with the StoryActionUI scene
# This script is used to update the ui for a StoryAction
# This script will signal when the user presses the action_button

#Example json:
#{
	# "requirements": {
		#"Story Point": 1,
		#"Persistence": 1
	#},
	#"rewards": {
		#"Story Point": 1
	#},
	#"story_text": "Pick wildflowers."
#}

@export var action_button: Button = null
@export var rewards_requirements: VBoxContainer = null

var story_action: StoryAction

# Signal to emit when the action button is pressed
signal action_pressed(control: Control)

func set_action_button_text(value: String) -> void:
	if action_button:
		action_button.text = value

# Update the UI for this action
func set_story_action(value: StoryAction) -> void:
	story_action = value
	if story_action:
		rewards_requirements.set_story_action(story_action)
		set_action_button_text(story_action.get_story_text())


# Handle action button press
func _ready():
	if action_button:
		action_button.pressed.connect(_on_action_button_pressed)

func _on_action_button_pressed() -> void:
	# Emit the signal, passing this control as a parameter
	action_pressed.emit(self)
	# Free the control after emitting the signal
	queue_free()
