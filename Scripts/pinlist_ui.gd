extends VBoxContainer

# This script belongs to the pinlist_ui scene and is used to update the pinlist
# This list will take a StoryAction instance and read its requirements
# Each requirement will be added to the requirement_item_list
# The format of each item will be [needed] requirement (current/max)
# For example: [40] resolve (1/10)

# The list may contain 1 or 100 requirements
# When all requirements are met, the ui is updated (green) to show the action can be cleared
# A bin icon lets the player remove this pinlist at any time

# Example StoryAction requirements:
# "requirements": {
		#"Story Point": 1,
		#"Ethereal Mana": 2
#}

@export var pin_list_label: Label = null
@export var rewards_requirements: VBoxContainer = null
var action: StoryAction = null
signal removed

func set_story_action(myaction: StoryAction):
	action = myaction
	pin_list_label.text = action.area.name
	rewards_requirements.set_story_action(myaction)

# Detect right-click events
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			print_debug("Right-click detected")
			removed.emit() # Send signal to pinlist
			queue_free() # Remove itself from pin list
