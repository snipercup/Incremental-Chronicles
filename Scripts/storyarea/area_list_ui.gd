extends VBoxContainer

# This script is used by the AreaList Ui control
# It will update its UI when it receives a list of StoryAreas

# Displays each action for an area
@export var action_list: VBoxContainer = null
@export var story_area_ui_scene: PackedScene = null
@export var resource_manager: Label = null

var area_list: Array[StoryArea] # The data for each area

func _ready() -> void:
	SignalBroker.area_removed.connect(_on_area_removed)
	SignalBroker.area_pressed.connect(_on_area_pressed)
	SignalBroker.area_unlocked.connect(_on_area_unlocked)
	SignalBroker.area_visibility_changed.connect(_on_area_visibility_changed)

	# Set the first area in the list if available
	if area_list.size() > 0:
		action_list.set_area(area_list[0])

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
		if area.get_visibility_state() == StoryArea.VisibilityState.VISIBLE:
			_add_area_to_ui(area)

# Add a StoryArea to the UI
func _add_area_to_ui(area: StoryArea) -> void:
	if story_area_ui_scene:
		var area_ui = story_area_ui_scene.instantiate()
		if area_ui.has_method("set_story_area"):
			area_ui.set_story_area(area)
		add_child(area_ui)

# Handle area pressed signal
func _on_area_pressed(myarea: StoryArea) -> void:
	if myarea.get_state() == StoryArea.State.LOCKED:
		return
	action_list.set_area(myarea)

# Handle area unlocked signal
func _on_area_unlocked(myarea: StoryArea) -> void:
	_refresh_area_list()
	action_list.set_area(myarea)

# Calculate the tier based on story points
func _calculate_tier() -> int:
	if resource_manager:
		return min(resource_manager.story_points / 100, 1)
	return 1

# Called when an area is removed from the game
func _on_area_removed(removed_area: StoryArea) -> void:
	if removed_area in area_list:
		area_list.erase(removed_area)
		_refresh_area_list()
		# Set the first area again if one remains
		if area_list.size() > 0:
			action_list.set_area(area_list[0])

# Called when an area is removed from the game
func _on_area_visibility_changed(visible_area: StoryArea) -> void:
	if visible_area in area_list:
		_refresh_area_list()
