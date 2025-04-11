extends VBoxContainer

# This script is used by the AreaList Ui control
# It will update its UI when it receives a list of StoryAreas

# Displays each action for an area
@export var action_list: VBoxContainer = null
@export var story_area_ui_scene: PackedScene = null
@export var resource_manager: Label = null
@export var special_areas_panel_container: PanelContainer = null

const REINCARNATION_AREA = preload("res://Special_areas/reincarnation_area.json")

var area_list: Array[StoryArea] # The data for each area

func _ready() -> void:
	# Connect to reincarnation_started signal
	SignalBroker.reincarnation_started.connect(_on_reincarnation_started)
	SignalBroker.reincarnation_finished.connect(_on_reincarnation_finished)

# Setter for area_list
func set_area_list(value: Array[StoryArea]) -> void:
	area_list = value
	_refresh_area_list()

# Refreshes the UI based on the current area list
func _refresh_area_list() -> void:
	print_debug("Refreshing area list")
	# Remove existing children
	for child in get_children():
		child.queue_free()

	# Create UI instances only for visible areas
	for area in area_list:
		_add_area_to_ui(area)

# Add a StoryArea to the UI
func _add_area_to_ui(area: StoryArea) -> void:
	if story_area_ui_scene:
		var area_ui = story_area_ui_scene.instantiate()
		add_child(area_ui)
		if area_ui.has_method("set_story_area"):
			area_ui.set_story_area(area)

# When reincarnation starts, reveal the special areas panel
func _on_reincarnation_started(_action: StoryAction) -> void:
	if special_areas_panel_container:
		special_areas_panel_container.visible = true
	action_list.set_area(area_list[0])

# When the reincarnation has finished, make the panel invisible
func _on_reincarnation_finished(_action: StoryAction) -> void:
	if special_areas_panel_container:
		special_areas_panel_container.visible = false

# Resets the area list by reloading the default reincarnation area from JSON
func reset_to_reincarnation_area() -> void:
	var file = FileAccess.open("res://Special_areas/reincarnation_area.json", FileAccess.READ)
	if file:
		var content := file.get_as_text()
		var parsed = JSON.parse_string(content)
		if parsed is Dictionary:
			var area := StoryArea.new(parsed)
			area_list = [area]
			_refresh_area_list()
			print_debug("Reincarnation area list successfully reset.")
		else:
			print_debug("Failed to parse reincarnation area JSON.")
		file.close()
	else:
		print_debug("Failed to open reincarnation area file.")
