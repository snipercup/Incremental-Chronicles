extends NobodyWhoChat

# This script belongs to the AreaGenerator UI node
# This script will generate the text and data for a new action

@export var area_list: VBoxContainer = null # The list that displays the current areas
const STORY_ACTION_SAMPLER = preload("res://Resources/story_action_sampler.tres")
const STORY_AREA_SAMPLER = preload("res://Resources/story_area_sampler.tres")

signal action_generated(action: String) # When an action has been generated
signal area_generated(area: String) # When an area has been generated
var can_generate: bool = true # To enforce only one generation at a time

# Called when the node enters the scene tree
func _ready() -> void:
	_initialize_timer()

# Initialize the timer used for action generation
func _initialize_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = 3.0  # 5 second interval
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)


# Generate a new action in an area unless the area is at capacity
# To generate the action, we use the system prompt from that area
# The action is then added to the current area
func generate_action() -> void:
	print_debug("Generating action")
	var current_area: StoryArea = _get_current_area()
	if not current_area or current_area.is_at_capacity():
		print_debug("can_generate = true")
		can_generate = true
		return
	sampler = STORY_ACTION_SAMPLER
	sampler.seed = randi()  # Set seed to a random integer
	system_prompt = current_area.get_system_prompt()
	start_worker()
	sampler = STORY_ACTION_SAMPLER
	sampler.seed = randi()  # Set seed to a random integer
	system_prompt = current_area.get_system_prompt()
	say(current_area.get_say()) # say something

	var response = await response_finished	# wait for the response
	current_area.add_story_action_from_json(response)
	action_generated.emit(response)
	#print_debug("can_generate = true")
	can_generate = true

# Get the current active area from the list
func _get_current_area() -> StoryArea:
	if not area_list or area_list.get_child_count() == 0:
		return null
	return area_list.get_random_area()

# Generates a new area
func generate_area() -> void:
	sampler = STORY_AREA_SAMPLER
	sampler.seed = randi()  # Set seed to a random integer
	system_prompt = _build_area_prompt()
	start_worker()
	sampler = STORY_AREA_SAMPLER
	sampler.seed = randi()  # Set seed to a random integer
	system_prompt = _build_area_prompt()
	# say something
	say("Create a new area.")

	# wait for the response
	var response = await response_finished
	print_debug("Got area response: " + response)
	area_generated.emit(response)
	#print_debug("can_generate = true")
	can_generate = true


# Called every second when the Timer times out
func _on_timer_timeout():
	if not can_generate:
		print_debug("can not generate, returning")
		return
	#print_debug("can_generate = false")
	can_generate = false
	if area_list.needs_new_area():
		generate_area()
	else:
		generate_action()


# Build the detailed area creation prompt
func _build_area_prompt() -> String:
	var file = FileAccess.open("res://Resources/area_prompt.txt", FileAccess.READ)
	if file:
		return file.get_as_text()
	else:
		print_debug("Failed to load area prompt file.")
		return "Describe a new area."
