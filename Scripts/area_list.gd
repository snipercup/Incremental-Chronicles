extends VBoxContainer

# This script is used by the AreaList Ui control
# It will update its UI when it receives a list of StoryAreas

# Displays each action for an area
@export var action_list: VBoxContainer = null
@export var story_area_ui_scene: PackedScene = null
@export var story_points_label: Label = null
@export var nobody_who_chat: NobodyWhoChat = null


var area_list: Array[StoryArea] # The data for each area
# Signal to emit when an area is created
signal area_created(area: StoryArea)

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


# Create the starting area
func create_tunnel():
	#print_debug("creating tunnel")
	var mydescription: String = "You awaken on the cold, uneven stone floor of a dimly lit tunnel.  " +\
		   "The air is damp and heavy, carrying the faint scent of moss and earth. Jagged rock  " +\
		   "walls stretch upward, disappearing into darkness above. The tunnel is eerily quiet,  " +\
		   "save for the distant sound of wind echoing through unseen cracks in the stone. " +\
		   "Behind you, the tunnel’s depths fade into shadow — but no entrance is visible.  " +\
		   "No path back. Just smooth, unyielding rock where an entrance should be. How did  " +\
		   "you get here? Your mind offers no answers. Ahead, pale light spills in from a  " +\
		   "rough opening at the end of the tunnel. The mouth of the tunnel leads to the  " +\
		   "side of a mountain, overlooking a vast, open wilderness. A cold breeze cuts  " +\
		   "through the stale air as you step toward the exit. Below, the rolling expanse of  " +\
		   "plains stretches to the horizon — patches of tall grass sway gently, broken only by  " +\
		   "scattered clusters of trees and the occasional dark silhouette of distant ruins. " +\
		   "As you take a hesitant step into the light, the weight of the unknown presses on  " +\
		   "your chest. The tunnel behind you remains silent and still. Whatever lies ahead,  " +\
		   "it is the only way forward."
	
	var myarea: StoryArea = finalize_area("Tunnel", mydescription)
	myarea.set_say("generate the next action for the player to do as he finds himself in the open wilderness")
	# Finalize the area creation
	action_list.set_area(myarea)
