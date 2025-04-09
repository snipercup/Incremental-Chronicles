extends Label
class_name ResourceLabel

@export var resource_key: String
@export var group: String = "visible"
@export var show_mode: String = "requirement" # "requirement", "reward", "value_only"
@export var required_amount: float = 0.0
@export var reward_amount: float = 0.0
@export var requirement_type: String = "consume" # or "appear"
@export var max_value_override: float = -1.0 # Optional for capacity display

@export var color_met := Color(0.8, 1.0, 0.8)
@export var color_unmet := Color(1.0, 0.6, 0.6)
@export var color_default := Color(1, 1, 1)

var current_value: float = -1.0
var parent: VBoxContainer # The resource requirement list ui

func _ready() -> void:
	SignalBroker.resources_updated.connect(_on_resources_updated)
	_update_text()

func _exit_tree() -> void:
	if SignalBroker.resources_updated.is_connected(_on_resources_updated):
		SignalBroker.resources_updated.disconnect(_on_resources_updated)

func _on_resources_updated(_data = null) -> void:
	_update_text()

func _update_text() -> void:
	var res: ResourceData = parent.get_resource_manager().get_resource(resource_key)

	var value: float = 0.0
	var max_value: float = 0.0

	if res == null:
		# Resource is missing from the manager
		match show_mode:
			"reward":
				# Show the reward amount even if the resource doesn't yet exist
				text = ResourceUtils.format_reward_label(resource_key, reward_amount, group)
				modulate = color_default
				return
			"requirement", "value_only":
				# Assume value = 0 for missing requirements
				value = 0.0
				max_value = max_value_override if max_value_override > 0 else 0.0
	else:
		# Fetch real values from the resource
		match group:
			"visible": value = res.get_visible()
			"hidden": value = res.get_hidden()
			"permanent": value = res.get_permanent()
			_: value = 0.0

		max_value = parent.get_resource_manager().get_resource_max(group, resource_key)
		if max_value_override > 0:
			max_value = max_value_override

	match show_mode:
		"value_only":
			text = ResourceUtils.format_requirement_label(
				resource_key, value, value, max_value, group, "consume"
			)
			modulate = color_default

		"reward":
			text = ResourceUtils.format_reward_label(resource_key, reward_amount, group)
			modulate = color_default

		"requirement":
			text = ResourceUtils.format_requirement_label(
				resource_key, required_amount, value, max_value, group, requirement_type
			)
			modulate = color_met if value >= required_amount else color_unmet
