# ResourceStore.gd
class_name ResourceStore
extends RefCounted

var updated: Signal # Dynamically emitted when resources change

var resources: Dictionary = {} # Keep track of each resource amount by using name and value
var caps: Dictionary = {} # Base capacity per resource
var respect_caps: bool = false

# Optional: provide caps if needed
func _init(use_caps: bool = false, caps_data: Dictionary = {}) -> void:
	respect_caps = use_caps
	caps = caps_data

func add(key: String, amount: float) -> bool:
	if amount <= 0:
		return false

	var current = resources.get(key, 0.0)
	var max_cap = caps.get(key, 0.0) if respect_caps else 0.0

	if respect_caps and max_cap > 0.0:
		if current >= max_cap:
			return false
		resources[key] = min(current + amount, max_cap)
	else:
		resources[key] = current + amount

	updated.emit(self)
	return true

func remove(key: String, amount: float) -> void:
	if key in resources:
		resources[key] = max(resources[key] - amount, 0.0)
		prune_zeros()
		updated.emit(self)

func set_value(key: String, amount: float) -> void:
	resources[key] = max(amount, 0.0)
	prune_zeros()
	updated.emit(self)

func get_value(key: String) -> float:
	return resources.get(key, 0.0)

# Returns true if the resources contain enough of each to fulfill the requirements
func has_all(requirements: Dictionary) -> bool:
	for key in requirements.keys():
		if get_value(key) < requirements[key]:
			return false
	return true

# Subtracts all the requirments from the resources and returns true on success
func consume(requirements: Dictionary) -> bool:
	if not has_all(requirements):
		return false

	for key in requirements.keys():
		resources[key] = max(resources.get(key, 0.0) - requirements[key], 0.0)

	prune_zeros()
	updated.emit(self)
	return true

# Check if all resources in the provided dictionary are at capacity
func are_all_at_capacity(requirements: Dictionary) -> bool:
	if not respect_caps:
		return false  # Capacity doesn't apply
	for key in requirements.keys():
		if not is_at_capacity(key):
			return false
	return true

# Returns true if the resource specified by key is at capacity
func is_at_capacity(key: String) -> bool:
	if not respect_caps:
		return false
	return caps.get(key, 0.0) > 0.0 and get_value(key) >= caps[key]

# Removes keys from the dictionary if the value is 0.0
func prune_zeros() -> void:
	var to_remove: Array = []
	for key in resources.keys():
		if resources[key] == 0.0:
			to_remove.append(key)
	for key in to_remove:
		resources.erase(key)
