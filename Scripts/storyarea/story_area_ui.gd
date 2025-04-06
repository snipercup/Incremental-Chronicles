extends PanelContainer

# This script is used with the StoryAreaUI scene
# This script is used to update the ui for a Storyarea
# This script will signal when the user presses the area_button

@export var story_point_requirement_label: Label = null
@export var stars_label: Label = null
@export var area_button: Button = null
var story_area: StoryArea

# Handle area button press
func _ready():
	if area_button:
		area_button.pressed.connect(_on_area_button_pressed)

	# Connect to the area_removed signal
	SignalBroker.area_removed.connect(_on_area_removed)

# Setters for controls and variables
func set_story_point_requirement_label(value: String) -> void:
	if story_point_requirement_label:
		story_point_requirement_label.text = value

func set_stars_label(value: String) -> void:
	if stars_label:
		stars_label.text = value

func set_area_button_text(value: String) -> void:
	if area_button:
		area_button.text = value

# Set story area and update controls
func set_story_area(value: StoryArea) -> void:
	story_area = value
	if story_area == null:
		return

	print_debug("Creating story area in area list. Name = %s, tier = %s" % [story_area.get_name(), str(story_area.get_tier())])

	var requirements: Dictionary = story_area.get_requirements()
	var requirements_text: Array[String] = []

	# Iterate through all ResourceRequirement entries (already parsed)
	for key in requirements:
		var req: ResourceRequirement = requirements[key]
		var parts := []

		# Add visible amount
		if req.required_amount_visible > 0.0:
			parts.append("🕒%s" % int(req.required_amount_visible))

		# Add consume
		if req.consume_visible > 0.0:
			parts.append("–%s" % int(req.consume_visible))

		# Add appear min/max
		if req.appear_min_visible > -INF or req.appear_max_visible < INF:
			if req.appear_max_visible < INF:
				parts.append("%s–%s" % [int(req.appear_min_visible), int(req.appear_max_visible)])
			else:
				parts.append("%s+" % int(req.appear_min_visible))

		# Add sum requirement
		if req.required_total_sum > 0.0:
			parts.append("Σ%s" % int(req.required_total_sum))

		if not parts.is_empty():
			requirements_text.append("[%s] %s" % [", ".join(parts), key])

	# === UI Updates ===
	set_story_point_requirement_label("%s" % ", ".join(requirements_text))
	set_stars_label("★".repeat(story_area.get_tier()))
	set_area_button_text(story_area.get_name())

	# Show/hide locked indicators
	var is_locked := story_area.get_state() == StoryArea.State.LOCKED
	if stars_label:
		stars_label.visible = is_locked
	if story_point_requirement_label:
		story_point_requirement_label.visible = is_locked
	if area_button and is_locked:
		set_area_button_text("Locked")



func _on_area_button_pressed() -> void:
	# Emit the signal, passing this control as a parameter
	SignalBroker.area_pressed.emit(story_area)

func get_area_actions() -> Array[StoryAction]:
	return story_area.get_story_actions()

func get_area() -> StoryArea:
	return story_area

func is_area_locked() -> bool:
	return story_area.state == StoryArea.State.LOCKED

# Handle when an area is removed
func _on_area_removed(removed_area: StoryArea) -> void:
	if removed_area == story_area:
		queue_free()  # Free this UI element if the associated area was removed
