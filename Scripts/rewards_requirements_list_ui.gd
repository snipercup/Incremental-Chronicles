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

# Example JSON from story_action.get_requirements():
#	  "requirements": {
#		"Resolve": { "consume": { "visible": 1.0 } },
#		"Strength": { "sum": { "amount": 1.0 } },
#		"Soul Vessel": { "consume": { "visible": 1.0 } },
#		"reincarnation_ready": { "appear": { "hidden": { "min": 1.0 } } }
#	  },

# Provides an option to select viewing either rewards, requirements or both
enum DisplayMode { REQUIREMENTS, REWARDS, BOTH }
@export var display_mode: DisplayMode = DisplayMode.BOTH

var story_action: StoryAction
# Signal to emit when the user right-clicks the container
signal right_clicked

func _ready():
	if story_action:
		_update_rewards_and_requirements()



# Set story action and update UI
func set_story_action(value: StoryAction) -> void:
	story_action = value

# Update the rewards and requirements list based on display mode
func _update_rewards_and_requirements() -> void:
	_clear_existing_labels()
	var has_content = false
	
	if display_mode == DisplayMode.REQUIREMENTS or display_mode == DisplayMode.BOTH:
		has_content = _display_requirements() or has_content
	
	if display_mode == DisplayMode.REWARDS or display_mode == DisplayMode.BOTH:
		has_content = _display_rewards() or has_content
	
	visible = has_content

# Clear existing labels
func _clear_existing_labels() -> void:
	for child in get_children():
		child.queue_free()


# Display requirements and return true if any are shown
# Now handles "consume", "appear", and "amount" types
# Also adds support for the "sum" requirement group
# Display requirements using ResourceRequirement class and format via ResourceUtils
func _display_requirements() -> bool:
	var has_content := false
	var resource_manager: Node = get_resource_manager()
	if not resource_manager:
		return false

	for key in story_action.get_requirements().keys():
		var req: ResourceRequirement = story_action.get_requirements()[key]
		var resource: ResourceData = resource_manager.get_resource(key)
		if resource == null:
			resource = ResourceData.new("")  # fallback

		var requirement_met := true

		if req.required_amount_visible > 0.0:
			var current := resource.get_visible()
			requirement_met = _display_requirement_segment(key, "visible", req.required_amount_visible, "amount", current) and requirement_met
			has_content = true

		if req.required_amount_permanent > 0.0:
			var current := resource.get_permanent()
			requirement_met = _display_requirement_segment(key, "permanent", req.required_amount_permanent, "amount", current) and requirement_met
			has_content = true

		if req.consume_visible > 0.0:
			var current := resource.get_visible()
			requirement_met = _display_requirement_segment(key, "visible", req.consume_visible, "consume", current) and requirement_met
			has_content = true

		if req.consume_permanent > 0.0:
			var current := resource.get_permanent()
			requirement_met = _display_requirement_segment(key, "permanent", req.consume_permanent, "consume", current) and requirement_met
			has_content = true

		if req.required_total_sum > 0.0:
			var current := resource.get_total()
			requirement_met = _display_requirement_segment(key, "sum", req.required_total_sum, "sum", current) and requirement_met
			has_content = true

	return has_content




# Display rewards and return true if any are shown, using ResourceUtils formatting
func _display_rewards() -> bool:
	var has_content := false
	var rewards: Dictionary = story_action.get_rewards()

	for key in rewards.keys():
		var reward: ResourceReward = rewards[key]

		if reward.visible > 0.0:
			_create_resource_label(key, "visible", "reward", reward.visible, "consume", Color(0, 1, 0))
			has_content = true

		if reward.permanent > 0.0:
			_create_resource_label(key, "permanent", "reward", reward.permanent, "consume", Color(0, 1, 0))
			has_content = true

		if reward.regeneration > 0.0:
			_create_resource_label(key, "regeneration", "reward", reward.regeneration, "consume", Color(0, 1, 0))
			has_content = true

		if reward.capacity > 0.0:
			_create_resource_label(key, "capacity", "reward", reward.capacity, "consume", Color(0, 1, 0))
			has_content = true

	return has_content


# Create and store a ResourceLabel instead of Label
func _create_resource_label(key: String, group: String, mode: String, amount: float, type: String = "consume", color: Color = Color.WHITE) -> void:
	var res_label := ResourceLabel.new()
	res_label.parent = self
	res_label.resource_key = key
	res_label.group = group
	res_label.show_mode = mode
	res_label.modulate = color

	match mode:
		"reward":
			res_label.reward_amount = amount
		"requirement":
			res_label.required_amount = amount
			res_label.requirement_type = type

	add_child(res_label)


# The resource manager will handle rewards
func get_resource_manager() -> Node:
	return get_tree().get_first_node_in_group("helper").resource_manager

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


func _display_requirement_segment(
	key: String,
	group: String,
	amount: float,
	type: String,
	current: float
) -> bool:
	var met := current >= amount
	var color: Color = Color(0.2, 0.6, 1) if met else Color(1, 0, 0)
	_create_resource_label(key, group, "requirement", amount, type, color)
	return met
