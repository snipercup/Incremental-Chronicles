extends VBoxContainer

# This script belongs to the RequirementPinList in the main scene
# This vboxcontainer contains instances of the pinlist_ui scene
# This script will accept an action the player selects trough a button or hotkey
# It will then check if the action has already been entered into this pinlist
# If it wasn't added already, it will create a new instance of PINLIST_UI and set the action
# When a pinlist is removed trough its UI, we also remove the associated action

const PINLIST_UI = preload("res://Scenes/pinlist_ui.tscn")
