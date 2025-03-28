extends VBoxContainer

# This script is used by the AreaList Ui control
# It will update its UI when it receives a list of StoryAreas

# Displays each action for an area
@export var action_list: VBoxContainer = null
@export var story_area_ui_scene: PackedScene = null
@export var resource_manager: Label = null
const REINCARNATION_AREA = preload("res://Special_areas/reincarnation_area.json")

var area_list: Array[StoryArea] # The data for each area

func _ready() -> void:
	# Load the reincarnation area at startup
	var file = FileAccess.open("res://Special_areas/reincarnation_area.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var reincarnation_data = JSON.parse_string(content)
		if reincarnation_data is Dictionary:
			var area = StoryArea.new(reincarnation_data)
			area_list = [area]
			_refresh_area_list()
			#action_list.set_area(area)
		else:
			print_debug("Failed to parse reincarnation area JSON.")
		file.close()
	else:
		print_debug("Failed to open reincarnation area file.")


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
		if area_ui.has_method("set_story_area"):
			area_ui.set_story_area(area)
		if area_ui.has_signal("area_pressed"):
			area_ui.area_pressed.connect(_on_area_pressed)
		add_child(area_ui)

# Handle area pressed signal
func _on_area_pressed(control: Control) -> void:
	action_list.set_area(control.get_area())
