class_name CombatAction
extends StoryAction

# Example combat step:
	#{
	  #"action_type": "combat",
	  #"requirements": {
		#"Resolve": 1.0
	  #},
	  #"rewards": {
		#"Story Point": 10.0
	  #},
	  #"story_text": "A rat scurries toward you, teeth bared and eyes gleaming in the dim light. You prepare to defend yourself.",
	  #"enemy": {
		  #"name": "Rat",
		  #"strength": 1.0
		#}
	#}


var enemy: Dictionary = {}

func _init(data: Dictionary) -> void:
	super(data)  # Call parent class _init function
	# Read and store the enemy data if available
	enemy = data.get("enemy", {})


#Player Strength	Enemy Strength	Success Chance
#0					1				0%
#1					1				50%
#2					1				100%
#1.5				1				75%
#0.5				1				25%
func test_combat_success(player_strength: int) -> bool:
	var enemy_strength: float = enemy.get("strength", 1.0)
	
	if player_strength <= 0:
		return false  # 0 strength = 0% chance
	var success_chance: float = clamp(player_strength / (enemy_strength * 2), 0.0, 1.0)
	# If player strength == enemy strength → 50% chance of success
	success_chance = lerp(0.5, 1.0, success_chance)
	return randf() < success_chance


func get_icon() -> String:
	return "⚔️"
