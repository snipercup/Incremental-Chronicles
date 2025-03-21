extends Control

# This script is the main controller of the game
@export var helper: Node = null


func _ready():
	helper.initialize()
