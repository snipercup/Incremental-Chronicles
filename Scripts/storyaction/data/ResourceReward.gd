# ResourceReward.gd
class_name ResourceReward
extends RefCounted

# === STORED VALUES ===
var visible: float = 0.0
var hidden: float = 0.0
var permanent: float = 0.0
var regeneration: float = 0.0
var capacity: float = 0.0


# === CONSTRUCTOR ===

# Parse dictionary on creation (optional)
func from_dict(data: Dictionary) -> void:
	visible = data.get("visible", 0.0)
	hidden = data.get("hidden", 0.0)
	permanent = data.get("permanent", 0.0)
	regeneration = data.get("regeneration", 0.0)
	capacity = data.get("capacity", 0.0)


# === MANIPULATION ===

func add_to(other: ResourceReward) -> void:
	visible += other.visible
	hidden += other.hidden
	permanent += other.permanent
	regeneration += other.regeneration
	capacity += other.capacity

func is_empty() -> bool:
	return visible == 0 and hidden == 0 and permanent == 0 and regeneration == 0 and capacity == 0


# === APPLICATION ===

# Applies this reward to a ResourceData instance
func apply_to(resource: ResourceData) -> void:
	resource.add_visible(visible)
	resource.add_hidden(hidden)
	resource.add_permanent(permanent)
	resource.regeneration += regeneration
	resource.capacity += capacity


# === SERIALIZATION ===

func to_dict() -> Dictionary:
	return {
		"visible": visible,
		"hidden": hidden,
		"permanent": permanent,
		"regeneration": regeneration,
		"capacity": capacity
	}
