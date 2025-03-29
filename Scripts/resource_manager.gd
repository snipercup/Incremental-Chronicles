extends Label
@export var action_list: VBoxContainer = null
const DEFAULT_LABEL_TEXT: String = "Story points: 0/100"

# Use ResourceStore class
var visible_resources := ResourceStore.new(true)
var hidden_resources := ResourceStore.new(false)
var permanent_resources := ResourceStore.new(false,{},true)

var resource_caps_data: Dictionary = {}
@onready var story_point_label := self

func _ready():
	_load_resource_caps()
	visible_resources.caps = resource_caps_data
	visible_resources.updated = SignalBroker.resources_updated
	hidden_resources.updated = SignalBroker.hidden_resources_updated
	visible_resources.updated.connect(_on_visible_resources_updated)
	SignalBroker.action_rewarded.connect(_on_action_rewarded)
	SignalBroker.area_pressed.connect(_on_area_pressed)

func _on_action_rewarded(myaction: StoryAction):
	for key in myaction.get_rewards().keys():
		visible_resources.add(key, myaction.get_rewards()[key])
	for key in myaction.get_hidden_rewards().keys():
		hidden_resources.add(key, myaction.get_hidden_rewards()[key])

func _on_visible_resources_updated(_store: ResourceStore) -> void:
	_update_display()

func _update_display() -> void:
	var story_points = visible_resources.get_value("Story points")
	text = "Story points: %d/100" % int(story_points)
	_update_tooltip()

func _update_tooltip() -> void:
	var list = []
	var count = 0
	for key in visible_resources.resources.keys():
		var value = visible_resources.get_value(key)
		var max_value = resource_caps_data.get(key, 0)
		if max_value > 0:
			list.append("%s: %d/%d" % [key, value, max_value])
		else:
			list.append("%s: %d" % [key, value])
		count += 1
		if count >= 10:
			break
	tooltip_text = "\n".join(list)

# Returns the value of the resource by name
func get_resource(resource_name: String) -> float:
	return visible_resources.get_value(resource_name)

func get_resource_max(resource_name: String) -> float:
	return resource_caps_data.get(resource_name, 0)

func apply_rewards(rewards: Dictionary) -> bool:
	var success := false
	for key in rewards.keys():
		if visible_resources.add(key, rewards[key]):
			success = true
	return success

func has_required_resources(requirements: Dictionary, use_hidden: bool = false) -> bool:
	return (hidden_resources if use_hidden else visible_resources).has_all(requirements)

func consume_resources(requirements: Dictionary, use_hidden: bool = false) -> bool:
	return (hidden_resources if use_hidden else visible_resources).consume(requirements)

func is_at_capacity(resource_name: String) -> bool:
	return visible_resources.is_at_capacity(resource_name)

# Returns true if all resources in requirements are at capacity
# If a resource has no capacity limit, this function will always return false
func are_all_at_capacity(myresources: Dictionary) -> bool:
	return visible_resources.are_all_at_capacity(myresources)

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
	if not has_required_resources(requirements):
		print_debug("Tried to unlock an area, but not enough resources")
		return
	if consume_resources(requirements):
		myarea.unlock()
