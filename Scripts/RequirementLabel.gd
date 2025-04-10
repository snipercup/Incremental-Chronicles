extends Label
class_name RequirementLabel

@export var resource_key: String # The name of the resource being checked
var requirement: ResourceRequirement # The requirement logic for this resource

@export var max_value_override: float = -1.0 # Optional max value override for display

@export var color_met := Color(0.8, 1.0, 0.8) # Color when requirement is fulfilled
@export var color_unmet := Color(1.0, 0.6, 0.6) # Color when requirement is not fulfilled

var parent: VBoxContainer # Parent container to access resource manager

# Called when the node enters the scene
func _ready() -> void:
	SignalBroker.resources_updated.connect(_on_resources_updated)
	_update_text()

# Cleanup when node is removed from the tree
func _exit_tree() -> void:
	if SignalBroker.resources_updated.is_connected(_on_resources_updated):
		SignalBroker.resources_updated.disconnect(_on_resources_updated)

# React to global resource updates
func _on_resources_updated(_data = null) -> void:
	_update_text()

# Updates the label text and color based on current resource state
func _update_text() -> void:
	if resource_key.begins_with("h_") or requirement == null:
		text = ""
		return

	var res: ResourceData = parent.get_resource_manager().get_resource(resource_key)
	var temp := res.get_temporary() if res else 0.0
	var perm := res.get_permanent() if res else 0.0
	var total := temp + perm
	var max_val := res.capacity if res and max_value_override <= 0 else max_value_override

	# Determine the main condition for this requirement
	var displayed_amount := 0.0
	var requirement_type := "consume"

	if requirement.required_amount > 0.0:
		displayed_amount = requirement.required_amount
		requirement_type = "amount"
	elif requirement.consume_temporary > 0.0:
		displayed_amount = requirement.consume_temporary
		requirement_type = "consume"
	elif requirement.consume_permanent > 0.0:
		displayed_amount = requirement.consume_permanent
		requirement_type = "consume"

	text = format_requirement_label(resource_key, displayed_amount, total, max_val)
	# If the resource doesn't exist, the requirement can't be fulfilled
	modulate = color_met if res and requirement.can_fulfill(res) else color_unmet


static func format_requirement_label(
	resource_name: String,
	needed: float,
	current: float = -1,
	max_value: float = -1
) -> String:
	if resource_name.begins_with("h_"):
		return ""

	if max_value > 0:
		return "⏳ [%d] %s (%d/%d)" % [int(needed), resource_name, int(current), int(max_value)]
	elif current >= 0:
		return "⏳ [%d] %s (%d)" % [int(needed), resource_name, int(current)]
	else:
		return "⏳ [%d] %s" % [int(needed), resource_name]
