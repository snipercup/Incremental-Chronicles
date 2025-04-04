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
func _display_requirements() -> bool:
	var requirement_groups := ["visible", "permanent", "sum"]
	var resource_manager: Node = get_resource_manager()
	if not resource_manager:
		return false

	var has_content := false

	for group in requirement_groups:
		var group_requirements: Dictionary = story_action.get_requirements().get(group, {})
		for key in group_requirements.keys():
			var req_data: Dictionary = group_requirements[key]
			if typeof(req_data) != TYPE_DICTIONARY:
				continue

			var requirement_met := false
			var label_text := ""
			var current: float
			var max_value: float = 0.0

			# Special handling for "sum" group — adds across all groups
			if group == "sum":
				current = (
					resource_manager.get_resource("visible", key) +
					resource_manager.get_resource("hidden", key) +
					resource_manager.get_resource("permanent", key)
				)
			else:
				current = resource_manager.get_resource(group, key)
				max_value = resource_manager.get_resource_max(group, key)

			# Check "consume"
			if req_data.has("consume"):
				var needed: float = req_data["consume"]
				requirement_met = current >= needed
				label_text = _format_requirement_text(key, needed, current, max_value)

			# Check "amount"
			elif req_data.has("amount"):
				var needed: float = req_data["amount"]
				requirement_met = current >= needed
				label_text = _format_requirement_text(key, needed, current, max_value)

			# Check "appear"
			elif req_data.has("appear"):
				var appear_range: Dictionary = req_data["appear"]
				var min_val: float = appear_range.get("min", 0.0)
				var max_val: float = appear_range.get("max", INF)
				requirement_met = current >= min_val and current <= max_val

				if max_val < INF:
					label_text = "[%s–%s] %s (%d)" % [min_val, max_val, key, current]
				else:
					label_text = "[%s+] %s (%d)" % [min_val, key, current]

			else:
				continue  # Skip unrecognized rule

			# Display result
			var label_color := Color(0.2, 0.6, 1) if requirement_met else Color(1, 0, 0)
			var prefix := "✔️ " if requirement_met else "❌ "
			_create_label(prefix + label_text, label_color)
			has_content = true

	return has_content

# Display rewards and return true if any are shown
func _display_rewards() -> bool:
	var reward_groups := ["visible", "permanent"]
	var has_content := false

	for group in reward_groups:
		var rewards: Dictionary = story_action.get_rewards().get(group, {})
		for key in rewards.keys():
			var amount: float = rewards[key]
			var label_text := "%s: %d" % [key, amount]
			_create_label(label_text, Color(0, 1, 0))  # Green for rewards
			has_content = true
	return has_content

# Format requirement text based on availability
func _format_requirement_text(key: String, needed: float, current: float, max_value: float) -> String:
	if max_value > 0:
		return "[%d] %s (%d/%d)" % [needed, key, current, max_value]
	else:
		return "[%d] %s" % [needed, key]

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
func _on_resources_updated(_myresources: ResourceStore) -> void:
	_update_rewards_and_requirements()
	
