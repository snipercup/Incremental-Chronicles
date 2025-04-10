extends VBoxContainer

enum DisplayMode { REQUIREMENTS, REWARDS, BOTH }
@export var display_mode: DisplayMode = DisplayMode.BOTH

var story_action: StoryAction
signal right_clicked

func _ready():
	if story_action:
		_update_rewards_and_requirements()

func set_story_action(value: StoryAction) -> void:
	story_action = value

func _update_rewards_and_requirements() -> void:
	_clear_existing_labels()
	var has_content = false

	if display_mode == DisplayMode.REQUIREMENTS or display_mode == DisplayMode.BOTH:
		has_content = _display_requirements() or has_content

	if display_mode == DisplayMode.REWARDS or display_mode == DisplayMode.BOTH:
		has_content = _display_rewards() or has_content

	visible = has_content

func _clear_existing_labels() -> void:
	for child in get_children():
		child.queue_free()

func _display_requirements() -> bool:
	var has_content := false
	var resource_manager: Node = get_resource_manager()
	if not resource_manager:
		return false

	var story_requirements: Dictionary = story_action.get_requirements()
	for key in story_requirements.keys():
		if key.begins_with("h_"):
			continue # Don't display hidden requirements
		var req: ResourceRequirement = story_requirements[key]
		_create_requirement_label(key, req)
		has_content = true

	return has_content

func _display_rewards() -> bool:
	var has_content := false
	var rewards: Dictionary = story_action.get_rewards()

	for key in rewards.keys():
		if key.begins_with("h_"):
			continue # Don't display hidden rewards
		var reward: ResourceReward = rewards[key]
		_create_reward_label(key, reward)
		has_content = true

	return has_content

func _create_reward_label(key: String, reward: ResourceReward) -> void:
	var label := RewardLabel.new()
	label.resource_key = key
	label.reward = reward
	label.parent = self
	add_child(label)

func _create_requirement_label(key: String, req: ResourceRequirement) -> void:
	var label := RequirementLabel.new()
	label.resource_key = key
	label.requirement = req
	label.parent = self
	add_child(label)

func get_resource_manager() -> Node:
	return get_tree().get_first_node_in_group("helper").resource_manager

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click()

func _handle_right_click() -> void:
	if not story_action.get_requirements().is_empty():
		print_debug("Right-click detected")
		right_clicked.emit()
		get_tree().get_first_node_in_group("helper").on_rewards_requirments_right_clicked(self)
