extends VBoxContainer

# This script belongs to the RequirementPinList in the main scene
# This vboxcontainer contains instances of the pinlist_ui scene
# This script will accept a StoryAction the player selects trough a button or hotkey
# It will then check if the action has already been entered into this pinlist
# If it wasn't added already, it will create a new instance of PINLIST_UI and set the action property
# When a pinlist is removed trough its UI, we also remove the associated action

const PINLIST_UI = preload("res://Scenes/pinlist_ui.tscn")
var story_actions: Array[StoryAction] = []

func _ready():
	# Connect to the action_removed signal
	SignalBroker.action_removed.connect(remove_story_action)

# Add a StoryAction to the list if it's not already present
func add_action(action: StoryAction) -> void:
	if action in story_actions:
		return # Already added, skip
	story_actions.append(action)
	_create_pinlist_ui(action)

# Create a new instance of PINLIST_UI and set the action
func _create_pinlist_ui(action: StoryAction) -> void:
	var pinlist_ui: VBoxContainer = PINLIST_UI.instantiate()
	pinlist_ui.set_story_action(action)
	# Connect the signal for removal
	pinlist_ui.removed.connect(_on_pinlist_removed.bind(action))
	add_child(pinlist_ui)

# Remove an action when its pinlist is removed
func _on_pinlist_removed(action: StoryAction) -> void:
	if action in story_actions:
		story_actions.erase(action)
		print_debug("Removed action:", action.get_story_text())

# Function to remove a StoryAction from the list
func remove_story_action(action: StoryAction) -> void:
	if action in story_actions:
		story_actions.erase(action)
		print_debug("Removed story action:", action.get_story_text())
	else:
		print_debug("Action not found in list:", action.get_story_text())
