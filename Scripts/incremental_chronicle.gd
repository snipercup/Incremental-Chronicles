extends Control

# This script is the main controller of the game

@export var area_list: VBoxContainer = null

func _ready():
	#print_debug("Game started")
	area_list.create_tunnel()
	#area_list.create_area()
