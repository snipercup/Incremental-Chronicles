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

# Press all actions of a specific type a given number of times
func _press_actions_of_type(action_list: Control, type_name: String, times: int) -> void:
	for i in times:
		var action_ui: Control = action_list.get_first_action_of_type(type_name)
		if action_ui:
			action_ui.action_instance._on_action_button_pressed()
		await get_tree().process_frame

# Presses all visible actions of a given type
func _press_all_actions_of_type(action_list: Control, type_name: String) -> void:
	var actions: Array = action_list.get_all_actions_of_type(type_name)
	for action_ui in actions:
		if action_ui:
			action_ui.action_instance._on_action_button_pressed()
			await get_tree().process_frame

# Wait until a resource reaches a given threshold
func _wait_for_resource(store: Label, permanent: bool, key: String, threshold: float, timeout := 2.0, interval := 1.0) -> void:
	var has_enough = func():
		return store.get_value(key,permanent) >= threshold
	assert_true(await wait_until(has_enough, timeout, interval), "Expected %s >= %.2f" % [key, threshold])

# Waits until a specified number of actions of the given type exist in the action list
func _wait_for_action_type_count(action_list: Control, type_name: String, count: int, timeout := 5.0, interval := 0.2, on_interval_callback: Callable = Callable()) -> void:
	var has_enough = func():
		if on_interval_callback.is_valid():
			print_debug("calling interval")
			on_interval_callback.call()
		var match_count := 0
		for action_ui in action_list.get_children():
			if action_ui.story_action.get_type() == type_name:
				match_count += 1
		return match_count == count

	assert_true(await wait_until(has_enough, timeout, interval), "Expected %d actions of type '%s'" % [count, type_name])

# Open an area and verify it
func _open_area(area_list: Control, index: int, expected_name: String) -> void:
	var area_ui: Control = area_list.get_children()[index]
	var story_area: StoryArea = area_ui.story_area
	assert_eq(story_area.name, expected_name, "Expected area name: %s" % expected_name)
	area_ui._on_area_button_pressed()
	await get_tree().process_frame


# Test if the game initializes correctly.
func test_incremental_chronicles():
	var action_list: Control = test_instance.action_list
	var area_list: Control = test_instance.area_list
	var special_area_list: Control = test_instance.special_area_list
	var resources: Label = test_instance.helper.resource_manager

	# -- TUNNEL --
	_open_area(area_list, 0, "Tunnel")
	assert_eq(action_list.get_children().size(), 9, "There should be 9 visible actions in Tunnel.")
	resources.apply_rewards({"Focus": 10})
	
	await _wait_for_action_type_count(action_list, "free", 0, 15, 0.2, _press_actions_of_type.bind(action_list, "free", 1))
	
	var num_children := func(expected: int) -> bool:
		return action_list.get_children().size() == expected
	assert_true(await wait_until(num_children.bind(2), 2, 0.5), "Expected 2 children to remain")
	assert_eq(test_instance.helper.resource_manager.get_value("Story points"), 30.0, "There should be 30 story points.")

	# Loop to generate Resolve
	var loop_action: Control = action_list.get_first_action_of_type("loop")
	assert_true(loop_action != null, "Expected a loop action.")
	loop_action.story_action.cooldown = 0.1
	loop_action.action_instance._on_action_button_pressed()
	_wait_for_resource(resources, false, "Resolve", 1.0)

	# Force Resolve to 10 to proceed
	resources.apply_rewards({"Resolve": 10})
	_wait_for_resource(resources, false, "Resolve", 10.0)
	assert_eq(resources.get_value("Resolve"), 10.0, "Expected 10 Resolve")

	# -- COMBAT --
	var combat_action: Control = action_list.get_first_action_of_type("combat")
	assert_true(combat_action != null, "Expected a combat action.")
	var max_attempts := 100
	while combat_action and max_attempts > 0:
		combat_action.action_instance._on_action_button_pressed()
		await get_tree().process_frame
		combat_action = action_list.get_first_action_of_type("combat")
		max_attempts -= 1
	assert_true(combat_action == null, "Combat action should now be gone.")

	# Examine the rat
	var post_combat_action: Control = action_list.get_first_action_of_type("free")
	post_combat_action.action_instance._on_action_button_pressed()
	await get_tree().process_frame
	assert_eq(action_list.get_children().size(), 1, "Only the loop action should remain.")

	# -- ROAD --
	_open_area(area_list, 1, "Road")
	# We have 0 story points after entering road
	assert_eq(test_instance.helper.resource_manager.get_value("Story points"), 0.0, "There should be 0 story points.")
	await get_tree().process_frame
	assert_eq(action_list.get_children().size(), 6, "There should be 6 actions in Road.")
	_press_actions_of_type(action_list, "free", 5)
	assert_true(await wait_until(num_children.bind(1), 2, 0.5), "Expected 1 child to remain")

	# Loop to generate Miles
	loop_action = action_list.get_first_action_of_type("loop")
	assert_true(loop_action != null, "Expected a loop action.")
	loop_action.story_action.cooldown = 0.01
	loop_action.action_instance._on_action_button_pressed()
	_wait_for_resource(resources, false, "h_miles", 10.0)

	await get_tree().process_frame
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2)
	var post_mile_action: Control = action_list.get_first_action_of_type("free")
	assert_true(post_mile_action != null, "Expected new free action.")
	post_mile_action.action_instance._on_action_button_pressed()
	await get_tree().process_frame
	# Since road is done now, we return to tunnel, which has 1 action
	assert_eq(action_list.get_children().size(), 1, "Only one action should remain in Tunnel.")

	# -- VILLAGE --
	_open_area(area_list, 1, "Village")
	await get_tree().process_frame
	assert_eq(action_list.get_children().size(), 12, "There should be 12 visible actions in Village.")
	
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	

	# Loop to generate turnips
	loop_action = action_list.get_first_action_of_type("loop")
	assert_true(loop_action != null, "Expected a loop action.")
	loop_action.story_action.cooldown = 0.1
	loop_action.action_instance._on_action_button_pressed()
	_wait_for_resource(resources, false, "Turnips", 10.0)
	
	# Wait for 2 free actions to be visible (one appears as we collect tulips)
	# Then wait for one action to remain while we press the free action
	await _wait_for_action_type_count(action_list, "loop", 1, 15, 0.2)
	await _wait_for_action_type_count(action_list, "free", 2, 15, 0.2)
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_actions_of_type.bind(action_list, "free", 1))
	
	# -- HOLLOW GROVE --
	_open_area(area_list, 2, "Hollow Grove")
	await get_tree().process_frame
	
	# We press all the grove actions
	assert_eq(action_list.get_children().size(), 5, "There should be 5 actions in grove.")
	resources.apply_rewards({"Focus": 10})
	_press_actions_of_type(action_list, "free", 10)
	await get_tree().process_frame # All actions pressed, grove disappears and we return to tunnel
	assert_true(await wait_until(num_children.bind(1), 2, 0.5), "Expected 1 child to remain")
	
	# Return to the village
	_open_area(area_list, 1, "Village")
	# Keep pressing free actions until 1 remains
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	# -- TEMPLE --
	# The grove is gone now, so index 3 is forgotten temple
	_open_area(area_list, 2, "Forgotten Temple")
	await get_tree().process_frame
	assert_eq(action_list.get_children().size(), 3, "There should be 3 actions in Temple.")
	_press_actions_of_type(action_list, "free", 3)
	assert_true(await wait_until(num_children.bind(1), 2, 0.5), "Expected 1 child to remain")


	# Return to the village
	_open_area(area_list, 1, "Village")
	# Keep pressing free actions until 1 remains
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	
	# Explore the village outskirts until 1 loop action remains
	loop_action = action_list.get_first_action_of_type("loop")
	assert_true(loop_action != null, "Expected a loop action.")
	loop_action.story_action.cooldown = 0.1
	loop_action.action_instance._on_action_button_pressed()
	await _wait_for_action_type_count(action_list, "loop", 1, 15, 0.2)
	
	_press_actions_of_type(action_list, "free", 1)
	# Keep pressing free actions until 3 remains
	await _wait_for_action_type_count(action_list, "free", 3, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	
	# collect herbs with lyra
	loop_action = action_list.get_first_action_of_type("loop")
	assert_true(loop_action != null, "Expected a loop action.")
	loop_action.story_action.cooldown = 0.1
	loop_action.action_instance._on_action_button_pressed()
	await _wait_for_action_type_count(action_list, "loop", 0, 15, 0.2)
	
	# Keep pressing free actions until 3 remains
	await _wait_for_action_type_count(action_list, "free", 2, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	
	 #-- TEMPLE --
	 #Index 3 is forgotten temple
	_open_area(area_list, 2, "Forgotten Temple")
	await get_tree().process_frame
	_press_actions_of_type(action_list, "free", 1)
	assert_true(await wait_until(num_children.bind(1), 2, 0.5), "Expected 1 child to remain")

	## We are now starting reincarnation
	#_press_actions_of_type(action_list, "reincarnation", 1)
	#await get_tree().process_frame
	#var is_visible := func(control: Control, expected: bool) -> bool:
		#return control.visible == expected
	#assert_true(await wait_until(is_visible.bind(area_list.areas_panel_container, false), 2, 0.5), "Expected area_list to be invisible")
	##assert_true(area_list.visible == false, "Expected area_list to be invisible")
	#assert_true(special_area_list.special_areas_panel_container.visible == true, "Expected special_area_list to be invisible")
	## We have entered the special reincarnation area, which holds 4 actions
	#assert_true(await wait_until(num_children.bind(5), 2, 0.5), "Expected 5 children to remain")
	
	await wait_seconds(1000, "Wait 10 seconds to see the result")
