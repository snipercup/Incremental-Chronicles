extends VBoxContainer

# This script is used with the RewardsRequirements_ui scene
# This script is used to display rewards and requirements
# Rewards will be displayed as green labels, requirements as red
# You can specify if you want to see requirements, rewards or both

# If story_points_label is present, we can get story_points_label.get_resource()
# and story_points_label.get_resource_max() to get the relevant values
# The format of each item will be [needed] requirement (current/max)
# For example: [40] resolve (1/10)
# If story_points_label is null, we just use resource: #

# Example JSON from story_action.get_requirements() and story_action.get_rewards():
# {
#     "Story Point": 1,
#     "Persistence": 1
# }

# Provides an option to select viewing either rewards, requirements or both
enum DisplayMode { REQUIREMENTS, REWARDS, BOTH }
@export var display_mode: DisplayMode = DisplayMode.BOTH
@export var story_points_label: Label = null

var story_action: StoryAction
# Signal to emit when the user right-clicks the container
signal right_clicked

# Set story action and update UI
func set_story_action(value: StoryAction) -> void:
	story_action = value
	if story_action:
		_update_rewards_and_requirements()

# Update the rewards and requirements list based on display mode
func _update_rewards_and_requirements() -> void:
	# Clear existing labels
	for child in get_children():
		child.queue_free()
	
	var requirements = story_action.get_requirements()
	var rewards = story_action.get_rewards()

	var has_content = false

	# Display requirements if enabled
	if display_mode == DisplayMode.REQUIREMENTS or display_mode == DisplayMode.BOTH:
		for key in requirements.keys():
			var needed = requirements[key]
			var label_text = ""

			if story_points_label:
				var current = story_points_label.get_resource(key)
				var max_value = story_points_label.get_resource("Max %s" % key)

				if max_value != 0: 
					# Include max value only if it’s greater than 0
					label_text = "[%d] %s (%d/%d)" % [needed, key, current, max_value]
				else:
					# No max value — omit the (current/max) part
					label_text = "[%d] %s" % [needed, key]
			else:
				# If no story_points_label, fall back to basic format
				label_text = "%s: %d" % [key, needed]

			var requirement_label = Label.new()
			requirement_label.text = label_text
			requirement_label.modulate = Color(1, 0, 0)  # Red color for requirements
			add_child(requirement_label)
			has_content = true
	
	# Display rewards if enabled
	if display_mode == DisplayMode.REWARDS or display_mode == DisplayMode.BOTH:
		for key in rewards.keys():
			var reward_label = Label.new()
			var amount = rewards[key]
			reward_label.text = "%s: %d" % [key, amount]
			reward_label.modulate = Color(0, 1, 0)  # Green color for rewards
			add_child(reward_label)
			has_content = true
	
	# Hide container if empty
	visible = has_content

# Detect right-click events
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click()

# Handle right-click event (only emit if requirements exist)
func _handle_right_click() -> void:
	if not story_action.get_requirements().is_empty():
		print_debug("Right-click detected")
		right_clicked.emit()
		get_tree().get_first_node_in_group("helper").on_rewards_requirments_right_clicked(self)
