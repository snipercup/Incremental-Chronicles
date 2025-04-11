# ResourceData.gd
class_name ResourceData
extends RefCounted

# === RESOURCE STATE ===
var temporary: float = 0.0  # Resets on reincarnation
var permanent: float = 0.0      # Carries across resets
var regeneration: float = 0.0   # Per-second visible gain
var temporary_capacity: float = 0.0  # Max temporary cap, resets on reset()
var permanent_capacity: float = 0.0  # Max permanent cap, does not reset
var name: String = ""  # Optional display name for this resource (used in tooltip)
signal resource_updated(myresource: ResourceData)


func _init(myname: String, cap: float = 0.0):
	name = myname
	permanent_capacity = cap

# === VALUE GETTERS ===

# Total value (not used in capacity checks)
func get_total() -> float:
	return temporary + permanent

# Returns the total capacity (temporary + permanent capacity)
func get_capacity() -> float:
	return temporary_capacity + permanent_capacity

# Returns true if temporary is at or above total capacity
func is_at_capacity() -> bool:
	var total_capacity := get_capacity()
	if total_capacity <= 0.0:
		return false
	return temporary >= total_capacity


# === VISIBLE METHODS ===

# Adds to the temporary (visible) capacity
func add_temporary_capacity(amount: float) -> void:
	if amount == 0.0:
		return
	temporary_capacity += amount
	_enforce_capacity()
	resource_updated.emit(self)

# Adds to the permanent capacity
func add_permanent_capacity(amount: float) -> void:
	if amount == 0.0:
		return
	permanent_capacity += amount
	resource_updated.emit(self)


func add_temporary(amount: float) -> void:
	if amount == 0.0:
		return
	temporary += amount
	_enforce_capacity()
	resource_updated.emit(self)

func remove_temporary(amount: float) -> void:
	if amount == 0.0:
		return
	temporary = max(temporary - amount, 0.0)
	resource_updated.emit(self)

func set_temporary(amount: float) -> void:
	temporary = max(amount, 0.0)
	_enforce_capacity()
	resource_updated.emit(self)

func get_temporary() -> float:
	return temporary


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

# Clamp temporary value to total capacity
func _enforce_capacity() -> void:
	var total_capacity := get_capacity()
	if total_capacity <= 0.0:
		return
	if temporary > total_capacity:
		temporary = total_capacity


# === REGENERATION ===

# Apply per-second visible resource regeneration
# Returns true if regeneration changed the visible value
func apply_regeneration(delta: float) -> bool:
	if regeneration <= 0.0:
		return false

	var before := temporary
	add_temporary(regeneration * delta)
	return temporary != before


# === UTILITIES ===

# Reset visible and hidden; optionally preserve permanent
# Returns true if all values (visible, hidden, permanent, regeneration) are 0.0 after reset
func reset(include_permanent: bool = false) -> bool:
	temporary = 0.0
	temporary_capacity = 0.0
	if include_permanent:
		permanent = 0.0
		permanent_capacity = 0.0
		regeneration = 0.0
	resource_updated.emit(self)
	return is_empty()

func is_empty() -> bool:
	return temporary == 0.0 and permanent == 0.0 and regeneration == 0.0

# === SERIALIZATION ===

# Convert to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"temporary": temporary,
		"permanent": permanent,
		"regeneration": regeneration,
		"temporary_capacity": temporary_capacity,
		"permanent_capacity": permanent_capacity,
	}

func from_dict(data: Dictionary) -> void:
	temporary = data.get("temporary", 0.0)
	permanent = data.get("permanent", 0.0)
	regeneration = data.get("regeneration", 0.0)
	temporary_capacity = data.get("temporary_capacity", 0.0)
	permanent_capacity = data.get("permanent_capacity", 0.0)
	name = data.get("name", name)


# Applies a reward dictionary to this resource.
# Example:
# only a number: 15.0, in this case we add only temporary value
# A dictionary for temporary: {"temporary": 1}
# A dictionary for permanent: {"permanent": 1}
# A dictionary for regeneration: {"regeneration": 0.1}
# A dictionary for permanent capacity: { "permanent_capacity": 10 }
# A dictionary for temporary capacity: { "temporary_capacity": 10 }
# A dictionary combination: {"temporary_capacity": 10, "regeneration": 0.1}
func apply_reward(data: Variant) -> void:
	if typeof(data) == TYPE_FLOAT or typeof(data) == TYPE_INT:
		add_temporary(data)
		return

	if data.has("temporary"):
		add_temporary(data["temporary"])
	if data.has("permanent"):
		add_permanent(data["permanent"])
	if data.has("regeneration"):
		regeneration += data["regeneration"]
	if data.has("temporary_capacity"):
		temporary_capacity += data["temporary_capacity"]
	if data.has("permanent_capacity"):
		permanent_capacity += data["permanent_capacity"]
	_enforce_capacity()


# Returns a single-line tooltip showing resource name, temporary and permanent values with icons.
# If the resource name starts with h_ it is hidden, so no tooltip
# Example: "Story points: 🕒 10 / 100  ♾️ 5"
func get_tooltip() -> String:
	var parts: Array = []

	# ⏳ Temporary
	var total_cap := get_capacity()
	if temporary > 0.0 or total_cap > 0.0:
		var tmp_text := "⏳ %d" % int(temporary)
		if total_cap > 0.0:
			tmp_text += " / %d" % int(total_cap)
		parts.append(tmp_text)

	# ♾️ Permanent
	if permanent > 0.0:
		parts.append("♾️ %d" % int(permanent))

	var body := "  ".join(parts)
	return name + ":" + body if name != "" and not body.is_empty() else body
