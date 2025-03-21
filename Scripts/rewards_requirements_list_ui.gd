extends VBoxContainer

# This script is used with the RewardsRequirements_ui scene
# This script is used to display rewards and requirements
# Rewards will be displayed as green labels, requirements as red
# You can specify if you want to see requirements, rewards or both

# Example JSON from story_action.get_requirements() and story_action.get_rewards():
# {
#     "Story Point": 1,
#     "Persistence": 1
# }

enum DisplayMode { REQUIREMENTS, REWARDS, BOTH }

@export var display_mode: DisplayMode = DisplayMode.BOTH

var story_action: StoryAction

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
			var requirement_label = Label.new()
			requirement_label.text = "%s: %d" % [key, requirements[key]]
			requirement_label.modulate = Color(1, 0, 0)  # Red color for requirements
			add_child(requirement_label)
			has_content = true
	
	# Display rewards if enabled
	if display_mode == DisplayMode.REWARDS or display_mode == DisplayMode.BOTH:
		for key in rewards.keys():
			var reward_label = Label.new()
			reward_label.text = "%s: %d" % [key, rewards[key]]
			reward_label.modulate = Color(0, 1, 0)  # Green color for rewards
			add_child(reward_label)
			has_content = true
	
	# Hide container if empty
	visible = has_content
