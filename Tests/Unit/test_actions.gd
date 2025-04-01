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
	var myaction_button_container: Control = myaction_ui.action_container
	var mybutton: Control = myaction_button_container.get_child(2)
	mybutton._on_action_button_pressed()

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
	_press_action_button(action_list,0)
	var has_resolve = func():
		return 1.0 == test_instance.helper.resource_manager.resources.get_value("visible","Resolve")
	# Calls chunk_is_unloaded every second until it returns true and asserts on the returned value
	assert_true(await wait_until(has_resolve, 3, 1),"Should have 1 resolve in 3 seconds")
	# Instead of waiting for 10 loops, we set the resolve to 10
	test_instance.helper.resource_manager.resources.set_value("visible","Resolve", 10)
	var resolve: float = test_instance.helper.resource_manager.resources.get_value("visible","Resolve")
	assert_eq(resolve, 10, "10 resolve")
	
	# Press the combat action until it disappears or we hit a max number of presses
	var max_attempts := 100
	var attempt := 0
	while attempt < max_attempts and _has_action_type(action_list, "combat"):
		# Re-fetch story_action_uis each loop since children may change
		if action_list.get_child_count() > 1:
			_press_action_button(action_list, 1)
			await get_tree().process_frame
		attempt += 1

	story_action_uis = action_list.get_children()
	assert_eq(story_action_uis.size(), 1, "There should be 1 action remaining.")
	#var finished_combat = func():
		#_press_action_button(action_list,1) # Press the combat button
		#var resolve: float = test_instance.helper.resource_manager.resources.get_value("visible","Resolve")
		#return resolve == 1.0
