extends PanelContainer

# This script is used with the StoryAreaUI scene
# This script is used to update the ui for a Storyarea
# This script will signal when the user presses the area_button

@export var story_point_requirement_label: Label = null
@export var stars_label: Label = null
@export var area_button: Button = null
var story_area: StoryArea

# Signal to emit when the area button is pressed
signal area_pressed(control: Control)

# Setters for controls and variables
func set_story_point_requirement_label(value: String) -> void:
	if story_point_requirement_label:
		story_point_requirement_label.text = value

func set_stars_label(value: String) -> void:
	if stars_label:
		stars_label.text = value


func set_area_button_text(value: String) -> void:
	if area_button:
		area_button.text = value

# Set story area and update controls
func set_story_area(value: StoryArea) -> void:
	story_area = value
	if story_area:
		# Update controls based on story area properties
		set_story_point_requirement_label("Requirement: %d" % story_area.get_story_point_requirement())
		set_stars_label("★".repeat(story_area.get_tier()))
		set_area_button_text(story_area.get_story_text())

# Handle area button press
func _ready():
	if area_button:
		area_button.pressed.connect(_on_area_button_pressed)

func _on_area_button_pressed() -> void:
	# Emit the signal, passing this control as a parameter
	area_pressed.emit(self)

func get_area_actions() -> Array[StoryAction]:
	return story_area.get_story_actions()
