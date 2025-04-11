extends PanelContainer

# This script is used with the StoryAreaUI scene
# This script is used to update the ui for a Storyarea
# This script will signal when the user presses the area_button

@export var story_point_requirement_label: Label = null
@export var stars_label: Label = null
@export var stats_container: HBoxContainer = null
@export var area_button: Button = null

var story_area: StoryArea
var is_active: bool = false


# Handle area button press
func _ready():
	if area_button:
		area_button.pressed.connect(_on_area_button_pressed)

	# Connect to the area_removed signal
	SignalBroker.area_removed.connect(_on_area_removed)
	# Refresh area progress display when resources change
	SignalBroker.resources_updated.connect(_on_resources_updated)

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

	# === UI Updates ===
	# Show textual progress per requirement
	var requirements: Dictionary = story_area.get_requirements()
	set_story_point_requirement_label(_format_requirement_progress(requirements))
	_update_progress_visuals()
	set_stars_label("★".repeat(story_area.get_tier()))

	# Show/hide locked indicators
	var is_locked := story_area.get_state() == StoryArea.State.LOCKED
	if stars_label:
		stars_label.visible = is_locked
	if story_point_requirement_label:
		story_point_requirement_label.visible = is_locked


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

# Calculates overall progress toward unlocking the area
func _update_progress_visuals() -> void:
	if story_area == null:
		return
	# If the area is already unlocked, display its name and skip progress visuals
	if story_area.get_state() == StoryArea.State.UNLOCKED:
		if area_button:
			set_area_button_text(story_area.get_name())
			area_button.modulate = Color(1, 1, 1) # Reset tint
		return

	var requirements := story_area.get_requirements()
	var total_progress := 0.0
	var req_count := 0

	var resource_manager = get_tree().get_first_node_in_group("helper").resource_manager
	if resource_manager == null:
		return

	for key in requirements:
		var req: ResourceRequirement = requirements[key]
		var resource: ResourceData = resource_manager.get_resource(key)

		var current := 0.0
		var needed := 0.0

		if req.consume_temporary > 0.0:
			current = resource.get_temporary() if resource else 0.0
			needed = req.consume_temporary
		elif req.consume_permanent > 0.0:
			current = resource.get_permanent() if resource else 0.0
			needed = req.consume_permanent
		elif req.required_amount > 0.0:
			current = resource.get_total() if resource else 0.0
			needed = req.required_amount

		if needed > 0.0:
			total_progress += clampf(current / needed, 0.0, 1.0)
			req_count += 1

	# Average progress if multiple requirements
	var avg_progress = total_progress / max(1, req_count)

	# Button tint based on progress
	if area_button:
		area_button.modulate = Color(1.0, 0.5 + 0.5 * avg_progress, 0.5 + 0.5 * avg_progress)

	# Optional: dynamic text update
	if avg_progress >= 1.0:
		set_area_button_text("Enter Area")
	else:
		set_area_button_text("Progress: %d%%" % int(avg_progress * 100))


func _format_requirement_progress(requirements: Dictionary) -> String:
	var resource_manager = get_tree().get_first_node_in_group("helper").resource_manager
	if resource_manager == null:
		return ""

	var lines: Array[String] = []

	for key in requirements:
		var req: ResourceRequirement = requirements[key]
		var resource: ResourceData = resource_manager.get_resource(key)

		var current := 0.0
		var needed := 0.0
		var symbol := ""

		if req.consume_temporary > 0.0:
			needed = req.consume_temporary
			symbol = "⏳"
			current = resource.get_temporary() if resource else 0.0
		elif req.consume_permanent > 0.0:
			needed = req.consume_permanent
			symbol = "♾️"
			current = resource.get_permanent() if resource else 0.0
		elif req.required_amount > 0.0:
			needed = req.required_amount
			symbol = "🕒"
			current = resource.get_total() if resource else 0.0

		if needed > 0.0:
			lines.append("%s%s: %d/%d" % [symbol, key, int(current), int(needed)])

	return "\n".join(lines)


# Called when resources update — used to refresh the displayed requirement progress
func _on_resources_updated(_resource_store: Label) -> void:
	if story_area == null:
		return

	var requirements := story_area.get_requirements()
	set_story_point_requirement_label(_format_requirement_progress(requirements))
	_update_progress_visuals()


# Highlights the area button if this area is currently active (unlocked only)
func set_is_active(value: bool) -> void:
	is_active = value
	_update_active_button_style()

func _update_active_button_style() -> void:
	if story_area == null or area_button == null:
		return

	var is_unlocked := story_area.get_state() == StoryArea.State.UNLOCKED

	# Only highlight if this area is unlocked and currently selected
	if is_unlocked and is_active:
		stats_container.visible = false
		# === Normal style (selected) ===
		var normal_box := area_button.get_theme_stylebox("normal").duplicate()
		normal_box.border_width_top = 1
		normal_box.border_width_bottom = 1
		normal_box.border_width_left = 1
		normal_box.border_width_right = 1
		normal_box.border_color = Color(1.0, 0.84, 0.0) # Gold
		area_button.add_theme_stylebox_override("normal", normal_box)

		# === Hover style (selected + hovered) ===
		var hover_box := area_button.get_theme_stylebox("hover").duplicate()
		hover_box.border_width_top = 1
		hover_box.border_width_bottom = 1
		hover_box.border_width_left = 1
		hover_box.border_width_right = 1
		hover_box.border_color = Color(0.8, 0.6, 0.0) # Darker gold
		area_button.add_theme_stylebox_override("hover", hover_box)
	else:
		# Remove highlight when not active
		area_button.remove_theme_stylebox_override("normal")
		area_button.remove_theme_stylebox_override("hover")
