extends GutTest

# Commonly used tests:
	#assert_has(test_chunk.chunk_data, "id", "Chunk data does not contain 'id' key.")
	

	#var chunk_is_unloaded = func():
		#return test_chunk == null
	## Calls chunk_is_unloaded every second until it returns true and asserts on the returned value
	#assert_true(await wait_until(chunk_is_unloaded, 10, 1),"Chunk should be unloaded in 10 seconds")
	# Wait for `game_started` signal
	#assert_true(await wait_for_signal(SignalBroker.game_started, 5), "Game should have been started.")

# The main game node instance
var test_instance: Control
const INCREMENTAL_CHRONICLE = preload("res://Scenes/incremental_chronicle.tscn")

# Runs before all tests.
#func before_all():
	#await get_tree().process_frame

# Runs before each test.
func before_each():
	test_instance = INCREMENTAL_CHRONICLE.instantiate()
	add_child(test_instance)

# Runs after each test.
func after_each():
	if test_instance and is_instance_valid(test_instance):
		test_instance.queue_free()

# Runs after all tests.
func after_all():
	await get_tree().process_frame


# Presses the action button of the first visible action in the action list
func _press_action_button(action_list: Control, childnr: int) -> void:
	var story_action_uis: Array = action_list.get_children()
	if story_action_uis.is_empty():
		return

	var myaction_ui: Control = story_action_uis[childnr]
	myaction_ui.action_instance._on_action_button_pressed()

# Returns true if an action of the given type exists in the action list
func _has_action_type(action_list: Control, type_name: String) -> bool:
	for action_ui in action_list.get_children():
		if action_ui.story_action.get_type() == type_name:
			return true
	return false

# Test if the game initializes correctly.
func test_incremental_chronicles():
	# Get the control lists
	var action_list: Control = test_instance.action_list
	var area_list: Control = test_instance.area_list
	
	# Get each instance of the area buttons in the area list
	var area_action_uis: Array = area_list.get_children()
	var tunnel_area_ui_instance: Control = area_action_uis[0]
	var tunnel_area_story_instance: StoryArea = tunnel_area_ui_instance.story_area
	assert_eq(tunnel_area_story_instance.name, "Tunnel", "Expected tunnel to be the first area.")
	tunnel_area_ui_instance._on_area_button_pressed() # Press the first area, which should be tunnel
	
	# Get all actions from the action list, which should be tunnel actions
	var story_action_uis: Array = action_list.get_children()
	# Verify there are 10 actions (since 1 is hidden)
	assert_eq(story_action_uis.size(), 10, "There should be 10 actions visible.")
	
	#press the first 8 actions
	# Press the first 8 actions using helper
	for i in 8:
		_press_action_button(action_list,0)
		await get_tree().process_frame
	story_action_uis = action_list.get_children()
	assert_eq(story_action_uis.size(), 2, "There should be 2 actions remaining.")
	var story_points: float = test_instance.helper.resource_manager.get_resource("Story points")
	assert_eq(story_points, 30.0, "There should be 30 story points.")
	
	# Next, we press the loop button, which generates Resolve
	var my_loop_action: Control = action_list.get_first_action_of_type("loop")
	assert_true(not my_loop_action == null, "There should be a loop action.")
	my_loop_action.story_action.cooldown = 0.1 # For this test we only want to wait 0.1 seconds
	my_loop_action.action_instance._on_action_button_pressed()
	var has_resolve = func():
		return 1.0 <= test_instance.helper.resource_manager.resources.get_value("visible","Resolve")
	assert_true(await wait_until(has_resolve, 2, 1),"Should have 1 resolve in 2 seconds")
	# Instead of waiting for 10 loops, we set the resolve to 10
	test_instance.helper.resource_manager.resources.set_value("visible","Resolve", 10)
	var resolve: float = test_instance.helper.resource_manager.resources.get_value("visible","Resolve")
	assert_eq(resolve, 10.0, "expected 10 resolve")
	
	# We now have enough resolve to proceed with combat
	var my_combat_action: Control = action_list.get_first_action_of_type("combat")
	assert_true(not my_combat_action == null, "There should be a combat action.")
	
	# Press the combat action until it disappears or we hit a max number of presses
	var max_attempts := 100
	var attempt := 0
	while attempt < max_attempts and not action_list.get_first_action_of_type("combat") == null:
		my_combat_action = action_list.get_first_action_of_type("combat")
		my_combat_action.action_instance._on_action_button_pressed()
		await get_tree().process_frame
		attempt += 1

	# The rat has been defeated and there is no combat action left
	my_combat_action = action_list.get_first_action_of_type("combat")
	assert_true(my_combat_action == null, "There should be no combat action.")
	
	# Rat was defeated, examine the rat
	var my_free_action: Control = action_list.get_first_action_of_type("free")
	my_free_action.action_instance._on_action_button_pressed()
	await get_tree().process_frame
	
	# The tunnel area is completed, only the loop action remains that generates resolve
	story_action_uis = action_list.get_children()
	assert_eq(story_action_uis.size(), 1, "There should be 1 (loop) action remaining.")
	
	# Get each instance of the area buttons in the area list
	area_action_uis = area_list.get_children()
	var road_area_ui_instance: Control = area_action_uis[1]
	var road_area_story_instance: StoryArea = road_area_ui_instance.story_area
	assert_eq(road_area_story_instance.name, "Road", "Expected road to be the second area.")
	road_area_ui_instance._on_area_button_pressed() # Press the second area, which should be road
	
	# The road area is started
	await get_tree().process_frame
	story_action_uis = action_list.get_children()
	assert_eq(story_action_uis.size(), 6, "There should be 6 actions in road area.")
	
	#press the first 5 free actions
	for i in 5:
		my_free_action = action_list.get_first_action_of_type("free")
		my_free_action.action_instance._on_action_button_pressed()
		await get_tree().process_frame

	# The road area is started
	await get_tree().process_frame
	story_action_uis = action_list.get_children()
	assert_eq(story_action_uis.size(), 1, "There should be 1 action in road area.")
		
	
	# Next, we press the loop button, which generates Miles
	my_loop_action = action_list.get_first_action_of_type("loop")
	assert_true(not my_loop_action == null, "There should be a loop action.")
	my_loop_action.story_action.cooldown = 0.1 # For this test we only want to wait 0.1 seconds
	my_loop_action.action_instance._on_action_button_pressed()
	var has_miles = func():
		return 1.0 <= test_instance.helper.resource_manager.resources.get_value("hidden","Miles")
	assert_true(await wait_until(has_miles, 2, 1),"Should have 1 mile in 2 seconds")
	# Instead of waiting for 10 loops, we set the miles to 10
	test_instance.helper.resource_manager.resources.set_value("hidden","Miles", 10)
	
	# When miles is set to 10, a new free action reveals itself
	await get_tree().process_frame
	my_free_action = action_list.get_first_action_of_type("free")
	assert_true(not my_free_action == null, "There should be a free action.")
	my_free_action.action_instance._on_action_button_pressed()
	
	# When the free action is pressed, only one action remains
	await get_tree().process_frame
	story_action_uis = action_list.get_children()
	assert_eq(story_action_uis.size(), 1, "There should be 1 action in road area.")
	
	# Get each instance of the area buttons in the area list
	area_action_uis = area_list.get_children()
	assert_eq(area_action_uis.size(), 3, "There should be 3 areas.")
	var village_area_ui_instance: Control = area_action_uis[2]
	var village_area_story_instance: StoryArea = village_area_ui_instance.story_area
	assert_eq(village_area_story_instance.name, "Village", "Expected village to be the third area.")
	village_area_ui_instance._on_area_button_pressed() # Press the third area, which should be village
	
	# When the village has been entered, 10 actions should be present
	await get_tree().process_frame
	story_action_uis = action_list.get_children()
	assert_eq(story_action_uis.size(), 10, "There should be 10 actions in village area.")
	
	
	#press the first 14 free actions (there were 10, but more reveal themselves)
	for i in 14:
		my_free_action = action_list.get_first_action_of_type("free")
		my_free_action.action_instance._on_action_button_pressed()
		await get_tree().process_frame
		
	# When the village has been done, 0 actions should be present
	await get_tree().process_frame
	story_action_uis = action_list.get_children()
	assert_eq(story_action_uis.size(), 0, "There should be 0 actions in village area.")
	
	# We have collected 50 story points
	story_points = test_instance.helper.resource_manager.get_resource("Story points")
	assert_eq(story_points, 50.0, "There should be 50 story points.")

	# Get each instance of the area buttons in the area list
	area_action_uis = area_list.get_children()
	assert_eq(area_action_uis.size(), 4, "There should be 4 areas.")
	var grove_area_ui_instance: Control = area_action_uis[3]
	var grove_area_story_instance: StoryArea = grove_area_ui_instance.story_area
	assert_eq(grove_area_story_instance.name, "Hollow Grove", "Expected grove to be the fourth area.")
	grove_area_ui_instance._on_area_button_pressed() # Press the fourth area, which should be grove
	
	# We have spent 50 story points, 0 remain
	story_points = test_instance.helper.resource_manager.get_resource("Story points")
	assert_eq(story_points, 0.0, "There should be 0 story points.")

	# Wait so we have an opportunity to see the end result
	await wait_seconds(10, "waiting 10 seconds")
