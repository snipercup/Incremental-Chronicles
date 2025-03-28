extends Node

var loaded_areas: Dictionary = {}
@export var area_list: VBoxContainer = null
@export var requirements_pin_list: VBoxContainer = null
@export var resource_manager: Label = null
@export var action_list: VBoxContainer = null


func initialize():
	loaded_areas = load_json_files_from_path("res://Area_data/")
	create_story_areas()

# Function to load all JSON resource files from a directory into a dictionary
# Step 1: Get sorted list of JSON file names
func get_sorted_json_filenames(path: String) -> Array:
	var filenames: Array = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				filenames.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		filenames.sort()  # Sort alphabetically
	else:
		print_debug("Failed to open directory: %s" % path)
	return filenames

# Step 2: Build data_dict from sorted file names
func load_json_files_from_path(path: String) -> Dictionary:
	var data_dict: Dictionary = {}
	var filenames = get_sorted_json_filenames(path)

	for file_name in filenames:
		var file_path = path + "/" + file_name
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var content = JSON.parse_string(file.get_as_text())
			if content != null:
				var base_name = file_name.get_basename()
				data_dict[base_name] = content
			else:
				print_debug("Failed to parse JSON file: %s" % file_path)
			file.close()
	return data_dict

# Function to create StoryArea instances from loaded areas and set area_list
func create_story_areas() -> void:
	var areas: Array[StoryArea] = []
	
	# Loop through loaded_areas and create a new StoryArea for each entry
	for key in loaded_areas.keys():
		var area_data = loaded_areas[key]
		if area_data is Dictionary:
			var new_area = StoryArea.new(area_data)
			areas.append(new_area)
	
	# Assign the created areas to area_list
	if area_list:
		area_list.set_area_list(areas)


# The user right-clicked on the rewards and requirements node on an action
# We add the action to the pin list
func on_rewards_requirments_right_clicked(rewardsrequirmentsnode: VBoxContainer):
	requirements_pin_list.add_action(rewardsrequirmentsnode.story_action)

# Get the active action from the action list. May be null
func get_active_action() -> StoryAction:
	return action_list.get_active_action()
	
func get_resource_manager() -> Label:
	return resource_manager
