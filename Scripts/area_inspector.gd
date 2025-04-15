# AreaUI.gd
extends Control

@export var area_v_box_container: VBoxContainer = null
@export var details_v_box_container: VBoxContainer = null
@export var area_item_list: ItemList = null
@export var requirement_item_list: ItemList = null
@export var reward_item_list: ItemList = null
@export var hidden_reward_item_list: ItemList = null
@export var hidden_requirement_item_list: ItemList = null

var loaded_areas: Dictionary = {}  # Loaded JSON data

func _ready():
	loaded_areas = load_json_files_from_path("res://Area_data/")
	create_story_areas()

func _on_area_selected(button):
	var story_area: StoryArea = button.get_meta("area")
	if story_area:
		_show_area_details(story_area)

func _show_area_details(area: StoryArea) -> void:
	# Clear all item lists
	requirement_item_list.clear()
	reward_item_list.clear()
	hidden_requirement_item_list.clear()
	hidden_reward_item_list.clear()

	var summary: Dictionary = area.get_resource_summary()

	for resource: String in summary.keys():
		var data: Dictionary = summary[resource]
		var is_hidden: bool = resource.begins_with("h_")

		# === REQUIREMENTS ===
		if data.get("appear_min_total", 0.0) > 0.0:
			var text := "🔍 %s: %.2f" % [resource, data["appear_min_total"]]
			if is_hidden:
				hidden_requirement_item_list.add_item(text)
			else:
				requirement_item_list.add_item(text)

		if data.get("temporary_consume", 0.0) > 0.0:
			var text := "🔥 %s: %.2f" % [resource, data["temporary_consume"]]
			if is_hidden:
				hidden_requirement_item_list.add_item(text)
			else:
				requirement_item_list.add_item(text)

		# === REWARDS ===
		if data.get("temporary_reward", 0.0) > 0.0:
			var text := "%s: %.2f" % [resource, data["temporary_reward"]]
			if is_hidden:
				hidden_reward_item_list.add_item(text)
			else:
				reward_item_list.add_item(text)



# Function to create StoryArea instances from loaded areas and set area_list
func create_story_areas() -> void:
	var areas: Array[StoryArea] = []

	# Create StoryArea instances
	for key in loaded_areas.keys():
		var area_data = loaded_areas[key]
		if area_data is Dictionary:
			var new_area = StoryArea.new(area_data)
			areas.append(new_area)

	# Populate ItemList instead of VBoxContainer
	if area_item_list:
		area_item_list.clear()  # Remove all existing items

		for area in areas:
			var index := area_item_list.add_item(area.get_name())
			# Store the area reference using metadata on the item
			area_item_list.set_item_metadata(index, area)

		# Connect item selected signal if not already connected
		if not area_item_list.item_selected.is_connected(_on_item_selected):
			area_item_list.item_selected.connect(_on_item_selected)

# Add this new method for handling item selection:
func _on_item_selected(index: int) -> void:
	var story_area: StoryArea = area_item_list.get_item_metadata(index)
	if story_area:
		_show_area_details(story_area)


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
