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
		#"Story Point": 1000000,
		#"Ethereal Mana": 1000000,
		#"Void Essence": 750000,
		#"Ancient Rune Stones": 500000,
		#"Soul Gems": 300000,
		#"Phoenix Feathers": 100000,
		#"Dragonfang Crystals": 150000,
		#"Orb of Eternity": 1,
		#"Heart of the World Tree": 1,
		#"Essence of Rebirth": 50000,
		#"Light of the Lost Star": 1
		#"Strength": 50000,
		#"Spirit Bond": 40000,
		#"Persistence": 45000
#}

@onready var pin_list_label: Label = $PinListLabel
@onready var requirement_item_list: ItemList = $RequirementItemList
