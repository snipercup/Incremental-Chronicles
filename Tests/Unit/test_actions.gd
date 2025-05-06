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


# Used for filtering story actions based on specific criteria
class ActionQuery:
	# Filter by action type (e.g., "free", "loop", "combat")
	var type_name: String = ""
	
	# Partial or full story text match
	var story_text: String = ""
	
	# Requires this key in requirements
	var required_key: String = ""
	
	# Requires this key in rewards
	var reward_key: String = ""

	func _init(_type := "", _story_text := "", _required_key := "", _reward_key := ""):
		type_name = _type
		story_text = _story_text
		required_key = _required_key
		reward_key = _reward_key


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


# Presses actions that match the given ActionQuery a specified number of times
func _press_actions_of_type(action_list: Control, query: ActionQuery, times: int) -> void:
	for i in times:
		var matches := _get_actions_by_filters(action_list, query)
		if matches.is_empty():
			break
		var action_ui: Control = matches[0]
		# If the story_action has a 'cooldown' property, override it for testing
		if "cooldown" in action_ui.story_action:
			action_ui.story_action.cooldown = 0.1
		action_ui.action_instance._on_action_button_pressed()
		await get_tree().process_frame


# Finds and runs a loop action until the specified resource reaches a threshold
func _run_loop_until_resource(query: ActionQuery, threshold: float, permanent: bool = false ) -> void:
	var action_list: Control = test_instance.action_list
	var resources: Label = test_instance.helper.resource_manager
	var resource_name: String = query.reward_key
	
	resources.apply_rewards({"Focus": 10})
	var actions := _get_actions_by_filters(action_list, query)
	assert_true(actions.size() > 0, "No matching loop action found.")
	if actions.size() > 0:
		var loop_action: Control = actions[0]
		loop_action.story_action.cooldown = 0.1
		loop_action.action_instance._on_action_button_pressed()
		await _wait_for_resource(resources, permanent, resource_name, threshold)


# Waits until at least one action matches the given ActionQuery.
# Optional timeout/interval can be passed to control how long to wait/check.
func _wait_for_action_query_match(action_list: Control, query: ActionQuery) -> void:
	var timeout := 10.0
	var interval := 0.2
	var match_exists := func():
		var matches := _get_actions_by_filters(action_list, query)
		return not matches.is_empty()

	assert_true(
		await wait_until(match_exists, timeout, interval),
		"Expected at least one action matching query: %s" % query.type_name
	)

# Presses all visible actions of a given type
func _press_all_actions_of_type(action_list: Control, type_name: String) -> void:
	var actions: Array = action_list.get_all_actions_of_type(type_name)
	for action_ui in actions:
		if action_ui:
			action_ui.action_instance._on_action_button_pressed()
			await get_tree().process_frame

# Returns a list of actions that match the given query filters
func _get_actions_by_filters(action_list: Control, query: ActionQuery) -> Array:
	return action_list.get_actions_by_filters(
		query.type_name,
		query.story_text,
		query.required_key,
		query.reward_key
	)

# Wait until a resource reaches a given threshold
func _wait_for_resource(store: Label, permanent: bool, key: String, threshold: float, timeout := 2.0, interval := 1.0) -> void:
	var has_enough = func():
		return store.get_value(key, permanent) >= threshold
	
	var message := "Waiting for resource [%s] %s %.2f" % [
		key, "(permanent)" if permanent else "(temporary)", threshold
	]

	assert_true(
		await wait_until(has_enough, timeout, interval, message),
		"Expected %s >= %.2f" % [key, threshold]
	)

# Waits until a specified number of actions of the given type exist in the action list
func _wait_for_action_type_count(action_list: Control, type_name: String, count: int, timeout := 5.0, interval := 0.2, on_interval_callback: Callable = Callable()) -> void:
	var first_story_text: String = ""
	var first_action: Control = action_list.get_first_action_of_type(type_name)
	if action_list.get_children().size() == 0:
		timeout = 0.1
	
	var has_enough = func():
		if on_interval_callback.is_valid():
			on_interval_callback.call()
		var match_count := 0
		for action_ui in action_list.get_children():
			if action_ui.story_action.get_type() == type_name:
				match_count += 1
		return match_count == count
	first_story_text = first_action.story_action.get_story_text() if first_action else ""
	var message := "Waiting for %d actions of type [%s]. First found: \"%s\"" % [count, type_name, first_story_text] if first_story_text != "" else "Waiting for %d actions of type [%s] — none found yet." % [count, type_name]

	assert_true(
		await wait_until(has_enough, timeout, interval, message),
		"Expected %d actions of type '%s'" % [count, type_name]
	)



# Opens an area by name, returns true if it's the stop_area_name
func _open_area(area_list: Control, area_name: String, stop_area_name := "") -> bool:
	var area_ui = area_list.get_area_by_name(area_name)
	if area_ui:
		area_ui._on_area_button_pressed()
		await get_tree().process_frame
		if stop_area_name != "" and area_name == stop_area_name:
			return true  # We reached the stop area
	return false

# Test if the game initializes correctly.
func test_incremental_chronicles():
	await _run_test_sequence(my_test_sequence, 3, "", 0.0) # Only run 3 reincarnation cycles
	await wait_seconds(1000, "Wait 1000 seconds to see the result")

# Runs a test sequence loop with control over steps and optional stop conditions
# Returns true if stopped early by stop_area match, false otherwise
func _run_test_sequence(fn: Callable, steps: int = 10, stop_area: String = "", delay: float = 0.0) -> bool:
	for i in steps:
		var aborted: bool = await fn.call(stop_area, delay)
		if aborted:
			print("Test aborted early at area: %s" % stop_area)
			return true
	return false


func my_test_sequence(stop_area_name := "", delay_seconds := 0.0) -> bool:
	var action_list: Control = test_instance.action_list
	var area_list: Control = test_instance.area_list
	var special_area_list: Control = test_instance.special_area_list
	var resources: Label = test_instance.helper.resource_manager
	var current_reincarnation: float = resources.get_value("Reincarnation", true) # starts at 0
	var query: ActionQuery
	var is_visible := func(control: Control, expected: bool) -> bool:
		return control.visible == expected

	# -- TUNNEL --
	await wait_seconds(0.01, "Entering Tunnel, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Tunnel", stop_area_name): return true
	assert_eq(resources.get_resource("Story points").temporary, 0.0, "At the start of the reincarnation, Story points should be 0.0.")
	
	match current_reincarnation:
		1.0, 2.0:
			assert_eq(action_list.get_children().size(), 10, "There should be 10 visible actions in Tunnel.")
			var focus_resource: ResourceData = resources.get_resource("Focus")
			assert_eq(focus_resource.regeneration, 0.1, "Focus should regenerate 0.1.")
			var resolve_resource: ResourceData = resources.get_resource("Resolve")
			assert_eq(resolve_resource.permanent_capacity, 15.0, "Resolve cap should be 15.")
		_:
			assert_eq(action_list.get_children().size(), 9, "There should be 9 visible actions in Tunnel.")
	resources.apply_rewards({"Focus": 10})
	
	var tunnel_query: ActionQuery = ActionQuery.new("free")
	await _wait_for_action_type_count(action_list, "free", 0, 15, 0.2, _press_actions_of_type.bind(action_list, tunnel_query, 1))

	# Loop to generate Resolve
	var myactionquery: ActionQuery = ActionQuery.new("loop","","","Resolve")
	await _run_loop_until_resource(myactionquery,1.0)
	
	# Force Resolve to 10 to proceed
	resources.apply_rewards({"Resolve": 10})
	await _wait_for_resource(resources, false, "Resolve", 10.0)

	# -- COMBAT --
	var combat_action: Control = action_list.get_first_action_of_type("combat")
	assert_true(combat_action != null, "Expected a combat action.")
	var max_attempts := 100
	while combat_action and max_attempts > 0:
		resources.apply_rewards({"Resolve": 10})
		combat_action.action_instance._on_action_button_pressed()
		await get_tree().process_frame
		combat_action = action_list.get_first_action_of_type("combat")
		max_attempts -= 1
	assert_true(combat_action == null, "Combat action should now be gone.")

	# Examine the rat. We keep pressing free actions until 1 loop action remains
	await _wait_for_action_type_count(action_list, "loop", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))


	# -- ROAD --
	await wait_seconds(0.01, "Entering Road, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Road", stop_area_name): return true
	
	match current_reincarnation:
		2.0: # An extra action shows up at reincarnation #2 that gives story points
			assert_eq(resources.get_resource("Story points").temporary, 5.0, "At the road, Story points should be 5.0.")
		_:
			assert_eq(resources.get_resource("Story points").temporary, 0.0, "At the road, Story points should be 0.0.")
	# We keep pressing free actions until 1 loop action (walk along road) remains
	await _wait_for_action_type_count(action_list, "loop", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	# Loop to generate Miles
	myactionquery.reward_key = "h_miles"
	await _wait_for_action_query_match(action_list,myactionquery)
	await _run_loop_until_resource(myactionquery,5.0)
	await _press_all_actions_of_type(action_list, "free") # We spot the village


	# -- VILLAGE --
	await wait_seconds(0.01, "Entering Village, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Village", stop_area_name): return true
	match current_reincarnation:
		2.0: 
			assert_eq(resources.get_resource("Story points").temporary, 5.0, "At the village, Story points should be 5.0.")
		_:
			assert_eq(resources.get_resource("Story points").temporary, 0.0, "At the village, Story points should be 0.0.")
	# Keep pressing free actions until 1 remains
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	myactionquery.reward_key = "Turnips" # Loop to generate 10 turnips
	await _run_loop_until_resource(myactionquery,10.0)
	myactionquery.reward_key = "Herbs" # collect herbs with lyra
	await _run_loop_until_resource(myactionquery,10.0)
	# Keep pressing free actions until 1 remains
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	
	
	# -- HOLLOW GROVE --
	await wait_seconds(0.01, "Entering Hollow Grove, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Hollow Grove", stop_area_name): return true
	
	# Keep pressing free actions. Once they are all gone
	resources.apply_rewards({"Focus": 10})
	await _wait_for_action_type_count(action_list, "free", 0, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	
	# -- VILLAGE --
	await wait_seconds(0.01, "Entering Village, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Village", stop_area_name): return true
	# Keep pressing free actions until 1 remains
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))


	# -- TEMPLE --
	await wait_seconds(0.01, "Entering Temple, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Forgotten Temple", stop_area_name): return true
	# Keep pressing free actions until 1 remains
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	

	# -- VILLAGE --
	await wait_seconds(0.01, "Entering Village, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Village", stop_area_name): return true
	# Keep pressing free actions until 1 remains
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	# Explore the village outskirts
	myactionquery.reward_key = "h_outskirts_explored"
	await _run_loop_until_resource(myactionquery,5.0)
	
	
	if current_reincarnation <= 0.0:
		# ✅ Runs only on the first reincarnation
		# Keep pressing free actions until 2 remains. We now have the soul vessel
		await _wait_for_action_type_count(action_list, "free", 2, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
		#-- TEMPLE --
		if await _open_area(area_list, "Forgotten Temple", stop_area_name): return true
		# Keep pressing free actions until 1 remains
		await _wait_for_action_type_count(action_list, "reincarnation", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
		query = ActionQuery.new("reincarnation") # Here we will reincarnate from the temple
		await _press_actions_of_type(action_list, query, 1)
		
		 #-- REINCARNATION --
		assert_true(await wait_until(is_visible.bind(area_list.areas_panel_container, false), 2, 0.5), "Expected area_list to be invisible")
		assert_true(special_area_list.special_areas_panel_container.visible == true, "Expected special_area_list to be visible")
		# We have entered the special reincarnation area, which holds actions
		await _wait_for_action_type_count(action_list, "reincarnation", 1, 15, 0.2) # 1 reincarnation action
		
		# Get the echoes of the past
		query = ActionQuery.new("free","","","Echoes of the Past")
		await _press_actions_of_type(action_list, query, 1)
		
		# We get one echo from the reward list, then force 2 more. This will save reincarnating again
		resources.apply_rewards({"Echoes of the Past": { "permanent": 4 }})
		query.reward_key = "Focus" # Get the focus regeneration buff
		await _press_actions_of_type(action_list, query, 1)
		query.reward_key = "Strength" # We also get strength
		await _press_actions_of_type(action_list, query, 1)
		resources.apply_rewards({"Strength": {"permanent": 2}}) # Sneak in 2 more strength
		query.reward_key = "Resolve" # Get the Resolve max capacity buff
		await _press_actions_of_type(action_list, query, 1)
		query.reward_key = "Wisdom" # Get the Wisdom buff
		await _press_actions_of_type(action_list, query, 1)
		query.reward_key = "Story points" # Get the "Story points" max capacity buff
		await _press_actions_of_type(action_list, query, 1)
		query = ActionQuery.new("reincarnation") # Reincarnate and start over
		await _press_actions_of_type(action_list, query, 1)
		return false # No interruptions, so return false
		
	# After 1 reincarnation, we have the strength to open the vessel vault
	# Keep pressing free actions until 1 remains. We now have the soul vessel
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	query = ActionQuery.new("free") # clear the mudslide
	await _press_actions_of_type(action_list, query, 1)
	
	#-- FLOODED CROSSING --
	await wait_seconds(0.01, "Entering Flooded Crossing, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Flooded Crossing", stop_area_name): return true
	
	if current_reincarnation <= 1.0:
		var story_point_resource: ResourceData = resources.get_resource("Story points")
		assert_eq(story_point_resource.temporary, 0.0, "Story points should be 0.0.")
	
	# We keep pressing free actions until 2 loop action remain
	await _wait_for_action_type_count(action_list, "loop", 2, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	await _wait_for_action_type_count(action_list, "loop", 2, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	
	myactionquery.reward_key = "Story points" # collect move the beams from the water
	await _run_loop_until_resource(myactionquery, 10.0)
	myactionquery.reward_key = "Iron Nails" # Scavenge wood and nails
	await _run_loop_until_resource(myactionquery, 5.0)
	# Keep pressing free actions until 3 free actions remain
	await _wait_for_action_type_count(action_list, "free", 3, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	await _wait_for_action_type_count(action_list, "free", 3, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	
	# -- HOLLOW GROVE --
	await wait_seconds(0.01, "Entering Hollow Grove, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Hollow Grove", stop_area_name): return true
	await get_tree().process_frame
	myactionquery.reward_key = "Knotroot Timber" # Scavenge Knotroot Timber
	await _run_loop_until_resource(myactionquery, 6.0)
	
	# -- VILLAGE --
	await wait_seconds(0.01, "Entering Village, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Village", stop_area_name): return true
	myactionquery.reward_key = "Stone Dowels" # Scavenge Stone Dowels
	await _run_loop_until_resource(myactionquery, 6.0)
	await _press_all_actions_of_type(action_list, "free") # Talk to smith
	myactionquery.reward_key = "Iron Braces" # get Iron Braces from smith
	await _run_loop_until_resource(myactionquery, 4.0)
	await _press_all_actions_of_type(action_list, "free") # Talk to smith
	
	#-- FLOODED CROSSING --
	await wait_seconds(0.01, "Entering Flooded Crossing, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Flooded Crossing", stop_area_name): return true
	
	# We keep pressing free actions until 1 loop action remains
	await _wait_for_action_type_count(action_list, "loop", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	await _wait_for_action_type_count(action_list, "loop", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	query = ActionQuery.new("loop") 
	await _press_actions_of_type(action_list, query, 1) # build the bridge
	await _wait_for_action_type_count(action_list, "loop", 0, 15, 0.2)
	await _press_all_actions_of_type(action_list, "free") # Talk to mirella
	
	#-- HILLSTEAD OUTPOST --
	await wait_seconds(0.01, "Entering Hillstead Outpost, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Hillstead Outpost", stop_area_name): return true
	await _wait_for_action_type_count(action_list, "free", 2, 15, 0.2)
	resources.apply_rewards({"Focus": 10})
	await _press_all_actions_of_type(action_list, "free") # do actions
	resources.apply_rewards({"Focus": 10})
	query = ActionQuery.new("free")
	await _press_actions_of_type(action_list,query,4) # Press patrol loop
	resources.apply_rewards({"Focus": 10})
	await _wait_for_action_type_count(action_list, "free", 2, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	resources.apply_rewards({"Focus": 10})
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	resources.apply_rewards({"Focus": 10})
	await _wait_for_action_type_count(action_list, "loop", 2, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	# -- VILLAGE --
	if await _open_area(area_list, "Village", stop_area_name): return true
	await _press_all_actions_of_type(action_list, "free") # We get the salve
	
	#-- HILLSTEAD OUTPOST --
	if await _open_area(area_list, "Hillstead Outpost", stop_area_name): return true
	await _wait_for_action_type_count(action_list, "loop", 2, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	myactionquery.reward_key = "Story points" # study weathered tomes
	await _press_actions_of_type(action_list,myactionquery,1) # Press study loop
	await _wait_for_action_type_count(action_list, "loop", 1, 15, 0.2) # One loop remains
	await _press_all_actions_of_type(action_list, "free") # close the last book
	await _press_actions_of_type(action_list,myactionquery,1) # Press patrol loop
	await _wait_for_action_type_count(action_list, "free", 1, 15, 0.2) # One free action remains
	# Keep pressing free actions until 0 remain
	await _wait_for_action_type_count(action_list, "free", 0, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))

	if current_reincarnation <= 1.0:
		# At this point we learn that we lack strength or wisdom+insight, and have to reincarnate again.
		#-- TEMPLE --
		if await _open_area(area_list, "Forgotten Temple", stop_area_name): return true
		# Keep pressing free actions until 1 remains
		await _wait_for_action_type_count(action_list, "reincarnation", 1, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
		query = ActionQuery.new("reincarnation") # Here we will reincarnate from the temple
		await _press_actions_of_type(action_list, query, 1)
	
		# We will now do the second reincarnation
		 #-- REINCARNATION --
		assert_true(await wait_until(is_visible.bind(area_list.areas_panel_container, false), 2, 0.5), "Expected area_list to be invisible")
		assert_true(special_area_list.special_areas_panel_container.visible == true, "Expected special_area_list to be visible")
		# We have entered the special reincarnation area, which holds actions
		await _wait_for_action_type_count(action_list, "reincarnation", 1, 15, 0.2) # 1 reincarnation action
		
		# Get the echoes of the past
		query = ActionQuery.new("free","","","Echoes of the Past")
		await _press_actions_of_type(action_list, query, 1)
		
		# We get one echo from the reward list, then force 2 more. This will save reincarnating again
		resources.apply_rewards({"Echoes of the Past": { "permanent": 3 }})
		query.reward_key = "Wisdom" # We also get Wisdom
		await _press_actions_of_type(action_list, query, 1)
		query.reward_key = "Insight" # We also get Insight
		await _press_actions_of_type(action_list, query, 1)
		resources.apply_rewards({"Insight": { "permanent": 1 }}) # Sneak in 1 more Insight
		query.reward_key = "Perception" # We also get Perception
		await _press_actions_of_type(action_list, query, 1)
		query.reward_key = "Story points" # Get the "Story points" max capacity buff
		await _press_actions_of_type(action_list, query, 1)
		resources.apply_rewards({"Story points": { "permanent_capacity": 25 }}) # Sneak in 25 more SP
		query = ActionQuery.new("reincarnation") # Reincarnate and start over
		await _press_actions_of_type(action_list, query, 1)
		return false # No interruptions, so return false

	# ## -- Continuing third reincarnation -- ## #
	# At this point we are in the third reincarnation and the hollowfang and unnamed lake areas are locked
	#-- HOLLOWFANG GORGE --
	await wait_seconds(0.01, "Entering Hollowfang Gorge, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "Hollowfang Gorge", stop_area_name): return true
	# Keep pressing free actions until 2 remain
	await _wait_for_action_type_count(action_list, "free", 2, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	resources.apply_rewards({"Focus": 10})
	# Study the glyphs, player understands the glyphs
	query = ActionQuery.new("free","","Wisdom","Story points")
	await _press_actions_of_type(action_list, query, 1)
	# Keep pressing free actions until 0 remain
	resources.apply_rewards({"Focus": 10})
	await _wait_for_action_type_count(action_list, "free", 0, 15, 0.2, _press_all_actions_of_type.bind(action_list, "free"))
	# -- By this point, Hollowfang gorge has been completed trough wisdom action
	
	#-- UNNAMED LAKE --
	await wait_seconds(0.01, "Entering The Unnamed Lake, reincarnation = " + str(current_reincarnation) + ", Story points = " + str(resources.get_resource("Story points").temporary))
	if await _open_area(area_list, "The Unnamed Lake", stop_area_name): return true
	await _wait_for_action_type_count(action_list, "free", 5, 15, 0.2) # We have 5 free actions
	resources.apply_rewards({"Focus": 10})
	await _press_all_actions_of_type(action_list, "free")

	if delay_seconds > 0.0: await wait_seconds(delay_seconds)
	return false # No interruptions, so return false
