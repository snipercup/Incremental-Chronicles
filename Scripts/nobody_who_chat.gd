extends NobodyWhoChat

# This script belongs to the AreaGenerator UI node
# This script will generate the text and data for a new action

@export var area_list: VBoxContainer = null

signal action_generated(action: String)
signal area_generated(area: String)
var can_generate: bool = true

func _ready():
	# Create a Timer node dynamically
	var timer = Timer.new()
	timer.wait_time = 5.0  # 5 second interval
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)  # Connect the signal to the callback function
	add_child(timer)  # Add the Timer as a child of this node
	#print_debug("timer started")
	start_worker()


func generate_action() -> void:
	var current_area: StoryArea = area_list.get_random_area()
	if not current_area:
		return
	if current_area.is_at_capacity():
		#print_debug("can_generate = true")
		can_generate = true
		return
	start_worker()
	sampler.seed = randi()  # Set seed to a random integer
	system_prompt = current_area.get_system_prompt()
	say(current_area.get_say()) # say something
	# wait for the response
	var response = await response_finished
	current_area.add_story_action_from_json(response)
	action_generated.emit(response)
	#print_debug("can_generate = true")
	can_generate = true


func generate_area() -> void:
	#print_debug("generating area")
	start_worker()
	#var current_area: StoryArea = area_list.get_random_area()
	sampler.seed = randi()  # Set seed to a random integer
	var myprompt: String = "You are an expert at creating immersive and detailed locations for a medieval fantasy game called *Incremental Chronicles*. Your task is to design a new area for this game. The world of *Incremental Chronicles* is rich with magic, ancient ruins, mysterious forces, and diverse inhabitants. The setting is grounded in medieval culture with a blend of high fantasy elements.**"
	myprompt += "**Create a name and a detailed description for the new area. The area can be a village, forest, ruins, cave, mountain, or similar location. Include the following details:**"
	myprompt += "- **Name:** A compelling name that reflects the character and tone of the area."
	myprompt += "- **General Overview:** A short summary of the area’s purpose, history, or significance."
	myprompt += "- **Landmarks and Structures:** Describe unique features such as castles, ancient altars, abandoned watchtowers, mystical groves, or underground tunnels."
	myprompt += "- **Inhabitants and NPCs:** Who or what lives here? Mention any notable factions, characters, or creatures. "
	myprompt += "- **Atmosphere and Mood:** Describe the feeling of the area — is it peaceful, sinister, mysterious, or bustling?"
	myprompt += "- **Lore and Backstory:** Provide any myths, curses, ancient conflicts, or lost knowledge tied to the area."
	myprompt += "- **Resources and Dangers:** Mention any valuable resources or hidden dangers, such as rare herbs, magical artifacts, roaming monsters, or environmental hazards.**"
	myprompt += "**Example:**"
	myprompt += "*'Ember Hollow'*"
	myprompt += "A secluded valley where the ground is scorched and veins of molten rock glow beneath the surface. Crumbling stone towers loom over the blackened soil, remnants of an ancient battlemage citadel. Strange, red-leafed trees grow along the ridge, their roots rumored to draw power from the scorched earth. The air smells of sulfur, and flickering shadows dance along the rocky walls at night. Whispered legends speak of a trapped fire spirit beneath the valley — and those who seek its power rarely return unchanged.*"
	myprompt += "**Be vivid, atmospheric, and creative — make the player *see* and *feel* the area!"
	system_prompt = myprompt
	# say something
	say("Create a new area.")

	# wait for the response
	var response = await response_finished
	#print_debug("Got area response: " + response)
	area_generated.emit(response)


# Called every second when the Timer times out
func _on_timer_timeout():
	if not can_generate:
		print_debug("can not generate, returning")
		return
	#print_debug("can_generate = false")
	can_generate = false
	generate_action()
