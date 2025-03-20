extends PanelContainer

# This script is used with the StoryActionUI scene
# This script is used to update the ui for a StoryAction
# This script will signal when the user presses the action_button

@export var story_point_requirement_label: Label = null
@export var stars_label: Label = null
@export var give_story_point_label: Label = null
@export var action_button: Button = null
var story_action: StoryAction

# Signal to emit when the action button is pressed
signal action_pressed(control: Control)

# Setters for controls and variables
func set_story_point_requirement_label(value: String) -> void:
	if story_point_requirement_label:
		story_point_requirement_label.text = value

func set_stars_label(value: String) -> void:
	if stars_label:
		stars_label.text = value

func set_give_story_point_label(value: String) -> void:
	if give_story_point_label:
		give_story_point_label.text = value

func set_action_button_text(value: String) -> void:
	if action_button:
		action_button.text = value

# Set story action and update controls
func set_story_action(value: StoryAction) -> void:
	story_action = value
	if story_action:
		# Update controls based on story action properties
		set_story_point_requirement_label("Requirement: %d" % story_action.get_story_point_requirement())
		set_give_story_point_label("Gives: %d" % story_action.get_story_points())
		set_stars_label("★".repeat(story_action.get_stars()))
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
