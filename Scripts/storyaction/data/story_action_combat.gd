class_name CombatAction
extends StoryAction

# Example combat step:
#	{
#	  "action_type": "combat",
#	  "story_text": "A rat scurries toward you, teeth bared and eyes gleaming in the dim light. You prepare to defend yourself.",
#	  "enemy": { "name": "Rat", "strength": 1.0 },
#	  "requirements": { "Resolve": { "consume": 1.0 } },
#	  "rewards": { "Story points": 15.0, "h_hidden_rat_reward": 1.0 }
#	},

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


func test_combat_success(player_strength: float) -> bool:
	var enemy_strength: float = enemy.get("strength", 1.0)
	var success_chance := calculate_combat_success_chance(player_strength, enemy_strength)
	return randf() < success_chance


# === Combat Success Chance Table (Enemy Strength = 10) ===
# Player Strength    Enemy Strength    Success Chance
# 0.0                10                0%
# 2.5                10                ~5%
# 5.0                10                10%   # Half strength
# 7.5                10                30%
# 10.0               10                50%   # Equal strength
# 12.5               10                62.5%
# 15.0               10                75%
# 17.5               10                87.5%
# 20.0               10                100%  # Double strength
func calculate_combat_success_chance(player_strength: float, enemy_strength: float) -> float:
	if player_strength <= 0:
		return 0.0  # 0 strength = 0% chance

	var ratio := player_strength / enemy_strength
	var success_chance: float

	if ratio < 1.0:
		# Below equal strength — scale from 10% to 50% between 0.5 and 1.0 ratio
		var scaled := inverse_lerp(0.5, 1.0, ratio)
		scaled = clamp(scaled, 0.0, 1.0)
		success_chance = lerp(0.1, 0.5, scaled)
	elif ratio == 1.0:
		success_chance = 0.5
	else:
		# Above equal strength — scale from 50% to 100%
		var overkill = min((ratio - 1.0), 1.0)
		success_chance = lerp(0.5, 1.0, overkill)
	return success_chance


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

# Returns the enemy's strength value from the combat data
func get_enemy_strength() -> float:
	return enemy.get("strength", 1.0)  # Default to 1.0 if not defined
