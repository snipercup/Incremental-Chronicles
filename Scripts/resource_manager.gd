extends Label
@export var action_list: VBoxContainer = null
const DEFAULT_LABEL_TEXT: String = "Story points: 0/100"

# Resources dictionary can look like this:
#"resources": {
  #"visible": { "Story points": 3.0 },
  #"hidden": { "reincarnation_ready": 1.0 },
  #"permanent": { "Ascension Tokens": 1 }
#}
# Resource caps may look like this:
#"resource_caps": {
  #"visible": { "Story points": 100.0 },
  #"hidden": { "reincarnation_ready": 10.0 },
  #"permanent": { "Ascension Tokens": 10.0 }
#}

# Use ResourceStore class
var resources := ResourceStore.new()

var resource_caps_data: Dictionary = {}
@onready var story_point_label := self

func _ready():
	_load_resource_caps()
	resources.caps = resource_caps_data

	# Connect one unified signal
	SignalBroker.resources_updated.connect(_on_resources_updated)
	SignalBroker.action_rewarded.connect(_on_action_rewarded)
	SignalBroker.area_pressed.connect(_on_area_pressed)

func _on_action_rewarded(myaction: StoryAction):
	var reward_data := myaction.get_rewards()
	for group in reward_data.keys():
		for key in reward_data[group].keys():
			resources.add(group, key, reward_data[group][key])

func _on_resources_updated(_store: ResourceStore) -> void:
	_update_display()

func _update_display() -> void:
	var story_points = resources.get_value("visible", "Story points")
	text = "Story points: %d/100" % int(story_points)
	_update_tooltip()

func _update_tooltip() -> void:
	var lines := []
	var total_count := 0

	# Add visible (temporary) resources
	total_count += _append_resource_group("visible", "Temporary Resources", lines, total_count, 10)
	# Add permanent resources
	if total_count < 20:
		total_count += _append_resource_group("permanent", "Permanent Resources", lines, total_count, 10)
	tooltip_text = "\n".join(lines)

# Appends a formatted section of resources to the tooltip lines
func _append_resource_group(group_name: String, section_title: String, lines: Array, count: int, max_items: int) -> int:
	if not resources.resources.has(group_name):
		return 0

	var added := 0
	if count > 0:
		lines.append("")  # Add spacing between sections
	lines.append(section_title)

	for key in resources.resources[group_name].keys():
		var value = resources.get_value(group_name, key)
		var max_value = resource_caps_data.get(group_name, {}).get(key, 0)
		if max_value > 0:
			lines.append("  %s: %d/%d" % [key, value, max_value])
		else:
			lines.append("  %s: %d" % [key, value])
		added += 1
		if added >= max_items:
			break

	return added


func get_resource(group: String, resource_name: String) -> float:
	return resources.get_value(group, resource_name)

func get_resource_max(group: String, resource_name: String) -> float:
	return resource_caps_data.get(group, {}).get(resource_name, 0)

# "rewards": { "regeneration": { "Focus": {"permanent": 1, "temporary": 0} } }
# "rewards": { "permanent": { "Perception": 1 } }
func apply_rewards(rewards: Dictionary) -> bool:
	var success := false
	for group in rewards.keys(): # For example: "visible" or "permanent"
		for key in rewards[group].keys(): # For example: "Focus"
			var count = rewards[group][key]
			if group == "regeneration":
				resources.add_generation(key, count)
				success = true
			else:
				if resources.add(group, key, count):
					success = true
	return success

func can_fulfill_requirements(requirements: Dictionary) -> bool:
	return resources.can_fulfill_requirements(requirements)

func consume(requirements: Dictionary) -> bool:
	return resources.consume(requirements)

func is_at_capacity(resource_name: String) -> bool:
	return resources.is_at_capacity("visible", resource_name)

func are_all_at_capacity(myresources: Dictionary) -> bool:
	return resources.are_all_at_capacity({ "visible": myresources })

# Loads the resource caps from the json file
func _load_resource_caps() -> void:
	var file = FileAccess.open("res://JSON/resource_caps.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.parse_string(content)
		if json is Dictionary:
			resource_caps_data = json
		else:
			print_debug("Failed to parse resource_caps.json")
	else:
		print_debug("Failed to load resource_caps.json")

# When an area has been pressed, try to unlock it if it is locked
func _on_area_pressed(myarea: StoryArea) -> void:
	if not myarea.get_state() == StoryArea.State.LOCKED:
		return
	var requirements: Dictionary = myarea.get_requirements()
	if not can_fulfill_requirements(requirements):
		print_debug("Tried to unlock an area, but not enough resources")
		return
	if consume(requirements):
		myarea.unlock()
