class_name CombatAction
extends StoryAction

# Example combat step:
#	{
#	  "action_type": "combat",
#	  "requirements": {
#		"visible": { "Resolve": {"consume": 20.0} },
#		"hidden": { "path_obstructed": {"appear":{"min": 1.0}} },
#		"permanent": { "Intelligence": {"amount": 1.0} },
#		"sum": { "Strength": {"amount": 1.0} }
#	  },
#	  "rewards": {
#		"visible": {"Story points": 15.0},
#		"hidden": {"hidden_rat_reward": 1.0}
#	  },
#	  "story_text": "A rat scurries toward you, teeth bared and eyes gleaming in the dim light. You prepare to defend yourself.",
#	  "enemy": { "name": "Rat", "strength": 1.0 }
#	}

var ui_scene: PackedScene = preload("res://Scenes/action/story_action_combat_ui.tscn")
var enemy: Dictionary = {}
# Number of allowed attempts to defeat the enemy
const TOTAL_CHANCES: int = 3
var remaining_chances: int = TOTAL_CHANCES
var success_count: int = 0

# Signal to emit when the enemy is defeated
signal enemy_defeated

func _init(data: Dictionary, myarea: StoryArea = null) -> void:
	super(data, myarea)  # Call parent class _init function
	# Read and store the enemy data if available
	enemy = data.get("enemy", {})
	print_debug("my class name is: " + get_class())


#Player Strength	Enemy Strength	Success Chance
#0					1				0%
#1					1				50%
#2					1				100%
#1.5				1				75%
#0.5				1				25%
func test_combat_success(player_strength: float) -> bool:
	var enemy_strength: float = enemy.get("strength", 1.0)
	if player_strength <= 0:
		return false  # 0 strength = 0% chance
	var success_chance: float = clamp(player_strength / (enemy_strength * 2), 0.0, 1.0)
	# If player strength == enemy strength → 50% chance of success
	success_chance = lerp(0.5, 1.0, success_chance)
	return randf() < success_chance

# The icon to use in the UI
func get_icon() -> String:
	return "⚔️"

# Set the number of chances and reset success count
func reset_combat_progress() -> void:
	remaining_chances = TOTAL_CHANCES
	success_count = 0

# Get the number of remaining chances
func get_remaining_chances() -> int:
	return remaining_chances

# Perform a combat attempt and track success
func attempt_combat(player_strength: float) -> bool:
	if remaining_chances <= 0:
		return false

	remaining_chances -= 1
	if test_combat_success(player_strength):
		success_count += 1
	
	# If two or more successes → defeat enemy
	if success_count >= 2:
		enemy_defeated.emit()
		return true
	return false

# Check if the enemy is defeated (two or more successes)
func is_enemy_defeated() -> bool:
	return success_count >= 2

func get_successes() -> int:
	return success_count

# Returns the type as specified in the json
func get_type() -> String:
	return "combat"
