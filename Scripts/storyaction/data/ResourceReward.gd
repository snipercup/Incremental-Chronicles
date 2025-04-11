# ResourceReward.gd
class_name ResourceReward
extends RefCounted

# === STORED VALUES ===
var temporary: float = 0.0
var permanent: float = 0.0
var regeneration: float = 0.0
var temporary_capacity: float = 0.0
var permanent_capacity: float = 0.0


# Example rewards json:
#	  "rewards": {
#		"Story points": 15.0, //Adds temporary points
#		"Focus": { "regeneration": 0.1 }, //Adds to regeneration amount
#		"Perception": { "permanent": 1 }, //Adds to permanent amount
#		"Perception": { "temporary": 1 }, //Adds to temporary amount
#		"Story Points": { "permanent_capacity": 10 }, //adds to permanent max capacity
#		"Story Points": { "temporary_capacity": 10 }, //adds to temporary max capacity
#		"h_hidden_rat_reward": 1.0 //Adds to temporary amount
#	  }


# === CONSTRUCTOR ===

# Parse dictionary on creation (optional)
func from_dict(data: Dictionary) -> void:
	temporary = data.get("temporary", 0.0)
	permanent = data.get("permanent", 0.0)
	regeneration = data.get("regeneration", 0.0)
	temporary_capacity = data.get("temporary_capacity", 0.0)
	permanent_capacity = data.get("permanent_capacity", 0.0)

# === MANIPULATION ===

func add_to(other: ResourceReward) -> void:
	temporary += other.temporary
	permanent += other.permanent
	regeneration += other.regeneration
	temporary_capacity += other.temporary_capacity
	permanent_capacity += other.permanent_capacity


func is_empty() -> bool:
	return (
	temporary == 0 and
	permanent == 0 and
	regeneration == 0 and
	temporary_capacity == 0 and
	permanent_capacity == 0
)

# === APPLICATION ===

# Applies this reward to a ResourceData instance
func apply_to(resource: ResourceData) -> void:
	resource.add_temporary(temporary)
	resource.add_permanent(permanent)
	resource.regeneration += regeneration
	resource.add_temporary_capacity(temporary_capacity)
	resource.add_permanent_capacity(permanent_capacity)


# === SERIALIZATION ===

func to_dict() -> Dictionary:
	return {
		"temporary": temporary,
		"permanent": permanent,
		"regeneration": regeneration,
		"temporary_capacity": temporary_capacity,
		"permanent_capacity": permanent_capacity
	}
