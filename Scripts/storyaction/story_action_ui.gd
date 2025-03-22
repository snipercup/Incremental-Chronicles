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

@export var rewards_requirements: VBoxContainer = null
@export var action_container: HBoxContainer = null

var story_action: StoryAction

# Signal to emit when the action button is pressed
signal action_pressed(control: Control)


# Update the UI for this action
func set_story_action(value: StoryAction) -> void:
	story_action = value
	if story_action:
		rewards_requirements.set_story_action(story_action)
		
		# Instantiate the action scene if available
		var action_scene: PackedScene = story_action.ui_scene
		if action_scene:
			var action_instance = action_scene.instantiate()
			action_instance.set_story_action(story_action)
			# Connect to the action_pressed signal
			action_instance.action_pressed.connect(_on_action_instance_pressed)
			# Add to the action_container
			action_container.add_child(action_instance)


# Handle action_pressed from the instantiated action scene
func _on_action_instance_pressed(control: Control) -> void:
	print_debug("Action instance pressed:", control)
	action_pressed.emit(self)
	# Free the control after emitting the signal
	queue_free()
