extends VBoxContainer

# This script is used by the AreaList Ui control
# It will update its UI when it receives a list of StoryAreas

# Displays each action for an area
@export var action_list: VBoxContainer = null
@export var story_area_ui_scene: PackedScene = null
var area_list: Array[StoryArea] # The data for each area

# Setter for area_list
func set_area_list(value: Array[StoryArea]) -> void:
	area_list = value
	_refresh_area_list()

# Refreshes the UI based on the current area list
func _refresh_area_list() -> void:
	# Remove existing children
	for child in get_children():
		child.queue_free()

	# Create a new instance for each StoryArea
	for area in area_list:
		if story_area_ui_scene:
			var area_ui = story_area_ui_scene.instantiate()
			# Set the story_area property if it exists
			if area_ui.has_method("set_story_area"):
				area_ui.set_story_area(area)
			
			# Connect to the area_pressed signal
			if area_ui.has_signal("area_pressed"):
				area_ui.area_pressed.connect(_on_area_pressed)
			add_child(area_ui)

# Handle area pressed signal
func _on_area_pressed(control: Control) -> void:
	action_list.set_action_list(control.get_area_actions())
