extends Label

@export var action_list: VBoxContainer = null
const DEFAULT_LABEL_TEXT: String = "Story points: 0/100"
var story_points: int = 0


# Called when the node enters the scene tree.
func _ready():
	# Connect the action_completed signal
	if action_list:
		action_list.action_completed.connect(_on_action_completed)

# Called when an action is completed
func _on_action_completed(control: Control):
	var story_action: StoryAction = control.story_action
	# Increment story_points based on the value from myaction
	story_points += story_action.story_points
	# Update label text
	text = "Story points: %d/100" % story_points
