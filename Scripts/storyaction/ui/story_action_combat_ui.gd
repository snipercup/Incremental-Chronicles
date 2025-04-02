extends HBoxContainer

# This script is used with the StoryActionCombatUI scene
# This script will signal when the user presses the button

var story_action: CombatAction
var parent: Control
@export var button: Button = null
@export var checks_v_box_container: VBoxContainer = null

func set_action_button_text(value: String) -> void:
	button.text = value

# Update the UI for this action
func set_story_action(value: StoryAction) -> void:
	story_action = value
	if story_action:
		set_action_button_text(story_action.get_story_text())

func set_parent(newparent: Control) -> void:
	parent = newparent

# Handle action button press
func _ready():
	button.pressed.connect(_on_action_button_pressed)
	update_combat_progress()


# Get the player's strength from the resource manager
func get_player_strength() -> float:
	var resource_manager: Node = parent.get_resource_manager()
	var temporary_strength: float = resource_manager.get_resource("visible","Strength")
	var permanent_strength: float = resource_manager.get_resource("permanent","Strength")
	return temporary_strength+permanent_strength


# Create nodes in the container to represent combat chances
func update_combat_progress() -> void:
	# Clear existing nodes
	for child in checks_v_box_container.get_children():
		child.queue_free()
	
	var total_chances: int = story_action.TOTAL_CHANCES
	var remaining_chances: int = story_action.get_remaining_chances()
	var successes: int = story_action.get_successes()

	for i in range(total_chances):
		var label = Label.new()
		if i < successes:
			label.text = "✅"  # Success icon
			label.modulate = Color(0, 1, 0)  # Green for success
		elif i < total_chances - remaining_chances:
			label.text = "❌"  # Failure icon
			label.modulate = Color(1, 0, 0)  # Red for failure
		else:
			label.text = "⬜"  # Pending icon
			label.modulate = Color(1, 1, 1)  # White for pending
		checks_v_box_container.add_child(label)


# Handle action button press
func _on_action_button_pressed() -> void:
	# First check if the player meets the requirements
	if not parent.apply_requirements(story_action.requirements):
		print_debug("Not enough resources to perform combat.")
		return
	SignalBroker.action_activated.emit(story_action)
	
	story_action.attempt_combat(get_player_strength())
	update_combat_progress()
	
	# If enemy is defeated, set to remove
	if story_action.is_enemy_defeated():
		print_debug("Enemy defeated!")
		SignalBroker.action_rewarded.emit(story_action)
		SignalBroker.action_removed.emit(story_action)
		return
	
	# If all chances are used up and enemy is not defeated, reset progress
	if story_action.get_remaining_chances() == 0:
		print_debug("All chances used up — combat failed.")
		story_action.reset_combat_progress()
		update_combat_progress()
