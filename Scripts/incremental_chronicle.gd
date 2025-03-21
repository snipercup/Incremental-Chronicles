extends Control

# This script is the main controller of the game

@export var area_list: VBoxContainer = null
@export var helper: Node = null


func _ready():
	#print_debug("Game started")
	helper.initialize()
