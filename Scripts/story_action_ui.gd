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
@export var rewards_requirements_v_box_container: VBoxContainer = null


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
		_update_rewards_and_requirements()
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

# Update the rewards and requirements list in a single container
func _update_rewards_and_requirements() -> void:
	# Clear existing labels
	for child in rewards_requirements_v_box_container.get_children():
		child.queue_free()
	
	var requirements = story_action.get_requirements()
	var rewards = story_action.get_rewards()

	var has_content = false

	# Create red labels for requirements
	for key in requirements.keys():
		var requirement_label = Label.new()
		requirement_label.text = "%s: %d" % [key, requirements[key]]
		requirement_label.modulate = Color(1, 0, 0)  # Red color for requirements
		rewards_requirements_v_box_container.add_child(requirement_label)
		has_content = true
	
	# Create green labels for rewards
	for key in rewards.keys():
		var reward_label = Label.new()
		reward_label.text = "%s: %d" % [key, rewards[key]]
		reward_label.modulate = Color(0, 1, 0)  # Green color for rewards
		rewards_requirements_v_box_container.add_child(reward_label)
		has_content = true
	
	# Hide container if empty
	rewards_requirements_v_box_container.visible = has_content
