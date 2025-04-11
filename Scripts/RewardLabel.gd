extends Label
class_name RewardLabel

@export var resource_key: String
var reward: ResourceReward
var parent: VBoxContainer

@export var color_default := Color(1, 1, 1)

func _ready() -> void:
	SignalBroker.resources_updated.connect(_on_resources_updated)
	_update_text()

func _exit_tree() -> void:
	if SignalBroker.resources_updated.is_connected(_on_resources_updated):
		SignalBroker.resources_updated.disconnect(_on_resources_updated)

func _on_resources_updated(_data = null) -> void:
	_update_text()

func _update_text() -> void:
	if resource_key.begins_with("h_") or reward == null:
		text = ""
		return

	var lines := []
	if reward.temporary != 0.0:
		lines.append("⏳ %s: %d" % [resource_key, int(reward.temporary)])

	if reward.permanent != 0.0:
		lines.append("♾️ %s: %d" % [resource_key, int(reward.permanent)])

	if reward.regeneration != 0.0:
		lines.append("⏫ %s: +%.2f/s" % [resource_key, reward.regeneration])

	if reward.temporary_capacity != 0.0:
		lines.append("📈 %s Temp Max: +%d" % [resource_key, int(reward.temporary_capacity)])

	if reward.permanent_capacity != 0.0:
		lines.append("🪙 %s Perm Max: +%d" % [resource_key, int(reward.permanent_capacity)])


	text = "\n".join(lines)
	modulate = color_default
