extends Control

# This script is the main controller of the game
@export var helper: Node = null
@export var action_list: VBoxContainer = null
@export var area_list: VBoxContainer = null
@export var special_area_list: VBoxContainer = null



func _ready():
	helper.initialize()
	print_debug("game started")
	SignalBroker.game_started.emit()
