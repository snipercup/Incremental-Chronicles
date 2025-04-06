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
#		"visible": { "Resolve": {"consume": 20.0} },
#		"hidden": { "path_obstructed": {"appear":{"min": 1.0}} },
#		"permanent": { "Intelligence": {"amount": 1.0} },
#		"sum": { "Strength": {"amount": 1.0} }
#	  }


# Provides an option to select viewing either rewards, requirements or both
enum DisplayMode { REQUIREMENTS, REWARDS, BOTH }
@export var display_mode: DisplayMode = DisplayMode.BOTH

var story_action: StoryAction
# Signal to emit when the user right-clicks the container
signal right_clicked

func _ready():
	SignalBroker.resources_updated.connect(_on_resources_updated)
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
			resource = ResourceData.new()

		var segments := []
		var requirement_met := true

		# === AMOUNT checks ===
		if req.required_amount_visible > 0.0:
			var current = resource.get_visible()
			var max_val = resource.capacity
			segments.append(ResourceUtils.format_requirement_label(
				key, req.required_amount_visible, current, max_val, "visible", "amount"
			))
			if current < req.required_amount_visible:
				requirement_met = false

		if req.required_amount_permanent > 0.0:
			var current = resource.get_permanent()
			segments.append(ResourceUtils.format_requirement_label(
				key, req.required_amount_permanent, current, -1, "permanent", "amount"
			))
			if current < req.required_amount_permanent:
				requirement_met = false

		# === CONSUME checks ===
		if req.consume_visible > 0.0:
			var current = resource.get_visible()
			var max_val = resource.capacity
			segments.append(ResourceUtils.format_requirement_label(
				key, req.consume_visible, current, max_val, "visible", "consume"
			))
			if current < req.consume_visible:
				requirement_met = false

		if req.consume_permanent > 0.0:
			var current = resource.get_permanent()
			segments.append(ResourceUtils.format_requirement_label(
				key, req.consume_permanent, current, -1, "permanent", "consume"
			))
			if current < req.consume_permanent:
				requirement_met = false

		# === APPEAR checks ===
		if req.appear_min_visible > -INF or req.appear_max_visible < INF:
			var current = resource.get_visible()
			segments.append(ResourceUtils.format_requirement_label(
				key, req.appear_min_visible, current, req.appear_max_visible, "visible", "appear"
			))
			if current < req.appear_min_visible or current > req.appear_max_visible:
				requirement_met = false

		if req.appear_min_permanent > -INF or req.appear_max_permanent < INF:
			var current = resource.get_permanent()
			segments.append(ResourceUtils.format_requirement_label(
				key, req.appear_min_permanent, current, req.appear_max_permanent, "permanent", "appear"
			))
			if current < req.appear_min_permanent or current > req.appear_max_permanent:
				requirement_met = false

		# === SUM checks ===
		if req.required_total_sum > 0.0:
			var current = resource.get_total()
			segments.append(ResourceUtils.format_requirement_label(
				key, req.required_total_sum, current, -1, "sum", "sum"
			))
			if current < req.required_total_sum:
				requirement_met = false

		# === Display label ===
		if not segments.is_empty():
			var label_color := Color(0.2, 0.6, 1) if requirement_met else Color(1, 0, 0)
			var prefix := "✔️ " if requirement_met else "❌ "
			_create_label(prefix + " | ".join(segments), label_color)
			has_content = true

	return has_content


# Display rewards and return true if any are shown, using ResourceUtils formatting
func _display_rewards() -> bool:
	var has_content := false
	var rewards: Dictionary = story_action.get_rewards()

	for key in rewards.keys():
		var reward: ResourceReward = rewards[key]

		if reward.visible > 0.0:
			var text := ResourceUtils.format_reward_label(key, reward.visible, "visible")
			_create_label(text, Color(0, 1, 0))
			has_content = true

		if reward.permanent > 0.0:
			var text := ResourceUtils.format_reward_label(key, reward.permanent, "permanent")
			_create_label(text, Color(0, 1, 0))
			has_content = true

		# Hidden rewards are excluded from display

		if reward.regeneration > 0.0:
			var text := ResourceUtils.format_reward_label(key, reward.regeneration, "regeneration")
			_create_label(text, Color(0, 1, 0))
			has_content = true

		if reward.capacity > 0.0:
			var text := ResourceUtils.format_reward_label(key, reward.capacity, "capacity")
			_create_label(text, Color(0, 1, 0))
			has_content = true

	return has_content


# Create and add label to the container
func _create_label(text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.modulate = color
	add_child(label)

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

# When visible resources is updated
func _on_resources_updated(_myresources: Label) -> void:
	_update_rewards_and_requirements()
	
