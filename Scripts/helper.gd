extends Node

var loaded_areas: Dictionary = {}
@export var area_list: VBoxContainer = null

func initialize():
	loaded_areas = load_json_files_from_path("res://Resources/")
	create_story_areas()

# Function to load all JSON files from a directory into a dictionary
func load_json_files_from_path(path: String) -> Dictionary:
	var data_dict: Dictionary = {}
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# Check if the file is a JSON file
			if file_name.ends_with(".json"):
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
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print_debug("Failed to open directory: %s" % path)
	
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
