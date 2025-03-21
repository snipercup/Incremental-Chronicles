extends VBoxContainer

# This script is used by the AreaList Ui control
# It will update its UI when it receives a list of StoryAreas

# Displays each action for an area
@export var action_list: VBoxContainer = null
@export var story_area_ui_scene: PackedScene = null
@export var story_points_label: Label = null
@export var nobody_who_chat: NobodyWhoChat = null

var area_list: Array[StoryArea] # The data for each area
signal area_created(area: StoryArea) # Signal to emit when an area is created

func _ready():
	nobody_who_chat.area_generated.connect(_on_area_generated)
	
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
	action_list.set_area(control.get_area())

func get_random_area() ->StoryArea:
	return area_list.pick_random()

# Generate area and wait for the signal in _on_area_generated
func create_area() -> void:
	nobody_who_chat.generate_area()

# Function to create a new StoryArea and append it to the list
func finalize_area(area_name: String, area_description: String) -> StoryArea:
	var tier: int = min(story_points_label.story_points / 100,1)
	var story_point_requirement: int = 0
	var new_area = StoryArea.new()
	new_area.set_name(area_name)
	new_area.set_description(area_description)
	new_area.set_tier(tier)
	new_area.set_story_point_requirement(story_point_requirement)
	
	# Add to the area list and refresh the UI
	print_debug("Adding area: " + area_name)
	area_list.append(new_area)
	_refresh_area_list()
	
	# Emit signal that an area has been created
	area_created.emit(new_area)
	return new_area


func _on_area_generated(area: String):
	# Attempt to parse the area string into a dictionary
	var area_data: Dictionary = JSON.parse_string(area) if area else {}
	if area_data.is_empty():
		print("Failed to parse area data from string:", area)
		return
	
	# Extract name and description from the dictionary
	var myname: String = area_data.get("name", "missing name")
	var mydescription: String = area_data.get("description", "missing description")
	
	# Finalize the area creation
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
