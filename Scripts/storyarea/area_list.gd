extends VBoxContainer

# This script is used by the AreaList Ui control
# It will update its UI when it receives a list of StoryAreas

# Displays each action for an area
@export var action_list: VBoxContainer = null
@export var story_area_ui_scene: PackedScene = null
@export var story_points_label: Label = null

var area_list: Array[StoryArea] # The data for each area
signal area_created(area: StoryArea) # Signal to emit when an area is created

	
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

	# Create UI instances for each StoryArea
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
	var myarea: StoryArea = control.story_area
	if myarea.get_state() == StoryArea.State.LOCKED:
		var remaining_points: int = myarea.unlock_with_story_points(story_points_label.story_points)
		if remaining_points == -1:
			print("Tried to unlock area, but not enough points")
			return
		else:
			story_points_label.set_story_points(remaining_points)
			_refresh_area_list()
	action_list.set_area(control.get_area())

# Get a random unlocked area
func get_random_area() -> StoryArea:
	# Filter out only unlocked areas
	var unlocked_areas = area_list.filter(func(area): 
		return area.get_state() == StoryArea.State.UNLOCKED
	)

	# Return a random unlocked area if available
	if unlocked_areas.size() > 0:
		return unlocked_areas.pick_random()
	
	return null  # Return null if no unlocked areas are available


# Finalize the creation of an area and add it to the list
func finalize_area(myname: String, description: String) -> StoryArea:
	var new_area = _create_story_area(myname, description)
	print_debug("Adding new area: %s" % myname)
	area_list.append(new_area)
	_refresh_area_list()
	area_created.emit(new_area)
	return new_area

# Calculate the tier based on story points
func _calculate_tier() -> int:
	if story_points_label:
		return min(story_points_label.story_points / 100, 1)
	return 1

# Create a StoryArea instance
func _create_story_area(myname: String, description: String) -> StoryArea:
	var tier: int = _calculate_tier()
	var new_area = StoryArea.new()
	new_area.set_name(myname)
	new_area.set_description(description)
	new_area.set_tier(tier)
	
	# Increment story point requirement based on the number of existing areas
	var requirement = area_list.size() * 10#0
	new_area.set_story_point_requirement(requirement)
	return new_area

# When a new area has been generated, extract the name and description
func _on_area_generated(area: String):
	# Attempt to parse the area string into a dictionary
	var area_data: Dictionary = JSON.parse_string(area) if area else {}
	if area_data.is_empty():
		print("Failed to parse area data from string:", area)
		return
	
	# Extract name, description, and actions from the dictionary
	var myname: String = area_data.get("name", "missing name")
	var mydescription: String = area_data.get("description", "missing description")
	var actions: Array = area_data.get("actions", [])

	# Format actions into a readable list
	if actions.size() > 0:
		mydescription += "\n\nActions:\n"
		for action in actions:
			mydescription += "\t" + action + "\n"

	# Finalize area creation with name and description
	finalize_area(myname, mydescription)


# Create a starting tunnel area (moved to a separate function)
func create_tunnel() -> void:
	var tunnel_description = _load_tunnel_description()
	var new_area = finalize_area("Tunnel", tunnel_description)
	new_area.set_say("Generate the next action for the player to do. Keep it short, like 'pick leaf', 'touch grass'")
	action_list.set_area(new_area)

# Load tunnel description from external file or resource
func _load_tunnel_description() -> String:
	var file = FileAccess.open("res://Resources/tunnel_description.txt", FileAccess.READ)
	return file.get_as_text() if file else "Tunnel description not found."


# Function to check if a new area needs to be created
func needs_new_area() -> bool:
	# If any area is locked, no need to create a new area
	for area in area_list:
		if area.get_state() == StoryArea.State.LOCKED:
			return false
	# If no area is locked, a new area needs to be created
	return true
