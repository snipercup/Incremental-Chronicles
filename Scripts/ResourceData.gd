# ResourceData.gd
class_name ResourceData
extends RefCounted

# === RESOURCE STATE ===
var visible: float = 0.0        # Shown to the player
var hidden: float = 0.0         # Internal/hidden counters
var permanent: float = 0.0      # Carries across resets
var regeneration: float = 0.0   # Per-second visible gain
var capacity: float = 0.0       # Max cap applies to VISIBLE ONLY
signal resource_updated(myresource: ResourceData)


# === VALUE GETTERS ===

# Total value (not used in capacity checks)
func get_total() -> float:
	return visible + hidden + permanent

# Returns true if visible group is at or above capacity
func is_at_capacity() -> bool:
	if capacity <= 0.0:
		return false
	return visible >= capacity


# === VISIBLE METHODS ===

func add_visible(amount: float) -> void:
	if amount == 0.0:
		return
	visible += amount
	_enforce_capacity()
	resource_updated.emit(self)

func remove_visible(amount: float) -> void:
	if amount == 0.0:
		return
	visible = max(visible - amount, 0.0)
	resource_updated.emit(self)

func set_visible(amount: float) -> void:
	visible = max(amount, 0.0)
	_enforce_capacity()
	resource_updated.emit(self)

func get_visible() -> float:
	return visible


# === HIDDEN METHODS ===

func add_hidden(amount: float) -> void:
	if amount == 0.0:
		return
	hidden += amount
	resource_updated.emit(self)

func remove_hidden(amount: float) -> void:
	if amount == 0.0:
		return
	hidden = max(hidden - amount, 0.0)
	resource_updated.emit(self)

func set_hidden(amount: float) -> void:
	hidden = max(amount, 0.0)
	resource_updated.emit(self)

func get_hidden() -> float:
	return hidden


# === PERMANENT METHODS ===

func add_permanent(amount: float) -> void:
	if amount == 0.0:
		return
	permanent += amount
	resource_updated.emit(self)

func remove_permanent(amount: float) -> void:
	if amount == 0.0:
		return
	permanent = max(permanent - amount, 0.0)
	resource_updated.emit(self)

func set_permanent(amount: float) -> void:
	permanent = max(amount, 0.0)
	resource_updated.emit(self)

func get_permanent() -> float:
	return permanent


# === CAPACITY ENFORCEMENT ===

# Clamp visible value to capacity
func _enforce_capacity() -> void:
	if capacity <= 0.0:
		return
	if visible > capacity:
		visible = capacity


# === REGENERATION ===

# Apply per-second visible resource regeneration
func apply_regeneration(delta: float) -> void:
	if regeneration > 0.0:
		add_visible(regeneration * delta)


# === UTILITIES ===

# Reset visible and hidden; optionally preserve permanent
func reset(exclude_permanent: bool = false) -> void:
	visible = 0.0
	hidden = 0.0
	if not exclude_permanent:
		permanent = 0.0
		regeneration = 0.0
	resource_updated.emit(self)


# === SERIALIZATION ===

# Convert to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"visible": visible,
		"hidden": hidden,
		"permanent": permanent,
		"regeneration": regeneration,
		"capacity": capacity
	}

# Load from dictionary
func from_dict(data: Dictionary) -> void:
	visible = data.get("visible", 0.0)
	hidden = data.get("hidden", 0.0)
	permanent = data.get("permanent", 0.0)
	regeneration = data.get("regeneration", 0.0)
	capacity = data.get("capacity", 0.0)

# Applies a reward dictionary to this resource.
# Example:
# {
#   "visible": 5,
#   "hidden": 2,
#   "permanent": 1,
#   "regeneration": 0.5,
#   "capacity": 10
# }
func apply_reward(data: Dictionary) -> void:
	if data.has("visible"):
		add_visible(data["visible"])
	if data.has("hidden"):
		add_hidden(data["hidden"])
	if data.has("permanent"):
		add_permanent(data["permanent"])
	if data.has("regeneration"):
		regeneration += data["regeneration"]
	if data.has("capacity"):
		capacity += data["capacity"]
	_enforce_capacity()

# Returns a single-line tooltip showing temporary and permanent values with icons.
# Example: "🕒 10 / 100  ♾️ 5"
func get_tooltip() -> String:
	var parts: Array = []

	# 🕒 Temporary (visible)
	if visible > 0.0 or capacity > 0.0:
		var tmp_text := "🕒 %d" % int(visible)
		if capacity > 0.0:
			tmp_text += " / %d" % int(capacity)
		parts.append(tmp_text)

	# ♾️ Permanent
	if permanent > 0.0:
		parts.append("♾️ %d" % int(permanent))

	return "  ".join(parts)
